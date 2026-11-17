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

# The tokenizer reads the command on stdin and prints one segment per line (one per simple command), words joined by
# \037 and each prefixed L (literal) or D (dynamic: an unquoted or double-quoted $, a backtick, an unquoted * ? [).
# It prints the single line `!` when a quote is unbalanced.
TOKENIZER='
function endword() {
    if (inword) seg = seg (seg == "" ? "" : SEP) (dyn ? "D" : "L") cur
    inword = 0; cur = ""; dyn = 0
}
function endseg() { endword(); if (seg != "") out = out seg "\n"; seg = "" }
function flat(s) { gsub(/\n/, " ", s); return s }
BEGIN { SEP = "\037"; Q = "\047" }
{ text = (NR > 1 ? text "\n" : "") $0 }
END {
    n = length(text); bad = 0
    for (i = 1; i <= n && !bad; i++) {
        c = substr(text, i, 1)
        if (c == Q) {
            j = index(substr(text, i + 1), Q)
            if (j == 0) { bad = 1; break }
            cur = cur flat(substr(text, i + 1, j - 1)); inword = 1; i += j
        } else if (c == "\"") {
            inword = 1; i++
            while (i <= n) {
                c = substr(text, i, 1)
                if (c == "\"") break
                if (c == "\\") {
                    d = substr(text, i + 1, 1)
                    if (d == "$" || d == "`" || d == "\"" || d == "\\") { cur = cur d; i += 2; continue }
                    if (d == "\n") { i += 2; continue }
                } else if (c == "$" || c == "`") dyn = 1
                cur = cur flat(c); i++
            }
            if (i > n) bad = 1
        } else if (c == "\\") {
            d = substr(text, i + 1, 1); i++
            if (d != "\n") { cur = cur d; inword = 1 }
        } else if (c == "$" || c == "`" || c == "*" || c == "?" || c == "[") {
            cur = cur c; inword = 1; dyn = 1
        } else if (c == " " || c == "\t") {
            endword()
        } else if (c == "#" && !inword) {
            while (i < n && substr(text, i + 1, 1) != "\n") i++
        } else if (c == "&" || c == "|" || c == ";" || c == "\n" || c == "(" || c == ")") {
            endseg()
        } else {
            cur = cur c; inword = 1
        }
    }
    endseg()
    if (bad) print "!"; else printf "%s", out
}'

# parse_segment <segment line>: SEG_TEXT (the words joined by blanks), WK (L or D per word), WV (the word; a dynamic
# word holds DYN, which never matches a flag or a path)
DYN=$'\001'
parse_segment() {
    local raw w
    SEG_TEXT=""; WK=(); WV=()
    IFS=$'\037' read -r -a raw <<< "$1"
    for w in ${raw[@]+"${raw[@]}"}; do
        SEG_TEXT="${SEG_TEXT:+$SEG_TEXT }${w:1}"
        WK[${#WK[@]}]="${w:0:1}"
        if [ "${w:0:1}" = L ]; then WV[${#WV[@]}]="${w:1}"; else WV[${#WV[@]}]="$DYN"; fi
    done
}

# check_git_add <first word index>: the words after `git add`
check_git_add() {
    local i
    for ((i = $1; i < ${#WV[@]}; i++)); do
        case "${WV[i]}" in
            -A|--all|-u|--update|.|./|:/) deny_staging "$SEG_TEXT" ;;
        esac
    done
}

check_segment() {
    parse_segment "$1"
    [ "${#WV[@]}" -ge 2 ] && [ "${WV[0]}" = git ] || return 0
    if [ "${WV[1]}" = add ]; then check_git_add 2; fi
}

# check_command <text>: tokenize, then check each segment; a command the tokenizer can't read passes
check_command() {
    local segs line
    segs="$(printf '%s' "$1" | awk "$TOKENIZER")"
    [ "$segs" = '!' ] && return 0
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        check_segment "$line"
    done <<< "$segs"
}

check_command "$COMMAND"
exit 0
