#!/usr/bin/env bash
# ABOUTME: Asserts the task-reviewer reviews a lane's diff and judges it directly, with no section on a report build never sends.
# ABOUTME: The description keeps "does NOT trust builder reports" (routing text); the body says one lane, not one task.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
rc=0
T="$PLUGIN_DIR/agents/task-reviewer.md"
assert_file "$T" || exit 1
BODY=$(tr -d '\r' < "$T" | awk 'NR==1 && $0=="---" { f=1; next } f && $0=="---" { f=0; next } !f')
for p in "one lane's diff" '## Judge the Diff' "spec of the lane's tasks verbatim" "that the tasks did not ask for"; do
    printf '%s\n' "$BODY" | grep -qF -- "$p" || { echo "    body missing: $p"; rc=1; }
done
for p in "one task's diff" 'CRITICAL' 'older two-agent' 'suspiciously'; do
    printf '%s\n' "$BODY" | grep -qF -- "$p" && { echo "    body must not have: $p"; rc=1; }
done
frontmatter "$T" | grep -qF -- 'does NOT trust builder reports' || { echo "    description lost: does NOT trust builder reports"; rc=1; }
exit $rc
