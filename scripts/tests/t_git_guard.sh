#!/usr/bin/env bash
# ABOUTME: Behavioral test for hooks/git-guard.sh: feeds PreToolUse hook JSON on stdin, checks the deny JSON or silence.
# ABOUTME: Fixture folders (path with a space) and stub `uname` scripts make every platform branch run on macOS and Linux CI.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
GUARD="$PLUGIN_DIR/hooks/git-guard.sh"
if ! command -v jq >/dev/null 2>&1; then echo "    jq not installed, skipping"; exit 0; fi
assert_file "$GUARD" || exit 1

ROOT="$(mktemp -d)"; trap 'rm -rf "$ROOT"' EXIT
WORK="$ROOT/work dir"; mkdir -p "$WORK"
FAILS=0
CHECK_CWD="$WORK"; CHECK_TOOL="Bash"; PREPATH=""

# check [VAR=value ...] <allow|block> <command> [reason substring]
check() {
    local envs=()
    while [ $# -gt 0 ] && [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do envs+=("$1"); shift; done
    local mode="$1" cmd="$2" want="${3:-}" out rc err
    out="$(jq -nc --arg c "$cmd" --arg d "$CHECK_CWD" --arg t "$CHECK_TOOL" \
        '{hook_event_name:"PreToolUse",tool_name:$t,tool_input:{command:$c},cwd:$d}' \
        | env ${envs[@]+"${envs[@]}"} PATH="${PREPATH:+$PREPATH:}$PATH" bash "$GUARD" 2>"$ROOT/err")"; rc=$?
    err="$(cat "$ROOT/err")"
    if [ "$rc" != 0 ]; then bad "$cmd" "exit $rc"; return; fi
    if [ -n "$err" ]; then bad "$cmd" "stderr: $err"; return; fi
    if [ "$mode" = allow ]; then
        [ -z "$out" ] || bad "$cmd" "expected allow, got: $out"
    else
        [ "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)" = deny ] \
            || { bad "$cmd" "expected deny, got: $out"; return; }
        printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "PreToolUse"' >/dev/null 2>&1 \
            || { bad "$cmd" "deny lacks hookEventName PreToolUse"; return; }
        [ -z "$want" ] || printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -qF -- "$want" \
            || bad "$cmd" "reason lacks '$want': $out"
    fi
}
bad() { echo "    FAIL: $1 -- $2"; FAILS=$((FAILS+1)); }
# check_raw <allow> <stdin text>
check_raw() {
    local out rc
    out="$(printf '%s' "$1" | bash "$GUARD" 2>"$ROOT/err")"; rc=$?
    [ "$rc" = 0 ] && [ -z "$out" ] && [ ! -s "$ROOT/err" ] || bad "raw: $1" "rc=$rc out=$out err=$(cat "$ROOT/err")"
}

# --- Task 1: bulk git add on a plain command
check block 'git add -A' 'Stage explicit paths after `git status`'
for c in 'git add .' 'git add ./' 'git add :/' 'git add -u' 'git add --update' 'git add --all'; do check block "$c"; done
check allow 'git add .gitignore'
check allow 'git add ./src'
CHECK_TOOL=Read check allow 'git add -A'
check_raw 'not json'
check allow ''
check TURBOCHARGE_GIT_GUARD=off allow 'git add -A'
check TURBOCHARGE_GIT_GUARD=OFF allow 'git add -A'

[ "$FAILS" = 0 ] || { echo "    $FAILS check(s) failed"; exit 1; }
exit 0
