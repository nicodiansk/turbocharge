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

# Task 2: planner
P="$PLUGIN_DIR/agents/planner.md"
assert_file "$P" || exit 1
VDU=$(sec "$P" '### Verify Domain Understanding First' '## ')
for p in '5. **Search before you plan new code.**' 'Grep tool' 'the Decision reuses it' 'covered by tests' 'Never invent one'; do
    has "planner Verify Domain Understanding First" "$VDU" "$p"
done
PF=$(sec "$P" '## Plan Format' '## Quality Checklist')
PL_N=$(printf '%s\n' "$PF" | grep -nF -- '**Lane:** api' | head -1 | cut -d: -f1)
PK_N=$(printf '%s\n' "$PF" | grep -nF -- '**Like:**' | head -1 | cut -d: -f1)
if [ -z "$PL_N" ] || [ -z "$PK_N" ] || [ "$PK_N" -ne $((PL_N + 1)) ]; then
    echo "    planner Plan Format must hold a Like: line right after the Lane: api line (lane=$PL_N like=$PK_N)"; rc=1
fi
grep -qF -- "**Name it, don't describe it**" "$P" || { echo "    planner.md missing: **Name it, don't describe it**"; rc=1; }
has "planner Remember" "$(sec "$P" '## Remember' '## ')" '(step 4)'

# Task 3: the plan check resolves Like: targets
SSR=$(sec "$P" '## Spec Self-Review' '## ')
for p in '6. **`Like:` targets resolve**' 'Grep tool' 'grep -n' 'fixed or removed'; do
    has "planner Spec Self-Review" "$SSR" "$p"
done
grep -nE '(^|[[:space:](])rg -' "$P" >/dev/null && { echo "    planner.md must not name rg"; rc=1; }
has "planner Quality Checklist" "$(sec "$P" '## Quality Checklist' '## ')" 'Every `Like:` target resolves'
CHECK=$(grep -F 'Check the saved plan' "$S" | head -1)
has "plan Check the saved plan line" "$CHECK" 'every `Like:` target resolves'
NOAGENT=$(grep -F '**No agent here:**' "$S" | head -1)
has "plan No agent here line" "$NOAGENT" '`Like:` targets resolve'

# Task 4: builder
B="$PLUGIN_DIR/agents/builder.md"
assert_file "$B" || exit 1
BVDU=$(sec "$B" '### Verify Domain Understanding' '## ')
for p in '5. **Read the task'"'"'s `Like:` target**' 'names, error handling, test layout' 'Like <target> · differs: <how> · <why>' 'read-only' 'found by content' 'Like <target> · not found · built from the Decision'; do
    has "builder Verify Domain Understanding" "$BVDU" "$p"
done
BREP=$(sec "$B" '## Report Format' '## ')
BR_N=$(printf '%s\n' "$BREP" | grep -nF -- '**Rulings**' | head -1 | cut -d: -f1)
BD_N=$(printf '%s\n' "$BREP" | grep -nF -- 'differs:' | head -1 | cut -d: -f1)
if [ -z "$BR_N" ] || [ -z "$BD_N" ] || ! [ "$BR_N" -lt "$BD_N" ]; then
    echo "    builder Report Format: the first differs: line must come after the first Rulings line (rulings=$BR_N differs=$BD_N)"; rc=1
fi

# Task 5: build Step 4
BS=$(sec "$PLUGIN_DIR/skills/build/SKILL.md" '## Step 4' '## ')
for p in '`Like:`' 'names, error handling, test layout' 'Like <target> · differs: <how> · <why>' "Step 7's Rulings" 'not found · built from the Decision'; do
    has "build Step 4" "$BS" "$p"
done

exit $rc
