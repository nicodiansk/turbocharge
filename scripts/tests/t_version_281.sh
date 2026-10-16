#!/usr/bin/env bash
# ABOUTME: Asserts the Stop-hook-removal patch bumped to 2.8.1 in all three version fields.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
M="$PLUGIN_DIR/.claude-plugin/marketplace.json"
assert_jq "$P" '.version == "2.8.1"'            || exit 1
assert_jq "$M" '.metadata.version == "2.8.1"'   || exit 1
assert_jq "$M" '.plugins[0].version == "2.8.1"' || exit 1
