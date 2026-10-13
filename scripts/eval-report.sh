#!/usr/bin/env bash
# ABOUTME: Summarizes a `claude plugin eval` result document as WITH / W/OUT / delta tables per family and case.
# ABOUTME: Exits 1 on partial runs, infrastructure errors or skipped paid graders; turn caps and timeouts count as measured.
# Usage: eval-report.sh <aggregate-result.json>
set -uo pipefail

F="${1:-}"
[ -n "$F" ] || { echo "usage: eval-report.sh <aggregate-result.json>" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "eval-report: jq is required" >&2; exit 1; }
[ -f "$F" ] || { echo "eval-report: no such file: $F" >&2; exit 1; }
jq -e 'type == "object"' "$F" >/dev/null 2>&1 || { echo "eval-report: not a JSON result document: $F" >&2; exit 1; }

# A budget error is the case's own limit (turn cap, timeout): the run was graded on what it produced.
BUDGET='test("timed out after|max(imum)?[ _-]*(number of )?turns"; "i")'
# Every run, flattened with its case, arm and 1-based index.
RUNS='[.cases[]? | . as $c | ("with","without") as $arm | ($c.arms[$arm] // []) | to_entries[] | {case: $c.name, arm: $arm, n: (.key + 1), run: .value}]'

FATAL=0
fail() { echo "eval-report: $1" >&2; FATAL=1; }

if [ "$(jq -r '.partial // false' "$F")" = "true" ]; then
    fail "partial run: $(jq -r '.partialReason // "unknown reason"' "$F")"
fi
while IFS= read -r line; do
    [ -n "$line" ] && fail "$line"
done < <(jq -r "$RUNS | .[] | select(.run.error != null and (.run.error | tostring | $BUDGET | not)) | \"\(.case) \(.arm): \(.run.error)\"" "$F")
SKIPPED="$(jq -r "(.skippedPaidGraders // false) or ($RUNS | any(.run.skippedPaidGraders == true))" "$F")"
[ "$SKIPPED" = "false" ] || fail "paid graders were skipped (skippedPaidGraders)"
[ "$FATAL" -eq 0 ] || exit 1

jq -r "
def f2: (. * 100 | round) as \$n | (if \$n < 0 then \"-\" else \"\" end) + ((\$n | fabs) / 100 | floor | tostring) + \".\" + (((\$n | fabs) % 100) | tostring | if length < 2 then \"0\" + . else . end);
def sgn: (. * 100 | round) as \$n | (if \$n < 0 then \"\" else \"+\" end) + f2;
def avg: add / length;
def fired(\$c): [(\$c.arms.with // [])[] | select(any(.graders[]?; .name == \"skill-fired\"))] as \$r
  | if (\$r | length) == 0 then null else {p: ([\$r[] | select(any(.graders[]?; .name == \"skill-fired\" and .passed == true))] | length), t: (\$r | length)} end;
def firedstr: if . == null then \"—\" else \"\(.p)/\(.t)\" end;
def cost(\$c): [((\$c.arms.with // []) + (\$c.arms.without // []))[] | (.costUsd // 0) + (.judgeCostUsd // 0)] | add // 0;
def opt(fn): if . == null then \"—\" else fn end;

[.cases[]? | {name, family: (.name | split(\"-\")[0]), s: .aggregates.score, w: .aggregates.scoreWithout, d: .aggregates.delta, fired: fired(.), cost: cost(.)}] as \$cs
| \"| Family | Cases | WITH | W/OUT | Δ | Fired |\",
  \"|---|---|---|---|---|---|\",
  ( \$cs | group_by(.family)[] | . as \$g
    | [\$g[] | select(.d != null)] as \$dd
    | [\$g[].fired | select(. != null)] as \$ff
    | \"| \(\$g[0].family) | \(\$g | length) | \(\$g | map(.s // 0) | avg | f2) | \(if (\$dd | length) == 0 then \"—\" else (\$dd | map(.w // 0) | avg | f2) end) | \(if (\$dd | length) == 0 then \"—\" else (\$dd | map(.d) | avg | sgn) end) | \(if (\$ff | length) == 0 then \"—\" else \"\(\$ff | map(.p) | add)/\(\$ff | map(.t) | add)\" end) |\" ),
  \"\",
  \"| Case | WITH | W/OUT | Δ | Fired | Cost |\",
  \"|---|---|---|---|---|---|\",
  ( \$cs[] | \"| \(.name) | \((.s // 0) | f2) | \(if .d == null then \"—\" else (.w // 0) | f2 end) | \(if .d == null then \"—\" else .d | sgn end) | \(.fired | firedstr) | \$\(.cost | f2) |\" )
" "$F" || { echo "eval-report: could not summarize $F" >&2; exit 1; }

MEASURED="$(jq -r "$RUNS | .[] | select(.run.error != null) | \"- \(.case) \(.arm) run \(.n): \(.run.error)\"" "$F")"
if [ -n "$MEASURED" ]; then
    printf '\nRun errors counted as measured:\n%s\n' "$MEASURED"
fi
jq -r 'def f2: (. * 100 | round) as $n | (($n | fabs) / 100 | floor | tostring) + "." + ((($n | fabs) % 100) | tostring | if length < 2 then "0" + . else . end);
  "\nCost $\((.costUsd // 0) | f2) · \(.durationSeconds // 0)s · Claude Code \(.claudeVersion // "unknown")"' "$F"
