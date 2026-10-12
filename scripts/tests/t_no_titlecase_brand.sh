#!/usr/bin/env bash
# ABOUTME: Asserts no tracked file still uses the title-case 3.0.0–3.1.x brand (spelled out in OLD_BRAND below).
# ABOUTME: 3.2.0 restored Turbocharge. CHANGELOG.md is exempt (historical entries); lowercase compat names are out of scope.
OLD_BRAND="Turbo""flow"
HITS=$(git -C "$PLUGIN_DIR" grep -n "$OLD_BRAND" -- . ':!CHANGELOG.md' || true)
[ -z "$HITS" ] || { echo "    title-case '$OLD_BRAND' still present:"; echo "$HITS" | sed 's/^/      /'; exit 1; }
