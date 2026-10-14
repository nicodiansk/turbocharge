#!/usr/bin/env bash
# ABOUTME: Asserts validate.sh runs strict validate on the plugin manifest, not only the marketplace.
# ABOUTME: `claude plugin validate <dir>` targets marketplace.json only; plugin.json mode checks skills and agents.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
V="$PLUGIN_DIR/scripts/validate.sh"
assert_grep "$V" 'claude plugin validate "\$PLUGIN_DIR/.claude-plugin/plugin.json" --strict' || exit 1
assert_grep "$V" 'claude plugin validate "\$PLUGIN_DIR" --strict' || exit 1
if ! command -v claude >/dev/null 2>&1; then
    echo "    claude CLI not installed, skipping plugin-mode behavior check"
    exit 0
fi
SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/tc-validate.XXXXXX")
trap 'rm -rf "$SCRATCH"' EXIT
git -C "$PLUGIN_DIR" archive HEAD | tar -x -C "$SCRATCH"
printf '%s\n' '---' 'name: zz' 'model: sonnet' '---' 'body' > "$SCRATCH/agents/zz.md"
if claude plugin validate "$SCRATCH/.claude-plugin/plugin.json" --strict >/dev/null 2>&1; then
    echo "    plugin-mode strict validate accepted an agent with no description"
    exit 1
fi
exit 0
