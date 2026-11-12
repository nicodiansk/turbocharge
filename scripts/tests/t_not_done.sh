#!/usr/bin/env bash
# ABOUTME: Asserts builders report a Not done line and build treats DONE with unfinished work as DONE_WITH_CONCERNS.
# ABOUTME: Tests with teeth, task 5: builder.md Report Format and Status bullets; build Steps 3, 5 and 7.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
B="$PLUGIN_DIR/agents/builder.md"
S="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$B" || exit 1
assert_file "$S" || exit 1
rc=0
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
REPORT=$(sec "$B" '## Report Format' '## ')
printf '%s\n' "$REPORT" | grep -qF '`Not done: <what in the lane'"'"'s tasks wasn'"'"'t built, or was left out on purpose, and why> | none`' || { echo "    builder.md Report Format missing the Not done line"; rc=1; }
ln() { printf '%s\n' "$REPORT" | grep -nF -- "$1" | head -1 | cut -d: -f1; }
A=$(ln 'Commit SHA'); N=$(ln 'Not done:'); M=$(ln 'Mutation:'); R=$(ln '**Rulings**')
if [ -z "$A" ] || [ -z "$N" ] || [ -z "$M" ] || [ -z "$R" ] || ! [ "$A" -lt "$N" ] || ! [ "$N" -lt "$M" ] || ! [ "$M" -lt "$R" ]; then
    echo "    builder.md Report Format order must be Commit SHA < Not done: < Mutation: < Rulings ($A $N $M $R)"; rc=1
fi
for p in 'With a `Not done:` other than `none`, the Status is not `DONE`' 'with `Not done: none`'; do
    grep -qF -- "$p" "$B" || { echo "    builder.md missing: $p"; rc=1; }
done
STEP3=$(sec "$S" '## Step 3' '## ')
STEP5=$(sec "$S" '## Step 5' '## Step 6')
STEP7=$(sec "$S" '## Step 7' '## ')
printf '%s\n' "$STEP3" | grep -qF 'then `Not done:` and `Mutation:`; then Rulings' || { echo "    build Step 3 missing the Not done report rule"; rc=1; }
grep -qF 'test result; then Rulings' "$S" && { echo "    build still says: test result; then Rulings"; rc=1; }
for p in 'Not done: not reported' '`DONE` with a `Not done:` other than `none`' \
    'DONE or DONE_WITH_CONCERNS with no `Not done:` line' 'A BLOCKED report follows its `Blocked on:` kind'; do
    printf '%s\n' "$STEP5" | grep -qF -- "$p" || { echo "    build Step 5 missing: $p"; rc=1; }
done
# Review 🟡 2: unscoped, the rule turned a BLOCKED report (the one most likely to lack the line) into a finished lane.
printf '%s\n' "$STEP5" | grep -qF -- '- **No `Not done:` line** →' && { echo "    build Step 5 still has the unscoped No Not done line rule"; rc=1; }
for p in '`Not done:`' 'states its own'; do
    printf '%s\n' "$STEP7" | grep -qF -- "$p" || { echo "    build Step 7 missing: $p"; rc=1; }
done
exit $rc
