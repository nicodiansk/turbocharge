#!/usr/bin/env bash
# ABOUTME: Asserts build waits for each background subagent's completion notification before moving on.
# ABOUTME: Also asserts single-track builders are dispatched without a `name` (named spawns become teammates).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$F" || exit 1
assert_grep "$F" "### 3b. Wait for the Completion Notification" || exit 1
grep -qF 'without** a `name` parameter' "$F" \
    || { echo "    Step 3a must dispatch builders without a name parameter"; exit 1; }
# The wait gates the next dispatch, the next BEFORE_SHA capture, and the reviewer.
grep -qF 'capture the next `BEFORE_SHA`' "$F" \
    || { echo "    wait rule must gate the next BEFORE_SHA capture"; exit 1; }
# Reviewed-mode sequence waits on the task-reviewer too.
grep -qF "wait for its completion notification" "$F" \
    || { echo "    Step 4 sequence must wait for the task-reviewer"; exit 1; }
# A Red Flags row names the violation.
awk '/^## Red Flags/{f=1} f' "$F" | grep -q "completion notification" \
    || { echo "    Red Flags table missing completion-notification row"; exit 1; }
exit 0
