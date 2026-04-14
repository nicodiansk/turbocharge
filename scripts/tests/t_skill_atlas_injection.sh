#!/usr/bin/env bash
# ABOUTME: Tests that plan, build, review skills inject @ATLAS.md in dispatch prompts.
# ABOUTME: Verifies subagent dispatch includes the navigation index reference.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
for s in plan build review; do
    F="$PLUGIN_DIR/skills/$s/SKILL.md"
    assert_file "$F" || exit 1
    grep -q "@ATLAS.md" "$F" || { echo "    skills/$s/SKILL.md does not inject @ATLAS.md"; exit 1; }
done
