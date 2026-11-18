#!/usr/bin/env bash
# ABOUTME: Asserts brainstorm runs a builder check on a project's design doc before committing it.
# ABOUTME: 3.3.0 quality pack item 8: a researcher reads the doc as its builder; only plan-changing questions reach the user.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/brainstorm/SKILL.md"
assert_file "$S" || exit 1
for p in 'turbocharge:researcher' 'effort: medium' 'wrong guess would change the plan' 'nothing important left' \
         'completion notification' 'Ruled while designing' 'one message' 'use `@AGENTS.md` in its place' 'not registered'; do
    grep -qF "$p" "$S" || { echo "    brainstorm missing: $p"; exit 1; }
done
# The check runs between writing the doc and committing it.
w=$(grep -nF 'Write design to' "$S" | head -1 | cut -d: -f1)
r=$(grep -nF 'turbocharge:researcher' "$S" | head -1 | cut -d: -f1)
c=$(grep -nF 'Commit the design document' "$S" | head -1 | cut -d: -f1)
[ -n "$w" ] && [ -n "$r" ] && [ -n "$c" ] && [ "$w" -lt "$r" ] && [ "$r" -lt "$c" ] \
    || { echo "    builder check must sit between writing the design (line $w) and committing it (line $c); researcher at $r"; exit 1; }
# 3.8.0: neutral marker and no word count, in the skill, the README alt text and the image.
for f in "$S" "$PLUGIN_DIR/README.md" "$PLUGIN_DIR/images/brainstorm-session.svg"; do
    for p in "Ruled in brainstorm" "200-300" "200–300" "200 to 300"; do
        ! grep -qF -- "$p" "$f" || { echo "    $f still has: $p"; exit 1; }
    done
done
# 3.8.0 Task 10: the commit check, the recorded commit, and the rule with its reason.
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
CTX=$(sec "$S" "### 1. Understand Context" "### ")
for p in 'git status -sb' 'git merge-base --is-ancestor HEAD <base>' 'git show <base>:<path>' 'skip the check' 'Outside a git repository' 'a worktree already on the base'; do
    printf "%s\n" "$CTX" | grep -qF -- "$p" || { echo "    brainstorm step 1 missing: $p"; exit 1; }
done
for p in 'Code read at:' 'commit the doc names'; do
    grep -qF -- "$p" "$S" || { echo "    brainstorm missing: $p"; exit 1; }
done
! grep -qF 'NO IMPLEMENTATION WITHOUT' "$S" || { echo "    brainstorm still has the capital-letter fence"; exit 1; }
exit 0
