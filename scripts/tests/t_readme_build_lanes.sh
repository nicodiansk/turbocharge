#!/usr/bin/env bash
# ABOUTME: Asserts README, the build diagram and CLAUDE.md describe lane-based build (3.1), not per-task builders.
# ABOUTME: Guards against the Agent Teams setup line, "complete code" plans and per-task review wording resurfacing.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
R="$PLUGIN_DIR/README.md"
SVG="$PLUGIN_DIR/images/build-review-chain.svg"
C="$PLUGIN_DIR/.claude/CLAUDE.md"
rc=0
for p in 'lane' '--inline' '--delegate' 'full-suite' 'resume'; do
    grep -qF -- "$p" "$R" || { echo "    README missing: $p"; rc=1; }
done
for p in 'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' 'complete code' 'on a task diff'; do
    grep -qF -- "$p" "$R" && { echo "    README still has: $p"; rc=1; }
done
grep -qF 'each lane' "$SVG" || { echo "    build diagram title must say 'each lane'"; rc=1; }
grep -qF '/ task' "$SVG"    && { echo "    build diagram still counts spawns per task"; rc=1; }
grep -qF '| **Lane** |' "$C" || { echo "    CLAUDE.md Domain Terms missing a Lane row"; rc=1; }
exit $rc
