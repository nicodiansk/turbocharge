#!/usr/bin/env bash
# ABOUTME: Asserts the capability-refresh release bumped to 2.8.0 in all three version fields.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
M="$PLUGIN_DIR/.claude-plugin/marketplace.json"
assert_jq "$P" '.version == "2.8.0"'            || exit 1
assert_jq "$M" '.metadata.version == "2.8.0"'   || exit 1
assert_jq "$M" '.plugins[0].version == "2.8.0"' || exit 1
