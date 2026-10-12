#!/usr/bin/env bash
# ABOUTME: Asserts build waits for every background builder's completion notification at the join before moving on.
# ABOUTME: Also asserts builders are dispatched without a `name` (a named spawn joins the implicit team as a teammate).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$F" || exit 1
assert_grep "$F" "### 5a. Wait for the Completion Notifications" || exit 1
grep -qF 'without** a `name` parameter' "$F" \
    || { echo "    builders must be dispatched without a name parameter"; exit 1; }
# The wait gates the full gate, dependent lanes, and the reviewer.
for p in 'run the full gate' 'start a lane that lists it in `After`' 'dispatch a task-reviewer'; do
    grep -qF "$p" "$F" || { echo "    join wait must gate: $p"; exit 1; }
done
# Reviewed mode waits on the task-reviewer too.
grep -qF "wait for its completion notification" "$F" \
    || { echo "    reviewed mode must wait for the task-reviewer"; exit 1; }
# A Red Flags row names the violation.
awk '/^## Red Flags/{f=1} f' "$F" | grep -q "completion notification" \
    || { echo "    Red Flags table missing completion-notification row"; exit 1; }
exit 0
