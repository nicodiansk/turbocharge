#!/usr/bin/env bash
# ABOUTME: Asserts plan tasks can name the code to imitate in a Like: line, and that the planner, builder and build skill follow it.
# ABOUTME: Named references, tasks 1-5: plan Task Structure and Rules; planner steps and checks; builder item 5; build Step 4.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/plan/SKILL.md"
assert_file "$S" || exit 1
rc=0
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
has() { # has <label> <text> <phrase>
    printf '%s\n' "$2" | grep -qF -- "$3" || { echo "    $1 missing: $3"; rc=1; }
}

# Task 1: plan skill
TS=$(sec "$S" '## Task Structure' '## ')
RULES=$(sec "$S" '## Rules' '## ')
LIKE='**Like:** `src/importers/csv.py:parse_row` (tests: `tests/importers/test_csv.py`)'
LANE_N=$(printf '%s\n' "$TS" | grep -nF -- '**Lane:**' | head -1 | cut -d: -f1)
LIKE_N=$(printf '%s\n' "$TS" | grep -nF -- "$LIKE" | head -1 | cut -d: -f1)
if [ -z "$LANE_N" ] || [ -z "$LIKE_N" ] || [ "$LIKE_N" -ne $((LANE_N + 1)) ]; then
    echo "    plan Task Structure must hold the Like: line right after the Lane: line (lane=$LANE_N like=$LIKE_N)"; rc=1
fi
has "plan Task Structure" "$TS" 'never invent one'
has "plan Task Structure" "$TS" '(tests: …)'
has "plan Rules" "$RULES" "**Name it, don't describe it.**"

exit $rc
