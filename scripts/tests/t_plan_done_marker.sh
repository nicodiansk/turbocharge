#!/usr/bin/env bash
# ABOUTME: Asserts build finds a plan that moved to archive/, asks before rerunning a plan marked done, marks a finished plan done
# ABOUTME: in Step 7 (committing only where git tracks it), and that review and ship look in archive/ too.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$S" || exit 1
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
rc=0
need() { # need <section text> <label> <phrase>...
    local text="$1" label="$2"; shift 2
    local p
    for p in "$@"; do
        printf '%s\n' "$text" | grep -qF -- "$p" || { echo "    $label missing: $p"; rc=1; }
    done
}
STEP1=$(sec "$S" '## Step 1' '## Step 2')
need "$STEP1" 'build Step 1' '<!-- plan: done YYYY-MM-DD -->' 'ask before running it again' 'before the first lane starts' \
    'docs/plans/archive/' 'plan found in archive/' '`\r` stripped' 'An archived plan gets the same check'
FLAGS=$(printf '%s\n' "$STEP1" | grep -nF 'Parse flags from $ARGUMENTS' | head -1 | cut -d: -f1)
LOOK=$(printf '%s\n' "$STEP1" | grep -nF 'plan found in archive/' | head -1 | cut -d: -f1)
if [ -z "$FLAGS" ] || [ -z "$LOOK" ] || [ "$LOOK" -le "$FLAGS" ]; then
    echo "    build Step 1: the archive lookup must come after Parse flags from \$ARGUMENTS"; rc=1
fi
exit $rc
