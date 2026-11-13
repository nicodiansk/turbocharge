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

exit $rc
