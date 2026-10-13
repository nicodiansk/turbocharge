#!/usr/bin/env bash
# ABOUTME: Asserts plans carry a Review Focus section: up to 5 implied failure modes, each pinned by a test.
# ABOUTME: Guards the plan skill template and the planner's 5-point self-review (3.3.0 quality pack item 1).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/plan/SKILL.md"
P="$PLUGIN_DIR/agents/planner.md"
assert_file "$S" || exit 1
assert_file "$P" || exit 1
for f in "$S" "$P"; do
    for p in '## Review Focus' '(pinned: Task N)' 'up to 5'; do
        grep -qF "$p" "$f" || { echo "    $(basename "$f") missing: $p"; exit 1; }
    done
done
grep -qF '5. **Review Focus**' "$P" || { echo "    planner.md self-review lacks point 5. **Review Focus**"; exit 1; }
grep -qF 'all five' "$P"            || { echo "    planner.md must gate on all five self-review points"; exit 1; }
grep -qF '4-point' "$P"             && { echo "    planner.md still says 4-point self-review"; exit 1; }
grep -qF 'all four' "$P"            && { echo "    planner.md still says all four"; exit 1; }
exit 0
