#!/usr/bin/env bash
# ABOUTME: Asserts plans are lean: decisions, paths, test assertions and Verify, grouped into file-disjoint lanes.
# ABOUTME: The plan skill and planner must not ask for complete code (3.0.0: 69 KB plan, 19-min planner, code typed twice).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/plan/SKILL.md"
assert_file "$S" || exit 1
grep -qF '| Lane | Owns files | Tasks | After | Executor | Effort |' "$S" || { echo "    plan skill missing the Lanes table header"; exit 1; }
for p in '**Decision:**' '**Test:**' '**Verify:**' 'Decisions, not code'; do
    grep -qF "$p" "$S" || { echo "    plan skill missing: $p"; exit 1; }
done
grep -qi "complete code" "$S"                       && { echo "    plan skill still asks for complete code"; exit 1; }
grep -qF "[complete implementation code]" "$S"      && { echo "    plan skill still has the complete-code task template"; exit 1; }
exit 0
