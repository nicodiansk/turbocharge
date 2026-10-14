#!/usr/bin/env bash
# ABOUTME: Asserts the planner writes its plan file early and a rerun resumes a partial one (3.4.0, dogfood D9).
# ABOUTME: A forked planner that wrote once, at the end, lost everything when the Mac slept mid-run.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/plan/SKILL.md"
P="$PLUGIN_DIR/agents/planner.md"
assert_file "$S" || exit 1
assert_file "$P" || exit 1
for f in "$S" "$P"; do
    grep -qF '<!-- plan: in progress -->' "$f" || { echo "    $(basename "$f") has no in-progress marker for an early-written plan"; exit 1; }
    grep -qF '**Commit:**' "$f"                || { echo "    $(basename "$f") doesn't say which tasks a resume keeps (those with their **Commit:** line)"; exit 1; }
done
grep -qF 'resumed from a partial plan' "$P"                || { echo "    planner.md doesn't report a resume"; exit 1; }
grep -qF -- '-2.md' "$P"                                   || { echo "    planner.md may overwrite a finished plan (no -2.md suffix rule)"; exit 1; }
grep -qF 'before you remove the in-progress marker' "$P"   || { echo "    planner.md's self-review isn't tied to removing the marker"; exit 1; }
grep -qF 'BEFORE you Write it to' "$P" && { echo "    planner.md still writes the plan only after the self-review"; exit 1; }
exit 0
