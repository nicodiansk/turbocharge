#!/usr/bin/env bash
# ABOUTME: Asserts plugin.json has displayName "Turboflow" and keeps name "turboflow".
# ABOUTME: displayName is plugin.json-only; marketplace.json does not repeat it.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
assert_file "$P" || exit 1
assert_jq "$P" '.displayName == "Turboflow"' || exit 1
assert_jq "$P" '.name == "turboflow"'        || exit 1
