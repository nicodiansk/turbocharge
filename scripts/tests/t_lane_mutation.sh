#!/usr/bin/env bash
# ABOUTME: Asserts the builder runs one mutation at the lane's end and build picks that mutation per builder lane.
# ABOUTME: Tests with teeth, tasks 3-4: builder.md Lane-End Mutation and Report Format; build Step 3 spawn list and Step 4.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
B="$PLUGIN_DIR/agents/builder.md"
S="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$B" || exit 1
assert_file "$S" || exit 1
rc=0
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
MUT=$(sec "$B" '## Lane-End Mutation' '## ')
REPORT=$(sec "$B" '## Report Format' '## ')
PR=$(grep -n '^## Your Process' "$B" | cut -d: -f1)
LM=$(grep -n '^## Lane-End Mutation' "$B" | cut -d: -f1)
LR=$(grep -n '^## Lane Rules' "$B" | cut -d: -f1)
if [ -z "$PR" ] || [ -z "$LM" ] || [ -z "$LR" ] || ! [ "$PR" -lt "$LM" ] || ! [ "$LM" -lt "$LR" ]; then
    echo "    builder.md needs '## Lane-End Mutation' between '## Your Process' and '## Lane Rules'"; rc=1
fi
for p in 'Mutation: lane' 'Mutation: no' 'with no `Mutation:` line means `no`' "after the last task's commit" 'a condition, a boundary, a returned value' 'never a comment, a log line or an import' 'git checkout -- <file>' 'in every case' 'Lane Rules' 'git status --porcelain -- <file>' '`test: …`' 'DONE_WITH_CONCERNS' 'Expect RED on an assertion, not an error' 'proves nothing'; do
    printf '%s\n' "$MUT" | grep -qF -- "$p" || { echo "    builder.md Lane-End Mutation missing: $p"; rc=1; }
done
printf '%s\n' "$REPORT" | grep -qF 'Mutation: <file:line> → <test> RED | strengthened: <how> | no' || { echo "    builder.md Report Format missing the Mutation line"; rc=1; }

STEP3=$(sec "$S" '## Step 3' '## ')
STEP4=$(sec "$S" '## Step 4' '## ')
for p in 'Mutation: Task N — <Review Focus line>' '(pinned: Task N)' 'most likely input first' '`Mutation: lane` with `--reviewed`' 'Mutation: no' 'The builder reads only this line'; do
    printf '%s\n' "$STEP3" | grep -qF -- "$p" || { echo "    build Step 3 missing: $p"; rc=1; }
done
printf '%s\n' "$STEP4" | grep -qF 'Inline lanes run no mutation' || { echo "    build Step 4 missing: Inline lanes run no mutation"; rc=1; }
exit $rc
