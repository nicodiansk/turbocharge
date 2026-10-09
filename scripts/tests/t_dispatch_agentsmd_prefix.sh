#!/usr/bin/env bash
# ABOUTME: Asserts every subagent dispatch prefix (build builder/researcher, plan, review) falls back to @AGENTS.md.
# ABOUTME: Projects with AGENTS.md and no CLAUDE.md must still hand subagents their conventions.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
B="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$B" || exit 1
grep -qF '`@CLAUDE.md` (conventions) — or `@AGENTS.md` if the project has no CLAUDE.md' "$B" \
    || { echo "    build Step 3a builder prefix missing @AGENTS.md fallback"; exit 1; }
grep -qF '`@ATLAS.md @AGENTS.md` if the project has no CLAUDE.md' "$B" \
    || { echo "    build Step 4b researcher prefix missing @AGENTS.md fallback"; exit 1; }
for s in plan review; do
    F="$PLUGIN_DIR/skills/$s/SKILL.md"
    assert_file "$F" || exit 1
    grep -qF 'use `@AGENTS.md` in its place' "$F" \
        || { echo "    skills/$s/SKILL.md dispatch prefix missing @AGENTS.md fallback"; exit 1; }
done
exit 0
