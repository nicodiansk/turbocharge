#!/usr/bin/env bash
# ABOUTME: Asserts every place a skill picks, reads or edits CLAUDE.md also handles projects that keep it at .claude/CLAUDE.md.
# ABOUTME: Covers build/plan/review prefixes, wrap, atlas, and setup's import form (@../AGENTS.md resolves from .claude/).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills"
count() { grep -oF -- "$1" "$2" | wc -l; }

# Dispatch prefixes: .claude/CLAUDE.md is a CLAUDE.md (so the AGENTS.md fallback does not apply).
[ "$(count '@.claude/CLAUDE.md' "$S/build/SKILL.md")" -ge 2 ] \
    || { echo "    build: @.claude/CLAUDE.md needed on builder and researcher prefixes"; exit 1; }
[ "$(count 'counts as a CLAUDE.md' "$S/build/SKILL.md")" -ge 2 ] \
    || { echo "    build: prefixes must say .claude/CLAUDE.md counts as a CLAUDE.md"; exit 1; }
for s in plan review; do
    grep -qF '@.claude/CLAUDE.md' "$S/$s/SKILL.md"      || { echo "    skills/$s: missing @.claude/CLAUDE.md"; exit 1; }
    grep -qF 'counts as a CLAUDE.md' "$S/$s/SKILL.md"   || { echo "    skills/$s: must say .claude/CLAUDE.md counts as a CLAUDE.md"; exit 1; }
done

# wrap: resume prompt + the "Update CLAUDE.md" step must not create a second, root-level file.
grep -qF '@.claude/CLAUDE.md' "$S/wrap/SKILL.md" || { echo "    wrap: resume prompt missing @.claude/CLAUDE.md"; exit 1; }
[ "$(count '.claude/CLAUDE.md' "$S/wrap/SKILL.md")" -ge 2 ] \
    || { echo "    wrap: 'Update CLAUDE.md' step must name .claude/CLAUDE.md"; exit 1; }

# atlas: reading CLAUDE.md must find .claude/CLAUDE.md too.
grep -qF '.claude/CLAUDE.md' "$S/atlas/SKILL.md" || { echo "    atlas: 'Read CLAUDE.md' step must name .claude/CLAUDE.md"; exit 1; }

# setup: edit the existing file; imports resolve relative to the importing file.
grep -qF '`./.claude/CLAUDE.md`' "$S/setup/SKILL.md" || { echo "    setup must name ./.claude/CLAUDE.md"; exit 1; }
assert_grep "$S/setup/SKILL.md" "never create a second" || exit 1
grep -qF '`@../AGENTS.md`' "$S/setup/SKILL.md" \
    || { echo "    setup: inside .claude/CLAUDE.md the import is @../AGENTS.md"; exit 1; }
exit 0
