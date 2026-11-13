#!/usr/bin/env bash
# ABOUTME: Asserts lanes follow the task shape: chained builder lanes merge, at most 3 builder lanes overlap.
# ABOUTME: Lane shape, tasks 6-9: plan Plan Document Header, planner Lanes and checks, build Steps 2, 3 and 5, README.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/plan/SKILL.md"
assert_file "$S" || exit 1
rc=0
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
has() { # has <label> <text> <phrase>
    printf '%s\n' "$2" | grep -qF -- "$3" || { echo "    $1 missing: $3"; rc=1; }
}
RULES=(
    '1. **One lane is the default.**'
    '2. **Chain → one lane.**'
    "B's only \`After\` is A and no other lane names A in \`After\`"
    'A→B→C becomes one lane'
    'takes the higher Effort'
    '3. **Inline lanes stay separate**'
    "A chain through an inline lane doesn't merge"
    '4. **At most 3 builder lanes overlap**'
    'union of their files'
    "Inline lanes don't count"
)

# Task 6: plan skill
HDR=$(sec "$S" '## Plan Document Header' '## Context Gathering')
for p in "${RULES[@]}"; do has "plan Plan Document Header" "$HDR" "$p"; done
grep -qF 'A small plan can be a single lane' "$S" && { echo "    plan still says: A small plan can be a single lane"; rc=1; }
# Merging costs no time but shares one mutation and one fix budget (review of 3.7.0, finding 4).
MERGE=('Merging costs no time' 'one lane-end mutation and one budget of 2 fix rounds' "whose \`After\` named B now names A")
for p in "${MERGE[@]}"; do has "plan Plan Document Header" "$HDR" "$p"; done
grep -qF 'Merging loses nothing' "$S" && { echo "    plan still says: Merging loses nothing"; rc=1; }

# Task 7: planner and plan check
P="$PLUGIN_DIR/agents/planner.md"
assert_file "$P" || exit 1
PLANES=$(sec "$P" '## Lanes' '## ')
for p in "${RULES[@]}" "${MERGE[@]}"; do has "planner Lanes" "$PLANES" "$p"; done
grep -qF 'Merging loses nothing' "$P" && { echo "    planner still says: Merging loses nothing"; rc=1; }
has "planner Quality Checklist" "$(sec "$P" '## Quality Checklist' '## ')" '- [ ] No builder→builder chain link; at most 3 builder lanes overlap'
SSR=$(sec "$P" '## Spec Self-Review' '## ')
for p in 'no builder→builder chain link' 'at most 3 overlapping builder lanes'; do
    has "planner Spec Self-Review" "$SSR" "$p"
    has "plan Check the saved plan line" "$(grep -F 'Check the saved plan' "$S" | head -1)" "$p"
    has "plan No agent here line" "$(grep -F '**No agent here:**' "$S" | head -1)" "$p"
done

# Task 8: build Steps 2, 3, 5
BS="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$BS" || exit 1
for p in 'At most 3 builder lanes run at once' 'waits for a slot' '`--delegate`' 'by hand'; do
    has "build Step 2" "$(sec "$BS" '## Step 2' '## ')" "$p"
done
has "build Step 3" "$(sec "$BS" '## Step 3' '## ')" 'has a slot'
for p in 'while fewer than 3 builder lanes are running' 'in plan order' 'whose join checks pass' 'frees its slot' 'takes the next free slot' \
    'start the next waiting builder lane' 'before lanes still waiting'; do
    has "build Step 5" "$(sec "$BS" '## Step 5' '## ')" "$p"
done

# Task 9: README
R="$PLUGIN_DIR/README.md"
assert_file "$R" || exit 1
ROW=$(grep -F '| **build** |' "$R" | head -1)
PARA=$(grep -F 'Independent lanes **overlap**' "$R" | head -1)
FILTERED=$(bash "$PLUGIN_DIR/scripts/directory-filter.sh" < "$R")
has "README build row" "$ROW" 'at most 3 builders at once'
has "README lanes paragraph" "$PARA" 'at most 3 builder lanes at once'
has "README lanes paragraph" "$PARA" 'Work that chains stays in one lane'
has "README filtered copy" "$FILTERED" 'at most 3 builders at once'
has "README filtered copy" "$FILTERED" 'Work that chains stays in one lane'

exit $rc
