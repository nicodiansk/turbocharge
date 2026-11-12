#!/usr/bin/env bash
# ABOUTME: Asserts RED must come from an assertion on the result, not an import error or a missing name.
# ABOUTME: Tests with teeth, task 1: builder.md and build Step 4 state the stub rule and the error-expecting case.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
B="$PLUGIN_DIR/agents/builder.md"
S="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$B" || exit 1
assert_file "$S" || exit 1
rc=0
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
PROCESS=$(sec "$B" '## Your Process' '## ')
CHECK=$(sec "$B" '## Self-Review Checklist' '## ')
REPORT=$(sec "$B" '## Report Format' '## ')
STEP4=$(sec "$S" '## Step 4' '## ')
for p in 'fails on an assertion about the result' 'is not RED' 'stub' 'neutral value' "the error doesn't come"; do
    printf '%s\n' "$PROCESS" | grep -qF -- "$p" || { echo "    builder.md Your Process missing: $p"; rc=1; }
done
printf '%s\n' "$CHECK" | grep -qF 'Did each RED come from an assertion, not an import or a missing name?' || { echo "    builder.md Self-Review Checklist missing the RED question"; rc=1; }
printf '%s\n' "$REPORT" | grep -qF 'RED evidence: the assertion that failed and the value it got' || { echo "    builder.md Report Format missing the RED evidence line"; rc=1; }
for p in 'is not RED' 'stub' "the error doesn't come"; do
    printf '%s\n' "$STEP4" | grep -qF -- "$p" || { echo "    build Step 4 missing: $p"; rc=1; }
done
for p in 'confirm it fails for the right reason' 'which assertion failed before the change, and why'; do
    grep -qF -- "$p" "$B" && { echo "    builder.md still says: $p"; rc=1; }
done
grep -qF 'it must fail for the reason the task names (RED)' "$S" && { echo "    build still says: it must fail for the reason the task names (RED)"; rc=1; }
exit $rc
