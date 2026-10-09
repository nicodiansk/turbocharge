#!/usr/bin/env bash
# ABOUTME: Asserts no tracked file still uses the title-case pre-3.0.0 brand "Turbocharge".
# ABOUTME: CHANGELOG.md is exempt (historical entries); lowercase repo/clone-dir paths are out of scope.
OLD_BRAND="Turbo""charge"
HITS=$(git -C "$PLUGIN_DIR" grep -n "$OLD_BRAND" -- . ':!CHANGELOG.md')
[ -z "$HITS" ] || { echo "    title-case '$OLD_BRAND' still present:"; echo "$HITS" | sed 's/^/      /'; exit 1; }
