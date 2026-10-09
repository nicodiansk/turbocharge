#!/usr/bin/env bash
# ABOUTME: Asserts the GitHub repo-rename release bumped to 3.0.1 in all three version fields.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
M="$PLUGIN_DIR/.claude-plugin/marketplace.json"
assert_jq "$P" '.version == "3.0.1"'            || exit 1
assert_jq "$M" '.metadata.version == "3.0.1"'   || exit 1
assert_jq "$M" '.plugins[0].version == "3.0.1"' || exit 1
