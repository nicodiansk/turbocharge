#!/usr/bin/env bash
# ABOUTME: Asserts build's Step 1 parses flags before reading the plan, finds the plan when no path is given,
# ABOUTME: and refuses a plan the planner left unfinished (line 1 `<!-- plan: in progress -->`), offering plan to resume it.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$S" || exit 1
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
STEP1=$(sec "$S" '## Step 1' '## Step 2')
rc=0
for p in 'plan: in progress' '`/turbocharge:plan <path>`' 'resumes it' 'What remains is the plan path' 'With no path' \
    '`Next:` line' 'docs/plans/*.md'; do
    printf '%s\n' "$STEP1" | grep -qF -- "$p" || { echo "    build Step 1 missing: $p"; rc=1; }
done
# Flags first: $ARGUMENTS also holds them, so the path is what is left after parsing.
FLAGS=$(printf '%s\n' "$STEP1" | grep -nF 'Parse flags from $ARGUMENTS' | head -1 | cut -d: -f1)
READ=$(printf '%s\n' "$STEP1" | grep -nF 'Read the plan file' | head -1 | cut -d: -f1)
if [ -z "$FLAGS" ] || [ -z "$READ" ] || [ "$FLAGS" -ge "$READ" ]; then
    echo "    build Step 1 must parse flags before it reads the plan file"; rc=1
fi
printf '%s\n' "$STEP1" | grep -qF 'Read the plan file at $ARGUMENTS' && { echo "    build Step 1 still reads the plan from raw \$ARGUMENTS"; rc=1; }
exit $rc
