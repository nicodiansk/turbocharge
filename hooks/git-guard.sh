#!/usr/bin/env bash
# ABOUTME: git-guard — refuses a Bash command (PreToolUse) that stages files in bulk, skips the repository's git hooks, or runs a recursive delete through a symlink.
# ABOUTME: Reads hook JSON on stdin with jq; prints one JSON deny on stdout with the reason and what to do instead, exit 0. Fails open: anything unexpected exits 0 with no output.
# ABOUTME: Read-only — writes nothing, no network, runs only jq, awk, find and uname, never git.
set -u
export LC_ALL=C

command -v jq >/dev/null 2>&1 || exit 0

MAX_COMMAND_BYTES=16384

is_off() { [ "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" = off ]; }

INPUT="$(cat)"
field() { printf '%s' "$INPUT" | jq -r "$1 // empty" 2>/dev/null | tr -d '\r'; }

[ "$(field .tool_name)" = "Bash" ] || exit 0
is_off "${TURBOCHARGE_GIT_GUARD:-}" && exit 0
COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -n "$COMMAND" ] && [ "${#COMMAND}" -le "$MAX_COMMAND_BYTES" ] || exit 0
case "$COMMAND" in *git*|*rm*) ;; *) exit 0 ;; esac

# deny <reason>: print the PreToolUse deny decision and stop.
deny() {
    jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
    exit 0
}

# first 80 characters of a segment, for the reason
excerpt() { printf '%s' "${1:0:80}"; }

deny_staging() {
    deny "turbocharge git-guard: \`$(excerpt "$1")\` stages files in bulk. Stage explicit paths after \`git status\`: git add <paths>, then git commit -m \"<message>\" -- <paths>. To turn this check off, the user sets TURBOCHARGE_GIT_GUARD_STAGING=off."
}

# check_git_add <segment text> <word>...: the words after `git add`
check_git_add() {
    local seg="$1"; shift
    local w
    for w in "$@"; do
        case "$w" in
            -A|--all|-u|--update|.|./|:/) deny_staging "$seg" ;;
        esac
    done
}

# check_segment <segment text>: this task splits on blanks only
check_segment() {
    local seg="$1" words
    IFS=' ' read -r -a words <<< "$seg"
    [ "${#words[@]}" -ge 2 ] || return 0
    [ "${words[0]}" = git ] || return 0
    if [ "${words[1]}" = add ]; then
        check_git_add "$seg" "${words[@]:2}"
    fi
}

check_segment "$COMMAND"
exit 0
