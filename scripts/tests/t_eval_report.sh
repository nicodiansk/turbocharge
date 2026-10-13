#!/usr/bin/env bash
# ABOUTME: Behavioral test for scripts/eval-report.sh, run against fixture eval-result JSON.
# ABOUTME: Covers the family and case tables, cost, measured budget errors, and the failure exits.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
if ! command -v jq >/dev/null 2>&1; then echo "    jq not installed, skipping"; exit 0; fi
R="$PLUGIN_DIR/scripts/eval-report.sh"
assert_file "$R" || exit 1
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

# run <fired true|false|none> <costUsd> <judgeCostUsd> [error]
run() {
    local g='[]'
    [ "$1" = none ] || g="[{\"name\":\"skill-fired\",\"passed\":$1}]"
    local e=null
    [ -z "${4:-}" ] || e="$(jq -n --arg e "$4" '$e')"
    printf '{"score":1,"turns":3,"costUsd":%s,"judgeCostUsd":%s,"error":%s,"skippedPaidGraders":false,"graders":%s}' "$2" "$3" "$e" "$g"
}
# doc <cases-json-array> [extra top-level json fragment]
doc() { printf '{"schemaVersion":1,"partial":false,"costUsd":4.5,"durationSeconds":321,"claudeVersion":"2.1.296","cases":%s%s}' "$1" "${2:-}"; }

# --- happy path: two trigger cases and a defects case
A="$(run true 0.5 0.1),$(run true 0.5 0.1)"
B="$(run true 0.5 0.1),$(run false 0.5 0.1)"
N="$(run none 0.5 0.1)"
doc "[
 {\"name\":\"trigger-a\",\"aggregates\":{\"score\":1.0,\"scoreWithout\":0.1,\"delta\":0.9},\"arms\":{\"with\":[$A],\"without\":[$N]}},
 {\"name\":\"trigger-b\",\"aggregates\":{\"score\":0.8,\"scoreWithout\":0.3,\"delta\":0.5},\"arms\":{\"with\":[$B],\"without\":[$N]}},
 {\"name\":\"defects-x\",\"aggregates\":{\"score\":0.6,\"scoreWithout\":0.4,\"delta\":0.2},\"arms\":{\"with\":[$N],\"without\":[$N]}}
]" > "$T/ok.json"
OUT="$(bash "$R" "$T/ok.json" 2>"$T/err")" || { echo "    happy path exited non-zero: $(cat "$T/err")"; exit 1; }
echo "$OUT" | grep -qF '| trigger | 2 | 0.90 | 0.20 | +0.70 | 3/4 |' || { echo "    missing trigger family row"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -qF '| defects | 1 | 0.60 | 0.40 | +0.20 | — |' || { echo "    missing defects family row"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -qF '| trigger-a | 1.00 | 0.10 | +0.90 | 2/2 |' || { echo "    missing case row"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -qF 'Cost $4.50' || { echo "    missing footer cost"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -qF '321s · Claude Code 2.1.296' || { echo "    missing footer tail"; echo "$OUT"; exit 1; }
# cost per case: 0.50 x 3 runs = 1.50 for trigger-a
echo "$OUT" | grep -F '| trigger-a |' | grep -qF '| $1.50 |' || { echo "    case cost wrong"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -q 'Run errors counted as measured' && { echo "    unexpected measured-errors section"; exit 1; }

# --- cost row for a case with 0.50 + 0.10 in each arm (one run per arm) => $1.00 (costUsd already includes the judge)
doc "[{\"name\":\"trigger-c\",\"aggregates\":{\"score\":1,\"scoreWithout\":0,\"delta\":1},\"arms\":{\"with\":[$(run true 0.5 0.1)],\"without\":[$(run none 0.5 0.1)]}}]" > "$T/cost.json"
bash "$R" "$T/cost.json" 2>/dev/null | grep -F '| trigger-c |' | grep -q '| \$1.00 |$' || { echo "    case row should end | \$1.00 |"; exit 1; }

# --- case costs sum to the footer cost
doc "[{\"name\":\"trigger-c\",\"aggregates\":{\"score\":1,\"scoreWithout\":0,\"delta\":1},\"arms\":{\"with\":[$(run true 0.5 0.1)],\"without\":[$(run none 0.5 0.1)]}},{\"name\":\"defects-d\",\"aggregates\":{\"score\":1,\"scoreWithout\":0,\"delta\":1},\"arms\":{\"with\":[$(run none 0.25 0.1)],\"without\":[$(run none 0.25 0.1)]}}]" | jq '.costUsd=1.5' > "$T/sum.json"
OUT="$(bash "$R" "$T/sum.json" 2>/dev/null)"
SUM="$(echo "$OUT" | grep -E '^\| (trigger-c|defects-d) \|' | sed -E 's/.*\| \$([0-9.]+) \|$/\1/' | awk '{s+=$1} END {printf "%.2f", s}')"
FOOT="$(echo "$OUT" | sed -nE 's/^Cost \$([0-9.]+) .*/\1/p')"
[ "$SUM" = "$FOOT" ] || { echo "    case costs ($SUM) should sum to footer cost ($FOOT)"; exit 1; }

# --- lone case with no delta
doc "[{\"name\":\"trigger-lone\",\"aggregates\":{\"score\":0.5},\"arms\":{\"with\":[$(run true 0 0)]}}]" > "$T/lone.json"
bash "$R" "$T/lone.json" 2>/dev/null | grep -F '| trigger-lone |' | grep -qF '| trigger-lone | 0.50 | — | — |' || { echo "    lone case row wrong"; exit 1; }
bash "$R" "$T/lone.json" 2>/dev/null | grep -qF '| trigger | 1 | 0.50 | — | — |' || { echo "    lone family row wrong"; exit 1; }

# --- usage limit in the without arm: exit 1, names case and arm
doc "[{\"name\":\"trigger-bad\",\"aggregates\":{\"score\":1,\"scoreWithout\":0,\"delta\":1},\"arms\":{\"with\":[$(run true 0 0)],\"without\":[$(run none 0 0 'usage limit reached')]}}]" > "$T/usage.json"
if bash "$R" "$T/usage.json" >/dev/null 2>"$T/err"; then echo "    usage limit should exit 1"; exit 1; fi
grep -q 'trigger-bad' "$T/err" && grep -q 'without' "$T/err" || { echo "    stderr should name case and arm"; cat "$T/err"; exit 1; }

# --- budget errors are measured, not failures
doc "[{\"name\":\"trigger-cap\",\"aggregates\":{\"score\":0.5,\"scoreWithout\":0.2,\"delta\":0.3},\"arms\":{\"with\":[$(run true 0 0 'Reached maximum number of turns (25)'),$(run true 0 0 'timed out after 600s')],\"without\":[$(run none 0 0)]}}]" > "$T/budget.json"
OUT="$(bash "$R" "$T/budget.json" 2>"$T/err")" || { echo "    budget errors should exit 0: $(cat "$T/err")"; exit 1; }
echo "$OUT" | grep -qF 'Run errors counted as measured:' || { echo "    missing measured section"; exit 1; }
echo "$OUT" | grep -qF -- '- trigger-cap with run 1: Reached maximum number of turns (25)' || { echo "    turn cap line missing"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -qF -- '- trigger-cap with run 2: timed out after 600s' || { echo "    timeout line missing"; exit 1; }

# --- partial
doc '[]' ',"partial":true,"partialReason":"cost_ceiling"' | jq '.partial=true | .partialReason="cost_ceiling"' > "$T/partial.json"
if bash "$R" "$T/partial.json" >/dev/null 2>"$T/err"; then echo "    partial should exit 1"; exit 1; fi
grep -q 'cost_ceiling' "$T/err" || { echo "    stderr should say cost_ceiling"; exit 1; }

# --- skippedPaidGraders
jq '.cases[0].arms.with[0].skippedPaidGraders=true' "$T/cost.json" > "$T/skip.json"
if bash "$R" "$T/skip.json" >/dev/null 2>&1; then echo "    skippedPaidGraders should exit 1"; exit 1; fi

# --- missing / non-JSON file
if bash "$R" "$T/nope.json" >/dev/null 2>&1; then echo "    missing file should exit 1"; exit 1; fi
echo "not json" > "$T/bad.json"
if bash "$R" "$T/bad.json" >/dev/null 2>&1; then echo "    non-JSON should exit 1"; exit 1; fi
exit 0
