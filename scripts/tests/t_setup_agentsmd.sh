#!/usr/bin/env bash
# ABOUTME: Asserts setup creates CLAUDE.md with @AGENTS.md as its first line when only AGENTS.md exists.
# ABOUTME: By default Claude Code reads AGENTS.md only when no CLAUDE.md exists, so the import keeps it loading.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/setup/SKILL.md"
assert_file "$F" || exit 1
grep -qF 'create CLAUDE.md with `@AGENTS.md` as its first line' "$F" \
    || { echo "    setup must create CLAUDE.md starting with @AGENTS.md"; exit 1; }
assert_grep "$F" "If neither CLAUDE.md nor AGENTS.md exists" || exit 1
# Existing CLAUDE.md + AGENTS.md without the import → AGENTS.md is silently ignored; setup must offer the import.
grep -qF 'offer to add `@AGENTS.md` as its first line' "$F" \
    || { echo "    setup must offer the @AGENTS.md import for an existing CLAUDE.md"; exit 1; }
# Loading facts as the docs state them: rules, the Project instructions setting, the version floor.
for p in 'Project instructions' 'claude-md-and-agents-md' 'v2.1.277' 'without `paths:` frontmatter loads at every session start'; do
    grep -qF -- "$p" "$F" || { echo "    setup missing: $p"; exit 1; }
done
for p in 'ignores AGENTS.md whenever' 'loaded into context on every turn' '~2,000 tokens'; do
    grep -qF -- "$p" "$F" && { echo "    setup still says: $p"; exit 1; }
done
exit 0
