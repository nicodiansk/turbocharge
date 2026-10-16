#!/usr/bin/env bash
# ABOUTME: Tests that atlas SKILL.md contains codemap integration instructions.
# ABOUTME: Verifies .codemap reference, Module Map/Key Symbols mentions, and graceful fallback.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/atlas/SKILL.md"
assert_file "$F" || exit 1
assert_grep "$F" "\.codemap/\.codemap\.json" || exit 1
assert_grep "$F" "Module Map"                 || exit 1
assert_grep "$F" "Key Symbols"                || exit 1
assert_grep "$F" "skip this step"             || exit 1
