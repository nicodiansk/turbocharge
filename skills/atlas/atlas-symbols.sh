#!/usr/bin/env bash
# ABOUTME: Lists a repository's definitions ranked by how often the code cites them, or one symbol's callers.
# ABOUTME: Runs on git, grep and awk alone; reads Python through ast when python3 exists.
set -uo pipefail

DEFAULT_TOP=30
MIN_NAME_LENGTH=3
CODE_GLOBS_NON_SHELL=('*.py' '*.js' '*.jsx' '*.mjs' '*.cjs' '*.ts' '*.tsx' '*.go' '*.rs' '*.rb' '*.java' '*.kt' '*.cs')
SHELL_GLOBS=('*.sh' '*.bash')
# Keywords that can open a definition outside the shell family.
KEYWORD_PATTERN='(def|class|function|interface|type|const|let|var|func|fn|struct|enum|trait|module|record)[[:space:]]'
SHELL_PATTERN='\(\)|function[[:space:]]'

usage() {
    echo "usage: atlas-symbols.sh top [N] | where NAME" >&2
    exit 2
}

# git grep over the given globs, leaving out files that would only skew the counts.
grep_in() {
    local mode="$1" pattern="$2"
    shift 2
    git grep "$mode" -e "$pattern" -- "$@" \
        ':(exclude)ATLAS.md' ':(exclude)*.min.js' ':(exclude)*.lock' ':(exclude)package-lock.json'
}

# Turns `file:line:text` lines into `file<TAB>line<TAB>name<TAB>kind` rows, one regex per language.
extract_definitions() {
    awk -v minlen="$MIN_NAME_LENGTH" '
    function ext(f,    n, parts) { n = split(f, parts, "."); return n > 1 ? parts[n] : "" }
    function emit(name, kind) {
        if (length(name) < minlen || name ~ /^__.*__$/) return
        print file "\t" ln "\t" name "\t" kind
    }
    # keyword + identifier anywhere on the line, the keyword standing alone
    function after(kw, kind,    re, s) {
        re = "(^|[^A-Za-z0-9_.$])" kw "[[:space:]]+[A-Za-z_][A-Za-z0-9_]*"
        if (match(text, re)) {
            s = substr(text, RSTART, RLENGTH)
            sub("^[^A-Za-z0-9_]?" kw "[[:space:]]+", "", s)
            emit(s, kind)
        }
    }
    {
        i = index($0, ":"); file = substr($0, 1, i - 1); rest = substr($0, i + 1)
        i = index(rest, ":"); ln = substr(rest, 1, i - 1); text = substr(rest, i + 1)
        e = ext(file)
        if (e == "py") { after("def", "function"); after("class", "class") }
        else if (e ~ /^(js|jsx|mjs|cjs|ts|tsx)$/) {
            after("function", "function"); after("class", "class"); after("interface", "type")
            if (match(text, /(^|[^A-Za-z0-9_.$])type[[:space:]]+[A-Za-z_][A-Za-z0-9_]*([<][^=]*[>])?[[:space:]]*=/)) {
                s = substr(text, RSTART, RLENGTH); sub(/^[^A-Za-z0-9_]?type[[:space:]]+/, "", s)
                match(s, /^[A-Za-z_][A-Za-z0-9_]*/); emit(substr(s, 1, RLENGTH), "type")
            }
            if (match(text, /^(export[[:space:]]+)?(declare[[:space:]]+)?(const|let|var)[[:space:]]+[A-Za-z_][A-Za-z0-9_$]*[[:space:]]*[=:]/)) {
                s = substr(text, RSTART, RLENGTH)
                sub(/^(export[[:space:]]+)?(declare[[:space:]]+)?(const|let|var)[[:space:]]+/, "", s)
                match(s, /^[A-Za-z_][A-Za-z0-9_$]*/); emit(substr(s, 1, RLENGTH), "const")
            }
        }
        else if (e == "go") {
            if (match(text, /^func[[:space:]]+([(][^)]*[)][[:space:]]*)?[A-Za-z_][A-Za-z0-9_]*/)) {
                s = substr(text, RSTART, RLENGTH); sub(/^func[[:space:]]+([(][^)]*[)][[:space:]]*)?/, "", s); emit(s, "function")
            }
            if (match(text, /^type[[:space:]]+[A-Za-z_][A-Za-z0-9_]*/)) {
                s = substr(text, RSTART, RLENGTH); sub(/^type[[:space:]]+/, "", s); emit(s, "type")
            }
        }
        else if (e == "rs") { after("fn", "function"); after("struct", "type"); after("enum", "type"); after("trait", "type") }
        else if (e == "rb") {
            if (match(text, /(^|[^A-Za-z0-9_.$])def[[:space:]]+(self[.])?[A-Za-z_][A-Za-z0-9_]*/)) {
                s = substr(text, RSTART, RLENGTH); sub(/^[^A-Za-z0-9_]?def[[:space:]]+(self[.])?/, "", s); emit(s, "function")
            }
            after("class", "class"); after("module", "class")
        }
        else if (e ~ /^(java|kt|cs)$/) { after("class", "class"); after("interface", "class"); after("enum", "class"); after("record", "class") }
        else if (e ~ /^(sh|bash)$/) {
            if (match(text, /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*[(][)]/)) {
                s = substr(text, RSTART, RLENGTH); sub(/^[[:space:]]+/, "", s); match(s, /^[A-Za-z_][A-Za-z0-9_]*/); emit(substr(s, 1, RLENGTH), "function")
            }
            after("function", "function")
        }
    }'
}

# All definitions as `file<TAB>line<TAB>name<TAB>kind`, one row per file, line and name.
definitions() {
    {
        grep_in -nIE "$KEYWORD_PATTERN" "${CODE_GLOBS_NON_SHELL[@]}" | extract_definitions
        grep_in -nIE "$SHELL_PATTERN" "${SHELL_GLOBS[@]}" | extract_definitions
    } | LC_ALL=C sort -u
}

# `refs<TAB>name<TAB>kind<TAB>file`, unsorted: every occurrence of the name minus its definition lines.
ranked_rows() {
    local defs_file="$1"
    grep_in -ohIwE '[A-Za-z_][A-Za-z0-9_]*' . | awk -F'\t' '
        FNR == NR { lines[$3]++; if (!(($3 SUBSEP $1) in seen)) { seen[$3 SUBSEP $1] = 1; kind[$3 SUBSEP $1] = $4; order[++n] = $3 SUBSEP $1 } next }
        ($0 in lines) { occ[$0]++ }
        END {
            for (k = 1; k <= n; k++) {
                split(order[k], p, SUBSEP)
                r = occ[p[1]] - lines[p[1]]; if (r < 0) r = 0
                print r "\t" p[1] "\t" kind[order[k]] "\t" p[2]
            }
        }' "$defs_file" -
}

cmd_top() {
    local limit="$DEFAULT_TOP" defs_file
    if [ "$#" -gt 1 ]; then usage; fi
    if [ "$#" -eq 1 ]; then
        case "$1" in ''|*[!0-9]*|0*) usage ;; esac
        limit="$1"
    fi
    defs_file="$(mktemp)" || exit 2
    trap "rm -f '$defs_file'" EXIT
    definitions > "$defs_file"
    ranked_rows "$defs_file" | LC_ALL=C sort -t "$(printf '\t')" -k1,1nr -k2,2 -k4,4 | awk -v n="$limit" 'NR <= n'
}

[ "$#" -ge 1 ] || usage
case "$1" in
    top) CMD=top ;;
    where) CMD=where ;;
    *) usage ;;
esac

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "atlas-symbols: run inside a git repository" >&2
    exit 2
fi
cd "$(git rev-parse --show-toplevel)" || exit 2

shift
case "$CMD" in
    top) cmd_top "$@" ;;
    where) usage ;;
esac
