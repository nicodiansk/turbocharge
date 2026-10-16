#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [2.8.1] entry documenting the Stop-hook removal.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[2\.8\.1\]" "$F" || { echo "    missing [2.8.1] entry"; exit 1; }
assert_grep "$F" "stop-wrap-reminder.sh" || exit 1
assert_grep "$F" "1 hook" || exit 1
