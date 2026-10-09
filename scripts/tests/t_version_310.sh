#!/usr/bin/env bash
# ABOUTME: Asserts the fast-build release bumped plugin.json (the only version field since 3.0.2) to 3.1.0.
# ABOUTME: grep-only, so a missed bump is caught even without jq.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
assert_file "$P" || exit 1
grep -qF '"version": "3.1.0"' "$P" || { echo "    plugin.json version is not 3.1.0"; exit 1; }
