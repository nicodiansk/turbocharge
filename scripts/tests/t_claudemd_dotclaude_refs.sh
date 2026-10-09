#!/usr/bin/env bash
# ABOUTME: Asserts every place a skill picks @CLAUDE.md also handles projects that keep it at .claude/CLAUDE.md.
# ABOUTME: Covers build (builder + researcher prefixes), plan, review, wrap's resume prompt, and setup's CLAUDE.md phase.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills"
N=$(grep -oF '@.claude/CLAUDE.md' "$S/build/SKILL.md" | wc -l)
[ "$N" -ge 2 ] || { echo "    build: @.claude/CLAUDE.md fallback needed on builder and researcher prefixes (found $N)"; exit 1; }
for s in plan review wrap; do
    grep -qF '@.claude/CLAUDE.md' "$S/$s/SKILL.md" \
        || { echo "    skills/$s/SKILL.md missing @.claude/CLAUDE.md fallback"; exit 1; }
done
grep -qF '`./.claude/CLAUDE.md`' "$S/setup/SKILL.md" || { echo "    setup must name ./.claude/CLAUDE.md"; exit 1; }
assert_grep "$S/setup/SKILL.md" "never create a second" || exit 1
exit 0
