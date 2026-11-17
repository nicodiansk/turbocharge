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
# It scans $(...) and backticks recursively (emitting their segments, to depth 4) and skips heredoc bodies.
# It prints the single line `!` when a quote, $( or backtick is unbalanced.
TOKENIZER='
function endword(d) {
    if (INW[d]) SEG[d] = SEG[d] (SEG[d] == "" ? "" : SEP) (DYN[d] ? "D" : "L") CUR[d]
    INW[d] = 0; CUR[d] = ""; DYN[d] = 0
}
function endseg(d) {
    endword(d)
    if (SEG[d] != "" && d <= MAXD) out = out SEG[d] "\n"
    SEG[d] = ""
}
function flat(s) { gsub(/\n/, " ", s); return s }
# skipbodies(i): i is a newline; consume the body of every pending heredoc, return the index to resume from
function skipbodies(i,    k, pos, rest, e, len, line) {
    for (k = 1; k <= NH; k++) {
        pos = i + 1
        while (1) {
            if (pos > n) { i = n; break }
            rest = substr(text, pos); e = index(rest, "\n")
            len = e ? e - 1 : length(rest)
            line = substr(rest, 1, len)
            if (HT[k]) sub(/^\t+/, "", line)
            if (line == HD[k]) { i = (pos + len > n) ? n : pos + len; break }
            pos += len + 1
        }
    }
    NH = 0
    return i
}
# readdelim(i): i is just past << (or <<-); sets DELIM, returns the index of the last character it consumed
function readdelim(i,    e, j) {
    DELIM = ""
    while (substr(text, i, 1) == " " || substr(text, i, 1) == "\t") i++
    while (i <= n) {
        e = substr(text, i, 1)
        if (e == Q || e == "\"") {
            j = index(substr(text, i + 1), e)
            if (j == 0) { bad = 1; return n }
            DELIM = DELIM substr(text, i + 1, j - 1); i += j + 1
        } else if (e == "\\") { DELIM = DELIM substr(text, i + 1, 1); i += 2 }
        else if (e == " " || e == "\t" || e == "\n" || e == ";" || e == "&" || e == "|" || e == "(" || e == ")" || e == "<" || e == ">") break
        else { DELIM = DELIM e; i++ }
    }
    return i - 1
}
# dquote(i, d): i is just past an opening ", returns the index of the closing one
function dquote(i, d,    c, e) {
    while (i <= n) {
        c = substr(text, i, 1)
        if (c == "\"") return i
        if (c == "\\") {
            e = substr(text, i + 1, 1)
            if (e == "$" || e == "`" || e == "\"" || e == "\\") { CUR[d] = CUR[d] e; i += 2; continue }
            if (e == "\n") { i += 2; continue }
        } else if (c == "$" && substr(text, i + 1, 1) == "(") {
            i = scan(i + 2, ")", d + 1); DYN[d] = 1; CUR[d] = CUR[d] "$()"; i++; continue
        } else if (c == "`") {
            i = scan(i + 1, "`", d + 1); DYN[d] = 1; CUR[d] = CUR[d] "`"; i++; continue
        } else if (c == "$") DYN[d] = 1
        CUR[d] = CUR[d] flat(c); i++
    }
    bad = 1
    return n + 1
}
# scan(start, closer, d): emit the segments from start up to closer (")", a backtick, or "" for the end of the text) and
# return the index of the closer
function scan(start, closer, d,    i, c, e, j, par, tab) {
    SEG[d] = ""; CUR[d] = ""; INW[d] = 0; DYN[d] = 0; par = 0
    for (i = start; i <= n; i++) {
        if (bad) return n + 1
        c = substr(text, i, 1)
        if (c == Q) {
            j = index(substr(text, i + 1), Q)
            if (j == 0) { bad = 1; return n + 1 }
            CUR[d] = CUR[d] flat(substr(text, i + 1, j - 1)); INW[d] = 1; i += j
        } else if (c == "\"") {
            INW[d] = 1; i = dquote(i + 1, d)
        } else if (c == "\\") {
            e = substr(text, i + 1, 1); i++
            if (e != "\n") { CUR[d] = CUR[d] e; INW[d] = 1 }
        } else if (c == "$" && substr(text, i + 1, 1) == "(") {
            i = scan(i + 2, ")", d + 1); DYN[d] = 1; INW[d] = 1; CUR[d] = CUR[d] "$()"
        } else if (c == "`") {
            if (closer == "`") { endseg(d); return i }
            i = scan(i + 1, "`", d + 1); DYN[d] = 1; INW[d] = 1; CUR[d] = CUR[d] "`"
        } else if (c == "$" || c == "*" || c == "?" || c == "[") {
            CUR[d] = CUR[d] c; INW[d] = 1; DYN[d] = 1
        } else if (c == " " || c == "\t") {
            endword(d)
        } else if (c == "<" && substr(text, i, 3) == "<<<") {
            endword(d); i += 2
        } else if (c == "<" && substr(text, i + 1, 1) == "<") {
            endword(d); i += 2; tab = 0
            if (substr(text, i, 1) == "-") { tab = 1; i++ }
            i = readdelim(i)
            NH++; HD[NH] = DELIM; HT[NH] = tab
        } else if (c == "#" && !INW[d]) {
            while (i < n && substr(text, i + 1, 1) != "\n") i++
        } else if (c == "\n") {
            endseg(d)
            if (NH > 0) i = skipbodies(i)
        } else if (c == "(") {
            endseg(d); par++
        } else if (c == ")") {
            endseg(d)
            if (par > 0) par--
            else if (closer == ")") return i
        } else if (c == "&" || c == "|" || c == ";") {
            endseg(d)
        } else {
            CUR[d] = CUR[d] c; INW[d] = 1
        }
    }
    endseg(d)
    if (closer != "") bad = 1
    return n + 1
}
BEGIN { SEP = "\037"; Q = "\047"; MAXD = 4 }
{ text = (NR > 1 ? text "\n" : "") $0 }
END {
    n = length(text)
    scan(1, "", 0)
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
