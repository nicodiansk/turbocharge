#!/usr/bin/env bash
# ABOUTME: Tests that plugin.json and marketplace.json versions are in lockstep.
# ABOUTME: Checks all three version fields match each other (not a hardcoded value).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
M="$PLUGIN_DIR/.claude-plugin/marketplace.json"
assert_file "$P" || exit 1
assert_file "$M" || exit 1
if command -v jq >/dev/null 2>&1; then
    V=$(jq -r '.version' "$P")
    MV=$(jq -r '.metadata.version' "$M")
    PV=$(jq -r '.plugins[0].version' "$M")
    [ "$V" = "$MV" ] || { echo "    plugin.json ($V) != marketplace metadata ($MV)"; exit 1; }
    [ "$V" = "$PV" ] || { echo "    plugin.json ($V) != marketplace plugins[0] ($PV)"; exit 1; }
else
    V=$(grep -o '"version": "[^"]*"' "$P" | head -1 | sed 's/.*: "//;s/"//')
    MV=$(grep -o '"version": "[^"]*"' "$M" | head -1 | sed 's/.*: "//;s/"//')
    PV=$(grep -o '"version": "[^"]*"' "$M" | tail -1 | sed 's/.*: "//;s/"//')
    [ "$V" = "$MV" ] || { echo "    plugin.json ($V) != marketplace ($MV)"; exit 1; }
    [ "$V" = "$PV" ] || { echo "    plugin.json ($V) != marketplace plugins ($PV)"; exit 1; }
fi
