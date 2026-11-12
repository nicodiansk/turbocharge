#!/usr/bin/env bash
# ABOUTME: Asserts the builder and build Step 4 forbid test shortcuts and state the two exceptions.
# ABOUTME: Tests with teeth, task 2: a Never section in builder.md, the same rules restated for inline lanes.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
B="$PLUGIN_DIR/agents/builder.md"
S="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$B" || exit 1
assert_file "$S" || exit 1
rc=0
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
NEVER=$(sec "$B" '## Never' '## ')
STEP4=$(sec "$S" '## Step 4' '## ')
LANE=$(grep -n '^## Lane Rules' "$B" | cut -d: -f1)
NV=$(grep -n '^## Never' "$B" | cut -d: -f1)
SR=$(grep -n '^## Self-Review Checklist' "$B" | cut -d: -f1)
if [ -z "$NV" ] || [ -z "$LANE" ] || [ -z "$SR" ] || ! [ "$LANE" -lt "$NV" ] || ! [ "$NV" -lt "$SR" ]; then
    echo "    builder.md needs '## Never' between '## Lane Rules' and '## Self-Review Checklist'"; rc=1
fi
for p in 'skip, mark xfail, delete or weaken a test (a looser assertion, fewer cases)' 'write the expected value into the code' "special-case the test's input" 'change a test to match the code' 'the old expectation → the new one' 'never weaken the test'; do
    printf '%s\n' "$NEVER" | grep -qF -- "$p" || { echo "    builder.md Never missing: $p"; rc=1; }
    printf '%s\n' "$STEP4" | grep -qF -- "$p" || { echo "    build Step 4 missing: $p"; rc=1; }
done
printf '%s\n' "$NEVER" | grep -qF '`Blocked on: design`' || { echo '    builder.md Never missing: `Blocked on: design`'; rc=1; }
printf '%s\n' "$STEP4" | grep -qF 'builder.md' && { echo "    build Step 4 must not point to builder.md"; rc=1; }
CHECK=$(sec "$B" '## Self-Review Checklist' '## ')
printf '%s\n' "$CHECK" | grep -qF 'Does every test still have its teeth: nothing skipped, weakened or hard-coded?' || { echo "    builder.md Self-Review Checklist missing the teeth question"; rc=1; }
KINDS=$(grep -oE 'Blocked on: [a-z |]+ —' "$B" | head -1)
case "$KINDS" in
    *'destructive | security | outside | design | context | stuck'*) ;;
    *) echo "    the first 'Blocked on: <kinds> —' match in builder.md lost a kind: $KINDS"; rc=1 ;;
esac
exit $rc
