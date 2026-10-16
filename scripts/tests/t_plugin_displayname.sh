#!/usr/bin/env bash
# ABOUTME: Asserts plugin.json has displayName "Turbocharge" and keeps name "turbocharge".
# ABOUTME: displayName is plugin.json-only; marketplace lockstep is unaffected.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
assert_file "$P" || exit 1
assert_jq "$P" '.displayName == "Turbocharge"' || exit 1
assert_jq "$P" '.name == "turbocharge"'        || exit 1
