#!/usr/bin/env bash
# ABOUTME: Tests that planner, researcher, code-reviewer agents reference ATLAS.md.
# ABOUTME: Also verifies builder, task-reviewer do NOT reference ATLAS.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
for a in planner researcher code-reviewer; do
    F="$PLUGIN_DIR/agents/$a.md"
    assert_file "$F" || exit 1
    grep -qi "ATLAS" "$F" || { echo "    $a.md missing ATLAS reference"; exit 1; }
    grep -qi "read.*ATLAS" "$F" || grep -qi "ATLAS.*first" "$F" || grep -qi "ATLAS.*pre-loaded" "$F" || { echo "    $a.md missing ATLAS navigation instruction"; exit 1; }
done
# Builder, task-reviewer must NOT reference ATLAS (per design)
for a in builder task-reviewer; do
    F="$PLUGIN_DIR/agents/$a.md"
    [ -f "$F" ] || continue
    if grep -qi "ATLAS" "$F"; then echo "    $a.md unexpectedly references ATLAS (design says no)"; exit 1; fi
done
