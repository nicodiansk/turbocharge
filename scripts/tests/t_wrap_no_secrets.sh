#!/usr/bin/env bash
# ABOUTME: Drives skills/wrap/write-snapshot.sh: a snapshot field that looks like a key blocks the write, a clean draft is written.
# ABOUTME: Fake keys are built at run time by concatenation; the clean draft runs through /bin/bash (3.2 on macOS) with no --allow.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/wrap/write-snapshot.sh"
assert_file "$S" || exit 1
rc=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null 2>/dev/null || true
R="$TMP/repo"
git init -q "$R"
git -C "$R" config user.name Fixture
git -C "$R" config user.email f@example.com
git -C "$R" commit -q --allow-empty -m init
HEAD_SHA="$(git -C "$R" rev-parse HEAD)"

AWSKEY="AKIA""IOSFODNN7EXAMPLE"
SKKEY="sk-""abcDEF1234567890xyzQWER"
B64="q8Zk3Lm0Vb7Tn2Xc9Rw5Yd1Hf6Jg4Sa8Pe3UoK2iMlA"
HEX64="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

# run NAME DRAFT [extra args...]: runs in the fixture, sets OUT (stderr), CODE, target at $R/out/NAME.json
run() {
    local name="$1" draft="$2" sh="${SHELL_BIN:-bash}"; shift 2
    rm -f "$R/out/$name.json"
    OUT="$(cd "$R" && printf '%s' "$draft" | "$sh" "$S" --target "$R/out/$name.json" "$@" 2>&1 >/dev/null)"; CODE=$?
}
expect_block() { # name, draft, field, rule, key-text
    run "$1" "$2"
    [ "$CODE" = 1 ] || { echo "    $1: exit $CODE, wanted 1"; rc=1; }
    [ ! -e "$R/out/$1.json" ] || { echo "    $1: target written"; rc=1; }
    printf '%s' "$OUT" | grep -qF "BLOCKED $3" || { echo "    $1: stderr lacks BLOCKED $3: $OUT"; rc=1; }
    printf '%s' "$OUT" | grep -qF "looks like $4" || { echo "    $1: stderr lacks looks like $4: $OUT"; rc=1; }
    printf '%s' "$OUT" | grep -qF -- "$5" && { echo "    $1: stderr leaks the value"; rc=1; }
    return 0
}
expect_block aws "{\"blockers\": [\"deploy key $AWSKEY\"]}" blockers 'AWS key' "$AWSKEY"
expect_block sk "{\"decisions\": [\"use $SKKEY\"]}" decisions 'sk- key' "$SKKEY"
expect_block pem '{"next_steps": ["-----BEGIN PRIVATE KEY-----"]}' next_steps 'PEM block' 'PRIVATE KEY'
expect_block b64 "{\"current_task\": \"$B64\"}" current_task 'long base64' "$B64"
expect_block hex "{\"open_files\": [\"$HEX64\"]}" open_files 'long hex' "$HEX64"
expect_block gh "{\"branch\": \"ghp_$(printf 'a%.0s' $(seq 1 24))\"}" branch 'GitHub token' ghp_aaaa
expect_block slack "{\"branch\": \"xoxb-1234567890-abcdef\"}" branch 'Slack token' xoxb-1234567890

run allow "{\"blockers\": [\"deploy key $AWSKEY\"]}" --allow blockers
{ [ "$CODE" = 0 ] && [ -f "$R/out/allow.json" ]; } || { echo "    --allow blockers: exit $CODE, written? no"; rc=1; }

CLEAN="{
  \"branch\": \"$HEAD_SHA\",
  \"decisions\": [\"STRIPE_KEY in .env, sha256:3f2a9c1b7d4e\"],
  \"open_files\": [\"src/components/dashboard/widgets/RevenueChartContainer2\"]
}
"
SHELL_BIN=bash run clean "$CLEAN"
[ "$CODE" = 0 ] || { echo "    clean draft: exit $CODE: $OUT"; rc=1; }
printf '%s' "$CLEAN" | cmp -s - "$R/out/clean.json" || { echo "    clean draft: target differs from the draft"; rc=1; }
if [ -x /bin/bash ]; then
    SHELL_BIN=/bin/bash run clean32 "$CLEAN"
    [ "$CODE" = 0 ] || { echo "    clean draft via /bin/bash: exit $CODE: $OUT"; rc=1; }
    printf '%s' "$OUT" | grep -q 'unbound variable' && { echo "    /bin/bash: unbound variable"; rc=1; }
    [ -f "$R/out/clean32.json" ] || { echo "    /bin/bash: target absent"; rc=1; }
fi

run bad 'not json'
{ [ "$CODE" = 2 ] && [ ! -e "$R/out/bad.json" ]; } || { echo "    not json: exit $CODE, wanted 2 and nothing written"; rc=1; }
printf '%s' "$OUT" | grep -qF "the draft isn't JSON" || { echo "    not json: message missing: $OUT"; rc=1; }
run empty ''
[ "$CODE" = 2 ] || { echo "    empty draft: exit $CODE, wanted 2"; rc=1; }
exit $rc
