#!/usr/bin/env bash
# ABOUTME: Asserts no tracked file names the 3.0.1–3.1.x GitHub repo path or its clone dir (3.2.0 renamed the repo back).
# ABOUTME: The old name is split in OLD so this file never matches itself; CHANGELOG.md and the historical [3.0.1] test are exempt.
OLD="turbo""flow"
rc=0
REPO_HITS=$(git -C "$PLUGIN_DIR" grep -nE "nicodiansk/${OLD}(\$|[^-])" -- . ':!CHANGELOG.md' ':!scripts/tests/t_changelog_301.sh' || true)
[ -z "$REPO_HITS" ] || { echo "    old repo path nicodiansk/$OLD still present:"; echo "$REPO_HITS" | sed 's/^/      /'; rc=1; }
DIR_HITS=$(git -C "$PLUGIN_DIR" grep -nE "plugin-dir [^ ]*${OLD}|^${OLD}/" -- . ':!CHANGELOG.md' || true)
[ -z "$DIR_HITS" ] || { echo "    old clone-dir label $OLD/ still present:"; echo "$DIR_HITS" | sed 's/^/      /'; rc=1; }
exit $rc
