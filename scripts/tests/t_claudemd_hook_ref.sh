#!/usr/bin/env bash
# ABOUTME: Tests CLAUDE.md no longer references PreToolUse hook (deleted in hooks.json).
# ABOUTME: Verifies hook inventory says 2 hooks (SessionStart, Stop), not 3.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CLAUDE.md"
assert_grep "$F" "SessionStart, Stop" || exit 1
assert_no_grep "$F" "SessionStart, PreToolUse, Stop" || exit 1
assert_no_grep "$F" "3 hooks (SessionStart bootstrap, PreToolUse codemap nudge, Stop wrap reminder)" || exit 1
