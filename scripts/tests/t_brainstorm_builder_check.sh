#!/usr/bin/env bash
# ABOUTME: Asserts brainstorm runs a builder check on a project's design doc before committing it.
# ABOUTME: 3.3.0 quality pack item 8: a researcher reads the doc as its builder; only plan-changing questions reach the user.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/brainstorm/SKILL.md"
assert_file "$S" || exit 1
for p in 'turbocharge:researcher' 'effort: medium' 'wrong guess would change the plan' 'nothing important left' \
         'completion notification' 'Ruled in brainstorm' 'one message' 'use `@AGENTS.md` in its place' 'not registered'; do
    grep -qF "$p" "$S" || { echo "    brainstorm missing: $p"; exit 1; }
done
# The check runs between writing the doc and committing it.
w=$(grep -nF 'Write design to' "$S" | head -1 | cut -d: -f1)
r=$(grep -nF 'turbocharge:researcher' "$S" | head -1 | cut -d: -f1)
c=$(grep -nF 'Commit the design document' "$S" | head -1 | cut -d: -f1)
[ -n "$w" ] && [ -n "$r" ] && [ -n "$c" ] && [ "$w" -lt "$r" ] && [ "$r" -lt "$c" ] \
    || { echo "    builder check must sit between writing the design (line $w) and committing it (line $c); researcher at $r"; exit 1; }
exit 0
