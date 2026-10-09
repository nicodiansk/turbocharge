#!/usr/bin/env bash
# ABOUTME: Asserts no tracked file except CHANGELOG.md names the pre-3.0.1 GitHub repo path or its clone dir.
# ABOUTME: The old name is split in OLD below so this file never matches itself; the historical *-marketplace sibling repo is allowed.
OLD="turbo""charge"
rc=0
REPO_HITS=$(git -C "$PLUGIN_DIR" grep -nE "nicodiansk/${OLD}(\$|[^-])" -- . ':!CHANGELOG.md')
[ -z "$REPO_HITS" ] || { echo "    old repo path nicodiansk/$OLD still present:"; echo "$REPO_HITS" | sed 's/^/      /'; rc=1; }
DIR_HITS=$(git -C "$PLUGIN_DIR" grep -nE "plugin-dir [^ ]*${OLD}|^${OLD}/" -- . ':!CHANGELOG.md')
[ -z "$DIR_HITS" ] || { echo "    old clone-dir label $OLD/ still present:"; echo "$DIR_HITS" | sed 's/^/      /'; rc=1; }
exit $rc
