#!/usr/bin/env bash
# ABOUTME: Asserts build routes each builder lane's model from the plan's Model column: reads it in Step 1,
# ABOUTME: routes it as a hint in Step 2, spawns Opus lanes in Step 3, handles stuck lanes in Step 5, counts them in Step 7.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$S" || exit 1
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
rc=0
need() { # need <section text> <label> <phrase>...
    local text="$1" label="$2"; shift 2
    local p
    for p in "$@"; do
        printf '%s\n' "$text" | grep -qF -- "$p" || { echo "    build $label missing: $p"; rc=1; }
    done
}
lack() { # lack <section text> <label> <phrase>
    printf '%s\n' "$1" | grep -qF -- "$3" && { echo "    build $2 still has: $3"; rc=1; }
}
STEP1=$(sec "$S" '## Step 1' '## Step 2')
need "$STEP1" 'Step 1' '| Effort | Model |' 'six-column table' '`opus · <reason>`' '`concurrency`' '`security`' \
    '`irreversible`' '`edge-cases`' 'plan concern' 'unless the user says otherwise' "session's model" \
    'one sequential lane, on `sonnet`'
STEP2=$(sec "$S" '## Step 2' '## Step 3')
need "$STEP2" 'Step 2' 'builder (high · opus · security)' 'reason in the routing announcement' 'loses its model' \
    'ignores the Model column' 'lane that was inline (`—`) gets `sonnet`' 'promotes to a builder' \
    "may lower a lane's model, never raise it"
lack "$STEP2" 'Step 2' 'One Sonnet builder'
lack "$STEP2" 'Step 2' 'raise or lower'
need "$STEP2" 'Step 2' 'Opus lanes count toward the cap'
STEP3=$(sec "$S" '## Step 3' '## Step 4')
need "$STEP3" 'Step 3' '`model: opus` on the Agent call' 'passes no `model`' 'opus unavailable — lane <name> on sonnet' \
    'for the rest of the run' 'older Opus'
STEP5=$(sec "$S" '## Step 5' '## Step 6')
need "$STEP5" 'Step 5' 'started on Opus' 'no retry' 'Opus is unavailable' 'whatever its model' \
    'model: opus' "keeps the lane's \`LANE_SHA\`" 'the same `Mutation:` line' "the retry's own spawn fails"
lack "$STEP5" 'Step 5' 'raised in Step 2'
grep -qF 'on Opus lanes too' "$PLUGIN_DIR/skills/build/references/reviewed-mode.md" || { echo "    reviewed-mode.md missing: on Opus lanes too"; rc=1; }
STEP7=$(sec "$S" '## Step 7' '## Red Flags')
need "$STEP7" 'Step 7' 'builder B, opus O)' 'opus 0'
lack "$STEP7" 'Step 7' 'raised'
FLAGS=$(sec "$S" '## Red Flags' '### Rationalizations')
need "$FLAGS" 'Red Flags' "the plan doesn't mark" 'already ran on Opus' 'never raise it' 'stuck Sonnet lane'
exit $rc
