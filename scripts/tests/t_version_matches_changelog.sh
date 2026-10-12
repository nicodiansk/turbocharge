#!/usr/bin/env bash
# ABOUTME: Asserts plugin.json `version` (the only version field since 3.0.2) equals the newest CHANGELOG heading.
# ABOUTME: Replaces per-release t_version_<x>.sh files; grep/sed only, so it never skips without jq.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
C="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$P" || exit 1
assert_file "$C" || exit 1
V=$(sed -n 's/.*"version": "\([0-9][0-9.]*\)".*/\1/p' "$P" | head -1)
CV=$(sed -n 's/^## \[\([0-9][0-9.]*\)\].*/\1/p' "$C" | head -1)
[ -n "$V" ]  || { echo "    plugin.json has no version"; exit 1; }
[ -n "$CV" ] || { echo "    CHANGELOG has no ## [x.y.z] heading"; exit 1; }
[ "$V" = "$CV" ] || { echo "    plugin.json version $V != newest CHANGELOG entry $CV"; exit 1; }
