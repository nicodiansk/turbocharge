#!/usr/bin/env bash
# ABOUTME: Asserts build's Reviewed Mode body lives in references/reviewed-mode.md (loaded only with --reviewed), Step 6 keeps
# ABOUTME: a short stub that points to it, Step 1 reads it before any lane starts, and the description names the plan-file trigger.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/build/SKILL.md"
R="$PLUGIN_DIR/skills/build/references/reviewed-mode.md"
assert_file "$S" || exit 1
assert_file "$R" || exit 1
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
rc=0
STEP6=$(sec "$S" '## Step 6' '## Step 7')
for p in '`references/reviewed-mode.md`' "in this skill's directory" 'complete only after Spec ✅'; do
    printf '%s\n' "$STEP6" | grep -qF -- "$p" || { echo "    build Step 6 stub missing: $p"; rc=1; }
done
W=$(printf '%s\n' "$STEP6" | wc -w | tr -d ' ')
[ "$W" -le 120 ] || { echo "    build Step 6 should be a short stub (<=120 words), has $W"; rc=1; }
printf '%s\n' "$STEP6" | grep -qF '**Disposition:**' && { echo "    build Step 6 still holds the disposition (move it to the reference)"; rc=1; }
sec "$S" '## Step 1' '## Step 2' | grep -qF '`references/reviewed-mode.md`' \
    || { echo "    build Step 1 must read references/reviewed-mode.md when --reviewed is set"; rc=1; }
for p in '**Disposition:**' 'Max 2 cycles' 'Declined to judge' 'task-reviewer'; do
    grep -qF -- "$p" "$R" || { echo "    reviewed-mode.md missing: $p"; rc=1; }
done
D=$(frontmatter "$S" | grep '^description:')
for p in 'written implementation plan' 'build the plan' 'plan first'; do
    printf '%s\n' "$D" | grep -qF -- "$p" || { echo "    build description missing: $p"; rc=1; }
done
printf '%s\n' "$D" | grep -qE 'Sonnet|two verdicts' && { echo "    build description still names internals (Sonnet, two verdicts)"; rc=1; }
exit $rc
