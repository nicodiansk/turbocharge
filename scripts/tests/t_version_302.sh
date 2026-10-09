#!/usr/bin/env bash
# ABOUTME: Asserts the directory-ready release bumped plugin.json — the only version field since 3.0.2 — to 3.0.2.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
assert_jq "$P" '.version == "3.0.2"' || exit 1
