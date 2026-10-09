#!/usr/bin/env bash
# ABOUTME: Asserts marketplace.json carries a top-level renames map turbocharge -> turboflow.
# ABOUTME: Claude Code 2.1.193+ follows it and rewrites users' enabledPlugins/pluginConfigs keys.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
M="$PLUGIN_DIR/.claude-plugin/marketplace.json"
assert_file "$M" || exit 1
# jq-free check first, so a missing jq can't mask a missing map.
assert_grep "$M" '"turbocharge": "turboflow"' || exit 1
assert_jq "$M" '.renames.turbocharge == "turboflow"' || exit 1
# Target must resolve to a listed plugin (claude plugin validate rejects dangling chains).
assert_jq "$M" '.renames.turbocharge as $t | any(.plugins[]; .name == $t)' || exit 1
# Top-level only — not under metadata or inside a plugin entry.
assert_jq "$M" '(.metadata.renames == null) and all(.plugins[]; .renames == null)' || exit 1
