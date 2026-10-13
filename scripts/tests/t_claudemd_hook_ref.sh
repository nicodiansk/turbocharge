#!/usr/bin/env bash
# ABOUTME: Tests CLAUDE.md and README hook inventories reflect the two hooks (SessionStart, builder exit gate).
# ABOUTME: Also forbids stale Stop references (the Stop wrap reminder was removed in 2.8.1).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/.claude/CLAUDE.md"
assert_grep "$F" "2 hooks (SessionStart" || exit 1
assert_no_grep "$F" "1 hook (SessionStart" || exit 1
assert_no_grep "$F" "Stop wrap reminder" || exit 1
assert_no_grep "$F" "SessionStart, Stop" || exit 1
assert_no_grep "$PLUGIN_DIR/README.md" '| \*\*Stop\*\* |' || exit 1
