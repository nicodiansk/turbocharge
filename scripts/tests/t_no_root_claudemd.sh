#!/usr/bin/env bash
# ABOUTME: Asserts project instructions live in .claude/CLAUDE.md, not the plugin root.
# ABOUTME: A root CLAUDE.md is not loaded as plugin context and fails `claude plugin validate --strict`.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
[ ! -f "$PLUGIN_DIR/CLAUDE.md" ] || { echo "    root CLAUDE.md present — fails plugin validate --strict"; exit 1; }
assert_file "$PLUGIN_DIR/.claude/CLAUDE.md" || exit 1
git -C "$PLUGIN_DIR" ls-files --error-unmatch .claude/CLAUDE.md >/dev/null 2>&1 \
    || { echo "    .claude/CLAUDE.md is not tracked"; exit 1; }
G="$PLUGIN_DIR/.gitignore"
grep -qE '^/CLAUDE\.md\r?$' "$G" || { echo "    .gitignore must ignore only the root /CLAUDE.md"; exit 1; }
if grep -qE '^CLAUDE\.md\r?$' "$G"; then echo "    bare CLAUDE.md in .gitignore also ignores .claude/CLAUDE.md"; exit 1; fi
exit 0
