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
    '`irreversible`' '`edge-cases`' 'plan concern' 'unless the user says otherwise' "session's model"
STEP2=$(sec "$S" '## Step 2' '## Step 3')
need "$STEP2" 'Step 2' 'builder (high · opus · security)' 'reason in the routing announcement' 'loses its model' \
    'ignores the Model column' 'lane that was inline (`—`) gets `sonnet`' 'promotes to a builder'
lack "$STEP2" 'Step 2' 'One Sonnet builder'
exit $rc
