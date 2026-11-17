#!/usr/bin/env bash
# ABOUTME: Asserts build's fix rounds (5c) route a full-gate failure in a file no lane owns: to the lane whose change
# ABOUTME: it points to, which may edit that file for the fix (listed in its Rulings), else the main session or the user.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$S" || exit 1
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
FIX=$(sec "$S" '### 5c. Fix Rounds' '## Step 6')
rc=0
for p in '**A file no lane owns**' 'cross-lane regression' 'whose change the failure points to' 'Every lane has finished' \
    'may edit the file for this fix' 'Rulings' 'main session' 'ask the user'; do
    printf '%s\n' "$FIX" | grep -qF -- "$p" || { echo "    build 5c missing: $p"; rc=1; }
done
exit $rc
