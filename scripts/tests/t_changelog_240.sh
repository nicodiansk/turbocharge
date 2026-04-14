#!/usr/bin/env bash
# ABOUTME: Tests CHANGELOG.md has a [2.4.0] entry with required keywords.
# ABOUTME: Verifies ATLAS pre-load, PreToolUse removal, CLAUDE.md bootstrap, session snapshot.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[2\.4\.0\]" "$F" || { echo "    missing [2.4.0] entry"; exit 1; }
assert_grep "$F" "ATLAS pre-load"        || exit 1
assert_grep "$F" "PreToolUse"            || exit 1
assert_grep "$F" "CLAUDE.md bootstrap"   || exit 1
assert_grep "$F" "session snapshot"      || exit 1
