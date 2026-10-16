#!/usr/bin/env bash
# ABOUTME: Tests CLAUDE.md hook inventory reflects the single remaining hook.
# ABOUTME: Verifies it says 1 hook (SessionStart), with no stale Stop/PreToolUse references.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CLAUDE.md"
assert_grep "$F" "1 hook (SessionStart" || exit 1
assert_no_grep "$F" "2 hooks" || exit 1
assert_no_grep "$F" "Stop wrap reminder" || exit 1
assert_no_grep "$F" "SessionStart, Stop" || exit 1
