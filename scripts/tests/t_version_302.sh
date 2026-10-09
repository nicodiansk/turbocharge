#!/usr/bin/env bash
# ABOUTME: Asserts the directory-ready release bumped plugin.json — the only version field since 3.0.2 — to 3.0.2.
# ABOUTME: grep-only, so a missed bump is caught even without jq.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
assert_file "$P" || exit 1
grep -qF '"version": "3.0.2"' "$P" || { echo "    plugin.json version is not 3.0.2"; exit 1; }
