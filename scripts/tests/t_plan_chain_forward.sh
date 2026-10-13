#!/usr/bin/env bash
# ABOUTME: Asserts plan chains forward to build, honors a path the user names, and never asks (it runs forked).
# ABOUTME: 3.3.0 quality pack item 4: running build is the approval; the planner records assumptions instead.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/plan/SKILL.md"
P="$PLUGIN_DIR/agents/planner.md"
assert_file "$S" || exit 1
assert_file "$P" || exit 1
for f in "$S" "$P"; do
    grep -qF 'then `/turbocharge:build <path>`' "$f" || { echo "    $(basename "$f") does not chain forward to build"; exit 1; }
    grep -qF 'request names a path' "$f"            || { echo "    $(basename "$f") ignores a path the user names"; exit 1; }
    # A planner that stops on a design question has no plan path, so the Next line can't apply.
    grep -qF 'stopped on a question' "$f"           || { echo "    $(basename "$f") gives no ending for a stop on a question"; exit 1; }
done
grep -qF 'cannot ask' "$P"                       || { echo "    planner.md must say the forked planner cannot ask"; exit 1; }
grep -qF 'get confirmation before planning' "$P" && { echo "    planner.md still asks for confirmation"; exit 1; }
exit 0
