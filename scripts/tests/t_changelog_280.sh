#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [2.8.0] capability-refresh entry naming each work item.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[2\.8\.0\]" "$F" || { echo "    missing [2.8.0] entry"; exit 1; }
assert_grep "$F" "effort"        || exit 1
assert_grep "$F" "maxTurns"      || exit 1
assert_grep "$F" "displayName"   || exit 1
assert_grep "$F" "[Aa]gent [Tt]eams" || exit 1
assert_grep "$F" "additionalContext" || exit 1
