#!/usr/bin/env bash
# ABOUTME: Asserts build runs lanes and lane reviews inline when its agents can't be dispatched (surfaces without agents).
# ABOUTME: Also asserts Step 6 rules on every "Declined to judge" line: a finding, or carried to Step 7 as set aside.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$S" || exit 1
grep -qF 'not registered' "$S"                             || { echo "    build must handle an unregistered builder type"; exit 1; }
grep -qF 'agents unavailable — running lanes inline' "$S" || { echo "    build must announce the inline fallback"; exit 1; }
STEP6=$(awk '{ sub(/\r$/, "") } /^## Step 6/ { s=1 } /^## Step 7/ { s=0 } s' "$S")
for p in 'Declined to judge' 'set aside' 'not registered'; do
    printf '%s\n' "$STEP6" | grep -qF "$p" || { echo "    build Step 6 missing: $p"; exit 1; }
done
exit 0
