#!/usr/bin/env bash
# ABOUTME: Asserts every eval case under evals/ is well-formed and its scaffold builds a real repo.
# ABOUTME: Covers frontmatter keys, grader shapes, case.yaml, fixtures, and per-case planted facts.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"

EVALS="$PLUGIN_DIR/evals"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAIL=0
fail() { echo "    $*"; FAIL=1; }

# A working Python, found by running it (the Windows python3 is a Store stub).
PY=""
for cand in python3 python; do
    if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'import sys' >/dev/null 2>&1; then PY="$cand"; break; fi
done

fm_get() { frontmatter "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -1 | sed 's/[[:space:]]*$//'; }
fm_has() { frontmatter "$1" | grep -q "^$2:"; }

# Build a case's scaffold into a fresh dir; echoes the dir.
scaffold() {
    local case_dir="$1" ws h
    ws="$(mktemp -d "$TMP/ws.XXXXXX")"; h="$(mktemp -d "$TMP/home.XXXXXX")"
    ( cd "$ws" && HOME="$h" bash "$case_dir/fixture.sh" >/dev/null 2>&1 ) || { echo "scaffold failed: $case_dir" >&2; return 1; }
    echo "$ws"
}

PROMPT_KEYS=" schema_version name description tags plugins runs expected_outcome model max_turns timeout_seconds allowed_tools append_system_prompt env "
GRADER_TYPES=" regex tool_used tool_order file_exists llm baseline "

check_case() {
    local p="$1" dir name key g type
    dir="$(dirname "$p")"; name="$(fm_get "$p" name)"
    echo "  case: ${dir#$EVALS/}"
    while IFS= read -r key; do
        case "$PROMPT_KEYS" in *" $key "*) ;; *) fail "$name: unknown prompt.md key '$key'" ;; esac
    done < <(frontmatter "$p" | sed -n 's/^\([A-Za-z_][A-Za-z_0-9]*\):.*/\1/p')
    case "$name" in trigger-*|defects-*|planning-*|triage-*) ;; *) fail "bad case name '$name'" ;; esac

    local graders=("$dir"/graders/*.md) behavior=0
    [ -f "${graders[0]}" ] || { fail "$name: no graders"; return; }
    for g in "${graders[@]}"; do
        type="$(fm_get "$g" type)"; local arm tool; arm="$(fm_get "$g" arm)"; tool="$(fm_get "$g" tool)"
        case "$GRADER_TYPES" in *" $type "*) ;; *) fail "$g: bad type '$type'" ;; esac
        [ "$type" = regex ] && fm_has "$g" focus && fail "$g: regex grader has focus (use target)"
        [ "$type" = llm ] && fm_has "$g" target && fail "$g: llm grader has target (use focus)"
        case "$arm" in ""|with-only|both) ;; *) fail "$g: bad arm '$arm'" ;; esac
        if [ "$(basename "$g")" = skill-fired.md ] && [ -n "$arm" ]; then fail "$g: skill-fired must not set arm"; fi
        [ "$arm" != with-only ] && [ "$tool" != Skill ] && behavior=$((behavior+1))
    done
    [ "$behavior" -ge 1 ] || fail "$name: no grader that scores behavior"

    local y="$dir/case.yaml"
    assert_file "$y" || { FAIL=1; return; }
    grep -q '^schema_version: "1.1"' "$y" || fail "$y: schema_version"
    grep -q "^name: $name\$" "$y" || fail "$y: name != $name"
    local script; script="$(sed -n 's/^[[:space:]]*scaffold_script:[[:space:]]*//p' "$y" | tr -d '"'"'"'\r ')"
    [ -n "$script" ] && [ -f "$dir/$script" ] || { fail "$y: scaffold_script missing"; return; }
    local ws; ws="$(scaffold "$dir")" || { FAIL=1; return; }
    [ "$(git -C "$ws" rev-list --count HEAD 2>/dev/null || echo 0)" -ge 1 ] || fail "$name: scaffold left no commit"
}

CASES=0
while IFS= read -r p; do
    check_case "$p"; CASES=$((CASES+1))
done < <(find "$EVALS" -name prompt.md 2>/dev/null | sort)

[ "$(find "$EVALS/trigger" -name prompt.md 2>/dev/null | wc -l)" -eq 4 ] || fail "expected 4 trigger cases"

# --- trigger fixtures --------------------------------------------------
if [ -n "$PY" ] && [ -d "$EVALS/trigger/debug" ]; then
    ws="$(scaffold "$EVALS/trigger/debug")"
    out="$(cd "$ws" && "$PY" -m unittest 2>&1)" && fail "debug fixture test should fail"
    echo "$out" | grep -q '10.0 != 90.0' || fail "debug fixture failure lacks '10.0 != 90.0'"
    git -C "$ws" log --format=%s | grep -q '^refactor: simplify discount math$' || fail "debug fixture lacks refactor commit"
fi
if [ -n "$PY" ] && [ -d "$EVALS/trigger/review" ]; then
    ws="$(scaffold "$EVALS/trigger/review")"
    [ "$(git -C "$ws" branch --show-current)" = feature/greeting ] || fail "review fixture not on feature/greeting"
    (cd "$ws" && "$PY" -m unittest >/dev/null 2>&1) || fail "review fixture tests should pass"
fi
if [ -d "$EVALS/trigger/quick-fix" ]; then
    ws="$(scaffold "$EVALS/trigger/quick-fix")"
    grep -q recieve "$ws/README.md" || fail "quick-fix README lacks the typo"
fi

# --- planted-defect review case ------------------------------------------
D="$EVALS/defects/review-branch"
[ "$(find "$D/graders" -name '*.md' 2>/dev/null | wc -l)" -eq 7 ] || fail "defects-review should have 7 graders"
if [ -d "$D" ]; then
    ws="$(scaffold "$D")"
    [ "$(git -C "$ws" branch --show-current)" = feature/order-report ] || fail "defects fixture not on feature/order-report"
    [ -n "$(git -C "$ws" diff main --stat)" ] || fail "defects fixture: empty diff against main"
    grep -q 'size - 1' "$ws/report.py" || fail "report.py lacks 'size - 1'"
    grep -q 'except Exception' "$ws/report.py" || fail "report.py lacks 'except Exception'"
    grep -q 'order\["id"\]' "$ws/report.py" || fail "report.py lacks order[\"id\"]"
    [ -f "$ws/SPEC.md" ] || fail "defects fixture lacks SPEC.md"
    if [ -n "$PY" ]; then
        (cd "$ws" && "$PY" -m unittest >/dev/null 2>&1) || fail "defects fixture tests should pass"
    fi
fi

# --- plan-quality case -----------------------------------------------------
P="$EVALS/planning/csv-export"
[ "$(find "$P/graders" -name '*.md' 2>/dev/null | wc -l)" -eq 6 ] || fail "planning-csv-export should have 6 graders"
if [ -d "$P" ]; then
    scored=0
    for g in "$P"/graders/*.md; do
        [ "$(fm_get "$g" arm)" != with-only ] && [ "$(fm_get "$g" tool)" != Skill ] && scored=$((scored+1))
    done
    [ "$scored" -ge 2 ] || fail "planning-csv-export: need 2+ graders that score behavior (got $scored)"
    ws="$(scaffold "$P")"
    [ -f "$ws/SPEC.md" ] || fail "planning fixture lacks SPEC.md"
    grep -qi 'comma' "$ws/SPEC.md" && fail "planning SPEC.md must not mention commas"
    grep -qi 'quot' "$ws/SPEC.md" && fail "planning SPEC.md must not mention quotes"
    [ -f "$ws/contacts.py" ] || fail "planning fixture lacks contacts.py"
fi

# --- brainstorm case grades the workspace (Bash edits slip past tool_used) ---
B="$EVALS/trigger/brainstorm"
for g in "$B"/graders/*.md; do
    if [ "$(fm_get "$g" type)" = tool_used ]; then
        case "$(fm_get "$g" tool)" in Edit|Write) fail "brainstorm: tool_used grader on Edit/Write ($(basename "$g")) misses Bash edits" ;; esac
    fi
done
found=0
for g in "$B"/graders/*.md; do
    [ "$(fm_get "$g" type)" = regex ] && fm_get "$g" target | grep -q 'contacts.py' && [ "$(fm_get "$g" match)" = not_contains ] && found=1
done
[ "$found" -eq 1 ] || fail "brainstorm: needs a regex grader on contacts.py with match: not_contains"
ws="$(scaffold "$B")"
grep -qiE 'csv|export' "$ws/contacts.py" && fail "brainstorm fixture contacts.py must not mention csv or export"

# --- harder planted-defect case (seven defects, three decoys, larger branch) --
X="$EVALS/defects/crossfile"
[ "$(find "$X/graders" -name '*.md' 2>/dev/null | wc -l)" -eq 9 ] || fail "defects-crossfile should have 9 graders"
if [ -d "$X" ]; then
    ws="$(scaffold "$X")"
    [ "$(git -C "$ws" branch --show-current)" = feature/invoices ] || fail "crossfile fixture not on feature/invoices"
    [ "$(git -C "$ws" diff main --name-only | wc -l | tr -d ' ')" -ge 8 ] || fail "crossfile branch should change 8+ files"
    added="$(git -C "$ws" diff main --numstat | awk '{ n += $1 } END { print n + 0 }')"
    { [ "$added" -ge 500 ] && [ "$added" -le 700 ]; } || fail "crossfile branch adds $added lines (want 500-700)"
    grep -q 'TAX_RATE *= *0\.0825' "$ws/config.py" || fail "config.py lacks TAX_RATE = 0.0825"
    grep -q 'apply_rate(.*config\.TAX_RATE' "$ws/invoice.py" || fail "invoice.py lacks apply_rate(..., config.TAX_RATE)"
    grep -q '< end' "$ws/invoice.py" || fail "invoice.py lacks '< end'"
    grep -q 'store\.add(' "$ws/importer.py" || fail "importer.py lacks store.add("
    grep -q '\* 100' "$ws/importer.py" || fail "importer.py lacks '* 100'"
    grep -q 'store\.get(' "$ws/importer.py" && fail "importer.py must not call store.get("
    grep -q '\.lower()' "$ws/importer.py" && fail "importer.py must not call .lower()"
    grep -q 'os\.path\.join(config\.EXPORT_DIR' "$ws/exporter.py" || fail "exporter.py lacks os.path.join(config.EXPORT_DIR"
    grep -qE 'commonpath|realpath' "$ws/exporter.py" && fail "exporter.py must not check the export path"
    awk '/except Exception:/ { getline nxt; if (nxt ~ /return \[\]/) found = 1 } END { exit !found }' "$ws/persistence.py" || fail "persistence.py lacks 'except Exception:' then 'return []'"
    grep -q 'today < ' "$ws/discounts.py" || fail "decoy missing: exclusive expiry in discounts.py"
    grep -q 'SPEC' "$ws/discounts.py" || fail "decoy missing: discounts.py comment citing SPEC"
    grep -q 'raise$' "$ws/cli.py" && grep -q 'except Exception' "$ws/cli.py" || fail "decoy missing: broad except that re-raises in cli.py"
    grep -q 'cents / 100' "$ws/report.py" || fail "decoy missing: display-only float in report.py"
    [ -f "$ws/SPEC.md" ] || fail "crossfile fixture lacks SPEC.md"
    grep -qiE 'twice|again|duplicat|rerun|re-run|case|lower|inclusive|round' "$ws/SPEC.md" && fail "crossfile SPEC.md gives a defect away"
    grep -q 'through' "$ws/SPEC.md" || fail "crossfile SPEC.md lacks 'through'"
    if [ -n "$PY" ]; then
        (cd "$ws" && "$PY" -m unittest >/dev/null 2>&1) || fail "crossfile fixture tests should pass"
    fi
    # Only the seven defects are planted: every arm reported these as real (3.4 baseline), so the fixture rules them out.
    grep -q 'the CSV that `import_file` reads' "$ws/SPEC.md" || fail "crossfile SPEC.md must say which CSV carries a decimal total"
    grep -q 'amounts in integer cents' "$ws/SPEC.md" || fail "crossfile SPEC.md must say invoice exports hold cents"
    if [ -n "$PY" ]; then
        (cd "$ws" && HOME="$ws" "$PY" - >/dev/null 2>&1 <<'CHECK'
import os, cli, config, importer, models, persistence, store
config.DATA_FILE = os.path.join(os.getcwd(), "data.json")
for name, row in (("a.csv", "1,ann@x.com,1.00,2026-03-02"), ("b.csv", "2,bob@x.com,2.00,2026-03-03")):
    with open(name, "w") as handle:
        handle.write("id,email,total,date\n" + row + "\n")
    cli.main(["import", name])
assert len(persistence.load_orders(config.DATA_FILE)) == 2, "a second import lost saved orders"
for row in ({"id": "x", "email": "a@x.com", "total": "1.00", "date": "2026-03-02"},
            {"id": "3", "email": None, "total": None, "date": None}):
    try:
        models.validate_row(row)
        raise AssertionError("bad row accepted")
    except models.RowError:
        pass
store.clear()
good = {"id": "4", "email": "c@x.com", "total": "1.00", "date": "2026-03-02"}
try:
    importer.import_orders([good, {"id": "5", "email": "bad", "total": "1.00", "date": "2026-03-02"}])
except models.RowError:
    pass
assert store.get(4) is None, "a bad row left earlier rows stored"
CHECK
        ) || fail "crossfile fixture holds an unplanted defect (import replaces saved data, a bad id or short row escapes RowError, or a bad row leaves earlier rows stored)"
    fi
fi
for g in "$EVALS/defects/crossfile/graders/no-false-alarms.md" "$EVALS/defects/review-branch/graders/no-false-alarms.md"; do
    grep -q 'Count each defect once' "$g" || fail "${g#$EVALS/}: must count a defect once however it is split"
done
grep -q 'daily_report' "$EVALS/defects/review-branch/graders/no-false-alarms.md" || fail "defects-review no-false-alarms must count the daily_report crash as defect (3)"
for c in defects/review-branch defects/crossfile trigger/review; do
    [ -f "$EVALS/$c/prompt.md" ] || continue
    frontmatter "$EVALS/$c/prompt.md" | grep '^allowed_tools:' | grep -q 'Workflow' || fail "$c: allowed_tools lacks Workflow"
done
for p in "$EVALS"/defects/*/prompt.md; do
    t="$(fm_get "$p" timeout_seconds)"
    [ "${t:-0}" -ge 1800 ] 2>/dev/null || fail "${p#$EVALS/}: timeout_seconds ${t:-unset} < 1800"
done

# --- PR triage case ----------------------------------------------------------
T="$EVALS/triage/pr-comments"
[ "$(find "$T/graders" -name '*.md' 2>/dev/null | wc -l)" -eq 5 ] || fail "triage-pr-comments should have 5 graders"
if [ -d "$T" ]; then
    ws="$(scaffold "$T")"
    [ "$(git -C "$ws" branch --show-current)" = feature/slugify ] || fail "triage fixture not on feature/slugify"
    [ -z "$(git -C "$ws" status --porcelain)" ] || fail "triage fixture tree not clean"
    [ -f "$ws/pr-comments.json" ] || fail "triage fixture lacks pr-comments.json"
    if command -v jq >/dev/null 2>&1; then
        [ "$(jq -r '[.comments[].kind] | join(",")' "$ws/pr-comments.json")" = "inline,issue,inline" ] || fail "pr-comments.json kinds != inline,issue,inline"
        [ "$(jq '.comments | length' "$ws/pr-comments.json")" = 3 ] || fail "pr-comments.json should hold 3 comments"
    else
        echo "    jq not installed, skipping pr-comments.json checks"
    fi
    if [ -n "$PY" ]; then
        (cd "$ws" && "$PY" -m unittest >/dev/null 2>&1) || fail "triage fixture tests should pass"
        got="$(cd "$ws" && "$PY" -c "from slug import slugify; print(slugify('  Hello  World '))")"
        [ "$got" != "hello-world" ] || fail "triage fixture: slugify bug is not present"
    fi
fi

[ "$FAIL" -eq 0 ] && echo "  $CASES cases ok" || exit 1
