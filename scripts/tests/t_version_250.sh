#!/usr/bin/env bash
# ABOUTME: Tests that plugin.json and marketplace.json are both at version 2.5.0.
# ABOUTME: Checks all three version fields are in lockstep.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
M="$PLUGIN_DIR/.claude-plugin/marketplace.json"
assert_file "$P" || exit 1
assert_file "$M" || exit 1
if command -v jq >/dev/null 2>&1; then
    jq -e '.version == "2.5.0"' "$P" >/dev/null || { echo "    plugin.json version != 2.5.0"; exit 1; }
    jq -e '.metadata.version == "2.5.0"' "$M" >/dev/null || { echo "    marketplace.json metadata.version != 2.5.0"; exit 1; }
    jq -e '.plugins[0].version == "2.5.0"' "$M" >/dev/null || { echo "    marketplace.json plugins[0].version != 2.5.0"; exit 1; }
else
    grep -q '"version": "2\.5\.0"' "$P" || { echo "    plugin.json version"; exit 1; }
    grep -q '"version": "2\.5\.0"' "$M" || { echo "    marketplace.json version"; exit 1; }
fi
