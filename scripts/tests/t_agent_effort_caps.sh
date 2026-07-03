#!/usr/bin/env bash
# ABOUTME: Asserts the effort/maxTurns capability-refresh fields are present per agent.
# ABOUTME: researcher=low+maxTurns, code-reviewer=high, planner=high, task-reviewer=medium.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"

R="$PLUGIN_DIR/agents/researcher.md"
CR="$PLUGIN_DIR/agents/code-reviewer.md"
P="$PLUGIN_DIR/agents/planner.md"
TR="$PLUGIN_DIR/agents/task-reviewer.md"

assert_grep "$R"  "^effort: low"        || exit 1
assert_grep "$R"  "^maxTurns: 25"       || exit 1
assert_grep "$CR" "^effort: high"       || exit 1
assert_grep "$P"  "^effort: high"       || exit 1
# planner must keep model: inherit even with effort added
assert_grep "$P"  "^model: inherit"     || exit 1
assert_grep "$TR" "^effort: medium"     || exit 1
# builder must NOT carry an effort field (inherits)
assert_no_grep "$PLUGIN_DIR/agents/builder.md" "^effort:" || exit 1
