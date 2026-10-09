#!/usr/bin/env bash
# ABOUTME: Tests the version lives only in plugin.json (it wins over the marketplace entry; the docs say set it once).
# ABOUTME: plugin.json must carry a semver version; marketplace.json must carry none. grep-only, so it never skips without jq.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
M="$PLUGIN_DIR/.claude-plugin/marketplace.json"
assert_file "$P" || exit 1
assert_file "$M" || exit 1
grep -qE '"version": "[0-9]+\.[0-9]+\.[0-9]+"' "$P" || { echo "    plugin.json has no semver version"; exit 1; }
if grep -q '"version"' "$M"; then
    echo "    marketplace.json carries a version — it lives only in plugin.json"; exit 1
fi
exit 0
