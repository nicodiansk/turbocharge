#!/usr/bin/env bash
# ABOUTME: Asserts setup creates CLAUDE.md with @AGENTS.md as its first line when only AGENTS.md exists.
# ABOUTME: Claude Code reads AGENTS.md only when no CLAUDE.md exists, so the import keeps it loading.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/setup/SKILL.md"
assert_file "$F" || exit 1
grep -qF 'create CLAUDE.md with `@AGENTS.md` as its first line' "$F" \
    || { echo "    setup must create CLAUDE.md starting with @AGENTS.md"; exit 1; }
assert_grep "$F" "If neither CLAUDE.md nor AGENTS.md exists" || exit 1
# Existing CLAUDE.md + AGENTS.md without the import → AGENTS.md is silently ignored; setup must offer the import.
grep -qF 'offer to add `@AGENTS.md` as its first line' "$F" \
    || { echo "    setup must offer the @AGENTS.md import for an existing CLAUDE.md"; exit 1; }
exit 0
