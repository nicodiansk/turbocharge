#!/usr/bin/env bash
# ABOUTME: git-guard — refuses a Bash command (PreToolUse) that stages files in bulk, skips the repository's git hooks, or runs a recursive delete through a symlink.
# ABOUTME: Reads hook JSON on stdin with jq; prints one JSON deny on stdout with the reason and what to do instead, exit 0. Fails open: anything unexpected exits 0 with no output.
# ABOUTME: Read-only — writes nothing, no network, runs only jq, awk, find and uname, never git.
# ABOUTME: Known limit — it lets a command through whenever it can't tell: an unbalanced quote, a dynamic word ($var, a glob), an abbreviated long option (git commit --al), text past 16384 bytes.
# ABOUTME: Known limit — an option's own argument isn't skipped after a wrapper, so `sudo -u bob git add -A` passes; recursion into `bash -c` and `eval` stops at 3 levels.
# ABOUTME: Known limit — on Windows shells whether find reports NTFS junctions as links is unverified, and uname is found through PATH.
# ABOUTME: Known limit — a $((1<<2)) arithmetic shift reads as a heredoc and hides the lines after it.
set -u
export LC_ALL=C

command -v jq >/dev/null 2>&1 || exit 0

MAX_COMMAND_BYTES=16384
MAX_LISTED_LINKS=10

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

# The deny_* functions deny, unless the user turned that guard off with its variable: then they return and the checks go on.

deny_staging() {
    is_off "${TURBOCHARGE_GIT_GUARD_STAGING:-}" && return 0
    deny "turbocharge git-guard: \`$(excerpt "$1")\` stages files in bulk. Stage explicit paths after \`git status\`: git add <paths>, then git commit -m \"<message>\" -- <paths>. To turn this check off, the user sets TURBOCHARGE_GIT_GUARD_STAGING=off."
}

deny_noverify() {
    is_off "${TURBOCHARGE_GIT_GUARD_NOVERIFY:-}" && return 0
    deny "turbocharge git-guard: \`$(excerpt "$1")\` skips the repository's git hooks. Run them: when one fails, fix what it reports, or ask the user. To turn this check off, the user sets TURBOCHARGE_GIT_GUARD_NOVERIFY=off."
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

# parse_segment <segment line>: SEG_TEXT (the words joined by blanks), WT (each word as written), WK (L or D per word), WV (the word; a dynamic
# word holds DYN, which never matches a flag or a path)
DYN=$'\001'
ASSIGN_RE='^[A-Za-z_][A-Za-z0-9_]*='
parse_segment() {
    local raw w
    SEG_TEXT=""; WK=(); WV=(); WT=()
    IFS=$'\037' read -r -a raw <<< "$1"
    for w in ${raw[@]+"${raw[@]}"}; do
        SEG_TEXT="${SEG_TEXT:+$SEG_TEXT }${w:1}"
        WT[${#WT[@]}]="${w:1}"
        WK[${#WK[@]}]="${w:0:1}"
        if [ "${w:0:1}" = L ]; then WV[${#WV[@]}]="${w:1}"; else WV[${#WV[@]}]="$DYN"; fi
    done
}

BULK_PATHSPEC_RE='^\./*$'
# Long `git commit` options that take the next word, and the short letters that take the rest of the cluster or the next word.
COMMIT_LONG_VALUE=" --message --file --reuse-message --reedit-message --template --author --date --fixup --squash --cleanup --trailer --pathspec-from-file "
COMMIT_SHORT_VALUE="mFcCt"
# Short letters that take only an attached optional value (-uno, -Skeyid): the rest of the cluster is theirs.
COMMIT_SHORT_ATTACHED="uS"

# check_git_add_args <first index>: bulk staging unless a dry run. Flags count before `--`; a pathspec counts anywhere.
check_git_add_args() {
    local i past=0 bulk=0 dry=0 w
    for ((i = $1; i < ${#WV[@]}; i++)); do
        [ "${WK[i]}" = L ] || continue
        w="${WV[i]}"
        if [ "$past" = 0 ] && [ "$w" = -- ]; then past=1; continue; fi
        if [ "$past" = 0 ]; then
            case "$w" in
                --all|--update) bulk=1; continue ;;
                --dry-run) dry=1; continue ;;
                --*) continue ;;
                -?*) case "$w" in *[Au]*) bulk=1 ;; esac
                     case "$w" in *n*) dry=1 ;; esac
                     continue ;;
            esac
        fi
        if [ "$w" = ':/' ] || [[ $w =~ $BULK_PATHSPEC_RE ]]; then bulk=1; fi
    done
    [ "$bulk" = 1 ] && [ "$dry" = 0 ] && deny_staging "$SEG_TEXT"
    return 0
}

# check_git_commit_args <first index>: -a / --all and -n / --no-verify, before `--`
check_git_commit_args() {
    local i=$1 n=${#WV[@]} w rest ch k
    while [ "$i" -lt "$n" ]; do
        w="${WV[i]}"
        [ "${WK[i]}" = L ] || { i=$((i + 1)); continue; }
        case "$w" in
            --) return 0 ;;
            --all) deny_staging "$SEG_TEXT" ;;
            --no-verify) deny_noverify "$SEG_TEXT" ;;
            --*) case "$COMMIT_LONG_VALUE" in *" $w "*) i=$((i + 1)) ;; esac ;;
            -?*)
                rest="${w:1}"
                for ((k = 0; k < ${#rest}; k++)); do
                    ch="${rest:k:1}"
                    case "$ch" in
                        a) deny_staging "$SEG_TEXT" ;;
                        n) deny_noverify "$SEG_TEXT" ;;
                        [$COMMIT_SHORT_VALUE]) [ "$k" -eq $((${#rest} - 1)) ] && i=$((i + 1)); break ;;
                        [$COMMIT_SHORT_ATTACHED]) break ;;
                    esac
                done ;;
        esac
        i=$((i + 1))
    done
}

# check_git_push_args <first index>: --no-verify, before `--` (-n is --dry-run)
check_git_push_args() {
    local i w
    for ((i = $1; i < ${#WV[@]}; i++)); do
        [ "${WK[i]}" = L ] || continue
        w="${WV[i]}"
        [ "$w" = -- ] && return 0
        [ "$w" = --no-verify ] && deny_noverify "$SEG_TEXT"
    done
    return 0
}

# check_git_config <value>: a -c or --config-env value that sets core.hooksPath
check_git_config() {
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
        core.hookspath=*) deny_noverify "$SEG_TEXT" ;;
    esac
}

# check_git_worktree <first index>: `git worktree remove [-f] <path>` goes through the same two checks as rm -r
check_git_worktree() {
    local i=$1 n=${#WV[@]} c
    local CWD="$CWD"
    [ "$i" -lt "$n" ] && [ "${WV[i]}" = remove ] || return 0
    for c in ${GIT_C[@]+"${GIT_C[@]}"}; do
        if [ "$c" = "$DYN" ]; then CWD=""; else CWD="$(resolve_path "$c")"; fi
    done
    for ((i = i + 1; i < n; i++)); do
        [ "${WK[i]}" = L ] || return 0
        case "${WV[i]}" in -*) ;; *) check_operand "${WV[i]}"; return 0 ;; esac
    done
}

# check_git <index of the git word>: skip git's global options, then dispatch on the subcommand
check_git() {
    local i=$(($1 + 1)) n=${#WV[@]} w
    GIT_C=()
    while [ "$i" -lt "$n" ]; do
        w="${WV[i]}"
        [ "${WK[i]}" = L ] || return 0
        case "$w" in
            -C) GIT_C[${#GIT_C[@]}]="${WV[i+1]:-}"; i=$((i + 2)) ;;
            -c|--config-env) check_git_config "${WV[i+1]:-}"; i=$((i + 2)) ;;
            --config-env=*) check_git_config "${w#--config-env=}"; i=$((i + 1)) ;;
            --git-dir|--work-tree|--namespace) i=$((i + 2)) ;;
            -*) i=$((i + 1)) ;;
            *) break ;;
        esac
    done
    [ "$i" -lt "$n" ] || return 0
    case "${WV[i]}" in
        add|stage) check_git_add_args $((i + 1)) ;;
        commit) check_git_commit_args $((i + 1)) ;;
        push) check_git_push_args $((i + 1)) ;;
        worktree) check_git_worktree $((i + 1)) ;;
    esac
}

deny_symlink() {
    deny "turbocharge git-guard: \`$(excerpt "$1")\` goes through the symlink \`$(excerpt "$2")\`, so the delete empties the folder the link points to, not the link. To remove only the link: rm $2 (no trailing slash). To clear the target, name its real path. To turn this check off, the user sets TURBOCHARGE_GIT_GUARD_SYMLINKS=off."
}

# strip_trailing <path>: drop trailing / and /. until neither is left
strip_trailing() {
    local p="$1"
    while :; do
        case "$p" in
            */.) p="${p%/.}" ;;
            */) p="${p%/}" ;;
            *) break ;;
        esac
    done
    printf '%s' "$p"
}

# resolve_path <path as written>: absolute path from ~, an absolute path or the tracked cwd; empty when unknown
resolve_path() {
    case "$1" in
        '~') printf '%s' "${HOME:-}" ;;
        '~/'*) [ -n "${HOME:-}" ] && printf '%s/%s' "$HOME" "${1#\~/}" ;;
        /*|[A-Za-z]:/*) printf '%s' "$1" ;;
        *) [ -n "$CWD" ] && printf '%s/%s' "$CWD" "$1" ;;
    esac
    return 0
}

# check_through <operand as written>: a trailing / or /. on a symlink to a directory deletes the target's contents
check_through() {
    local op="$1" base path
    case "$op" in */|*/.) ;; *) return 0 ;; esac
    base="$(strip_trailing "$op")"
    [ -n "$base" ] || return 0
    path="$(resolve_path "$base")"
    [ -n "$path" ] || return 0
    if [ -L "$path" ] && [ -d "$path" ]; then deny_symlink "$op" "$base"; fi
    return 0
}

deny_links() {
    deny "turbocharge git-guard: \`$(excerpt "$1")\` holds links, and on Windows a recursive delete can follow one out of the folder (a junction once emptied a checkout, .git included): $2. Remove the links first (rm <link>, without -r), then retry. To turn this check off, the user sets TURBOCHARGE_GIT_GUARD_SYMLINKS=off."
}

# is_windows_shell: uname -s (found through PATH) names Git Bash, MSYS2 or Cygwin; read once
OS_KIND=""
is_windows_shell() {
    if [ -z "$OS_KIND" ]; then
        case "$(uname -s 2>/dev/null)" in MINGW*|MSYS*|CYGWIN*) OS_KIND=win ;; *) OS_KIND=other ;; esac
    fi
    [ "$OS_KIND" = win ]
}

# check_links <operand as written> <resolved path>: on Windows shells, a folder holding links (depth 2) is refused
check_links() {
    local op="$1" dir="$2" links line k=0 list=""
    [ -d "$dir" ] && [ ! -L "$dir" ] || return 0
    is_windows_shell || return 0
    links="$(find "$dir" -maxdepth 2 -type l 2>/dev/null)"
    [ -n "$links" ] || return 0
    while IFS= read -r line; do
        k=$((k + 1))
        [ "$k" -le "$MAX_LISTED_LINKS" ] && list="${list:+$list, }${line#"$dir"/}"
    done <<< "$links"
    [ "$k" -le "$MAX_LISTED_LINKS" ] || list="$list (+$((k - MAX_LISTED_LINKS)) more)"
    deny_links "$op" "$list"
}

# check_operand <operand as written>: both link checks for one path a recursive delete names
check_operand() {
    local base path
    is_off "${TURBOCHARGE_GIT_GUARD_SYMLINKS:-}" && return 0
    check_through "$1"
    base="$(strip_trailing "$1")"
    [ -n "$base" ] || return 0
    path="$(resolve_path "$base")"
    [ -n "$path" ] || return 0
    check_links "$1" "$path"
}

# check_rm <index of the rm word>: the operands of a recursive rm
check_rm() {
    local i n=${#WV[@]} past=0 rec=0 w ops=()
    for ((i = $1 + 1; i < n; i++)); do
        [ "${WK[i]}" = L ] || continue
        w="${WV[i]}"
        if [ "$past" = 1 ]; then ops[${#ops[@]}]="$w"; continue; fi
        case "$w" in
            --) past=1 ;;
            --recursive) rec=1 ;;
            --*) ;;
            -?*) case "$w" in *[rR]*) rec=1 ;; esac ;;
            *) ops[${#ops[@]}]="$w" ;;
        esac
    done
    [ "$rec" = 1 ] || return 0
    for w in ${ops[@]+"${ops[@]}"}; do check_operand "$w"; done
}

# track_cwd <index of the cd word>: cd moves the tracked cwd; an unknown target makes it unknown
track_cwd() {
    local i=$(($1 + 1)) n=${#WV[@]}
    while [ "$i" -lt "$n" ] && [ "${WK[i]}" = L ]; do
        case "${WV[i]}" in -P|-L|-e|-@|--) i=$((i + 1)) ;; *) break ;; esac
    done
    if [ "$i" -ge "$n" ]; then CWD="${HOME:-}"
    elif [ "${WK[i]}" != L ] || [ "${WV[i]}" = - ]; then CWD=""
    else CWD="$(resolve_path "${WV[i]}")"; fi
}

# Words skipped before a segment's command word: wrappers (their own -options too) and shell keywords.
WRAPPERS=" sudo env command builtin exec nohup time nice "
KEYWORDS=" ! { if then else elif do while until "
SHELLS=" bash sh zsh dash ksh "
MAX_NEST=3
NEST=0

# find_command: sets CMD_I to the index of the command word (skipping NAME=value, wrappers and keywords), or -1
find_command() {
    local i=0 n=${#WV[@]} base
    while [ "$i" -lt "$n" ]; do
        if [[ ${WT[i]} =~ $ASSIGN_RE ]]; then i=$((i + 1)); continue; fi
        [ "${WK[i]}" = L ] || break
        base="${WV[i]##*/}"
        case "$WRAPPERS" in
            *" $base "*)
                i=$((i + 1))
                while [ "$i" -lt "$n" ] && [ "${WK[i]}" = L ] && [ "${WV[i]#-}" != "${WV[i]}" ]; do i=$((i + 1)); done
                continue ;;
        esac
        case "$KEYWORDS" in *" ${WV[i]} "*) i=$((i + 1)); continue ;; esac
        break
    done
    if [ "$i" -lt "$n" ] && [ "${WK[i]}" = L ]; then CMD_I=$i; else CMD_I=-1; fi
}

# check_nested <text>: check a command string held in another command, down to MAX_NEST levels
check_nested() {
    [ "$NEST" -lt "$MAX_NEST" ] || return 0
    NEST=$((NEST + 1))
    check_command "$1"
    NEST=$((NEST - 1))
}

# check_shell <index of the shell word>: `bash -c '<script>'`, with the script a literal word
check_shell() {
    local i=$(($1 + 1)) n=${#WV[@]} w
    while [ "$i" -lt "$n" ] && [ "${WK[i]}" = L ]; do
        w="${WV[i]}"
        case "$w" in
            --|[!-]*) return 0 ;;
            -c|-[!-]*c)
                [ "$((i + 1))" -lt "$n" ] && [ "${WK[i+1]}" = L ] && check_nested "${WV[i+1]}"
                return 0 ;;
        esac
        i=$((i + 1))
    done
}

# check_eval <index of the eval word>: `eval` followed only by literal words
check_eval() {
    local i text=""
    for ((i = $1 + 1; i < ${#WV[@]}; i++)); do
        [ "${WK[i]}" = L ] || return 0
        text="${text:+$text }${WV[i]}"
    done
    [ -z "$text" ] || check_nested "$text"
}

check_segment() {
    local base
    parse_segment "$1"
    find_command
    [ "$CMD_I" -ge 0 ] || return 0
    base="${WV[CMD_I]##*/}"
    case "$base" in
        git) check_git "$CMD_I" ;;
        eval) check_eval "$CMD_I" ;;
        rm) check_rm "$CMD_I" ;;
        cd) track_cwd "$CMD_I" ;;
        pushd|popd) CWD="" ;;
        *) case "$SHELLS" in *" $base "*) check_shell "$CMD_I" ;; esac ;;
    esac
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

CWD="$(field .cwd)"; CWD="${CWD//\\//}"
check_command "$COMMAND"
exit 0
