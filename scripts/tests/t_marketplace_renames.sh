#!/usr/bin/env bash
# ABOUTME: Asserts marketplace.json maps the 3.0–3.1 plugin name back: renames {"turboflow": "turbocharge"}.
# ABOUTME: The reverse 3.0.0 entry (turbocharge -> turboflow) must be gone, or the rename chain would cycle.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
M="$PLUGIN_DIR/.claude-plugin/marketplace.json"
assert_file "$M" || exit 1
assert_grep "$M" '"turboflow": "turbocharge"' || exit 1
grep -q '"turbocharge": "turboflow"' "$M" && { echo "    reverse rename turbocharge -> turboflow still present"; exit 1; }
assert_jq "$M" '.renames.turboflow == "turbocharge"' || exit 1
assert_jq "$M" '.renames | has("turbocharge") | not' || exit 1
assert_jq "$M" '.name == "turbocharge" and .plugins[0].name == "turbocharge"' || exit 1
