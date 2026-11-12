#!/usr/bin/env bash
# ABOUTME: Asserts task-reviewer and code-reviewer read for toothless tests and test shortcuts, with set severities.
# ABOUTME: Lab backlog 1b (tests with teeth): the same list in both reviewers; a shortcut is Critical, a toothless pin Important.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
T="$PLUGIN_DIR/agents/task-reviewer.md"
C="$PLUGIN_DIR/agents/code-reviewer.md"
assert_file "$T" || exit 1
assert_file "$C" || exit 1
rc=0

TV=$(awk '{ sub(/\r$/, "") } /^## Verdict 2/ { s=1 } /^## Report Shape/ { s=0 } s' "$T")
CQ=$(awk '{ sub(/\r$/, "") } /^3\. \*\*Code Quality\*\*/ { s=1 } /^4\. \*\*Architecture/ { s=0 } s' "$C")
[ -n "$TV" ] || { echo "    task-reviewer.md has no '## Verdict 2' section"; exit 1; }
[ -n "$CQ" ] || { echo "    code-reviewer.md has no '3. **Code Quality**' item"; exit 1; }

LIST=(
    'is not None' 'len > 0' 'truthiness only'
    'a mock that returns the very value the test expects'
    'no assertion on the output'
    'snapshots regenerated in the same change as the code'
    'a test skipped, marked xfail, deleted or weakened'
    'the expected value written into the code'
    "the test's input special-cased"
    'a test changed to match the code'
    "a test change the plan's Decision calls for"
    'a skip when a tool is missing'
    'a deletion the plan names'
    'A shortcut hides a failure: 🔴 Critical'
    "the only test for a Review Focus pin or for the task's main behavior"
    '🟡 Important'
)
for p in "${LIST[@]}"; do
    printf '%s\n' "$TV" | grep -qF -- "$p" || { echo "    task-reviewer.md Verdict 2 missing: $p"; rc=1; }
    printf '%s\n' "$CQ" | grep -qF -- "$p" || { echo "    code-reviewer.md 3. Code Quality missing: $p"; rc=1; }
done
printf '%s\n' "$CQ" | grep -qF 'a toothless pin is a missing pin' \
    || { echo "    code-reviewer.md 3. Code Quality missing: a toothless pin is a missing pin"; rc=1; }

# The old one-line test bullets are gone (each keeps its lead words and gains the list).
tr -d '\r' < "$T" | grep -qxF -- '- **Test rigor** — tests verify behavior (not mocks), cover edge cases.' \
    && { echo "    task-reviewer.md still has the old Test rigor line"; rc=1; }
tr -d '\r' < "$C" | grep -qxF -- '   - Test coverage and test quality' \
    && { echo "    code-reviewer.md still has the old test quality line"; rc=1; }
exit $rc
