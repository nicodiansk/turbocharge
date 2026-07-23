#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.0.0] entry documenting the turboflow namespace rename.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.0\.0\]" "$F" || { echo "    missing [3.0.0] entry"; exit 1; }
assert_grep "$F" "turboflow" || exit 1
assert_grep "$F" "BREAKING" || exit 1
