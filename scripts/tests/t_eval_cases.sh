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
    case "$name" in trigger-*|defects-*|planning-*) ;; *) fail "bad case name '$name'" ;; esac

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

[ "$FAIL" -eq 0 ] && echo "  $CASES cases ok" || exit 1
