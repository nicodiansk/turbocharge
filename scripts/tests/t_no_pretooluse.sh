#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/hooks.json"
assert_file "$F" || exit 1
assert_no_grep "$F" "PreToolUse"          || exit 1
assert_no_grep "$F" "pretool-read-codemap" || exit 1
[ ! -f "$PLUGIN_DIR/hooks/pretool-read-codemap.sh" ] || { echo "    pretool-read-codemap.sh still exists"; exit 1; }
# hooks.json still parses as valid JSON
if command -v jq >/dev/null 2>&1; then
    jq -e '.hooks.SessionStart' "$F" >/dev/null || { echo "    SessionStart missing"; exit 1; }
    jq -e '.hooks.Stop' "$F" >/dev/null         || { echo "    Stop missing"; exit 1; }
fi
