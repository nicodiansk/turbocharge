#!/usr/bin/env bash
# ABOUTME: Lists a repository's definitions ranked by how often the code cites them, or one symbol's callers.
# ABOUTME: Runs on git, grep and awk alone; reads Python through ast when python3 exists.
set -uo pipefail

DEFAULT_TOP=30
MIN_NAME_LENGTH=3
CODE_GLOBS_NON_SHELL=('*.py' '*.js' '*.jsx' '*.mjs' '*.cjs' '*.ts' '*.tsx' '*.go' '*.rs' '*.rb' '*.java' '*.kt' '*.cs')
CODE_GLOBS_NO_PY=('*.js' '*.jsx' '*.mjs' '*.cjs' '*.ts' '*.tsx' '*.go' '*.rs' '*.rb' '*.java' '*.kt' '*.cs')
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

# Python definitions from ast (never imports or runs the file): reads the file list on stdin and prints
# `file<TAB>line<TAB>name<TAB>kind`. A file ast can't parse falls back to the regex used for the other languages.
PYTHON_AST_SCRIPT='
import ast, re, sys
MIN = int(sys.argv[1])
RX = ((re.compile(r"(?:^|[^A-Za-z0-9_.$])def\s+([A-Za-z_][A-Za-z0-9_]*)"), "function"),
      (re.compile(r"(?:^|[^A-Za-z0-9_.$])class\s+([A-Za-z_][A-Za-z0-9_]*)"), "class"))
def emit(path, line, name, kind):
    if len(name) >= MIN and not (name.startswith("__") and name.endswith("__")):
        print("%s\t%d\t%s\t%s" % (path, line, name, kind))
def by_regex(path, data):
    for n, text in enumerate(data.decode("utf-8", "replace").splitlines(), 1):
        for rx, kind in RX:
            m = rx.search(text)
            if m:
                emit(path, n, m.group(1), kind)
def by_ast(path, tree):
    stack = [(tree, False)]
    while stack:
        node, in_class = stack.pop()
        for child in ast.iter_child_nodes(node):
            if isinstance(child, ast.ClassDef):
                emit(path, child.lineno, child.name, "class")
                stack.append((child, True))
            elif isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef)):
                emit(path, child.lineno, child.name, "method" if in_class else "function")
                stack.append((child, False))
            else:
                stack.append((child, in_class))
for path in sys.stdin.read().split("\n"):
    if not path:
        continue
    try:
        with open(path, "rb") as fh:
            data = fh.read()
    except OSError:
        continue
    try:
        tree = ast.parse(data, filename=path)
    except (SyntaxError, UnicodeDecodeError, ValueError, RecursionError, MemoryError):
        by_regex(path, data)
        continue
    by_ast(path, tree)
'

python_available() {
    [ -z "${ATLAS_SYMBOLS_NO_PYTHON:-}" ] && command -v python3 >/dev/null 2>&1 && python3 -I -c 'import ast' >/dev/null 2>&1
}

# Python rows from ast. Returns 1 when ast mode is off or python3 fails, so the caller uses the regex step.
python_definitions() {
    python_available || return 1
    git ls-files -- '*.py' | python3 -I -c "$PYTHON_AST_SCRIPT" "$MIN_NAME_LENGTH"
}

# All definitions as `file<TAB>line<TAB>name<TAB>kind`, one row per file, line and name.
definitions() {
    local py_rows
    {
        if py_rows="$(python_definitions)"; then
            [ -z "$py_rows" ] || printf '%s\n' "$py_rows"
            grep_in -nIE "$KEYWORD_PATTERN" "${CODE_GLOBS_NO_PY[@]}" | extract_definitions
        else
            grep_in -nIE "$KEYWORD_PATTERN" "${CODE_GLOBS_NON_SHELL[@]}" | extract_definitions
        fi
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

cmd_where() {
    local name="$1" defs_file callers
    defs_file="$(mktemp)" || exit 2
    trap "rm -f '$defs_file'" EXIT
    definitions | awk -F'\t' -v n="$name" '$3 == n' > "$defs_file"
    callers="$(grep_in -nIw "$name" . | awk -F'\t' '
        FNR == NR { isdef[$1 SUBSEP $2] = 1; next }
        {
            i = index($0, ":"); file = substr($0, 1, i - 1); rest = substr($0, i + 1)
            i = index(rest, ":"); ln = substr(rest, 1, i - 1); text = substr(rest, i + 1)
            if ((file SUBSEP ln) in isdef) next
            sub(/^[[:space:]]+/, "", text)
            if (file != last) { out = out file "\n"; files++; last = file }
            out = out "  " ln ": " text "\n"; total++
        }
        END { if (total > 0) printf "callers (%d in %d files):\n%s", total, files, out }' "$defs_file" -)"
    if [ -s "$defs_file" ]; then
        echo "defined in:"
        awk -F'\t' '{ print "  " $1 ":" $2 " (" $4 ")" }' "$defs_file"
    else
        echo "defined in: none found"
    fi
    if [ -n "$callers" ]; then
        printf '%s\n' "$callers"
    else
        echo "callers: none found"
    fi
    [ -s "$defs_file" ] || [ -n "$callers" ]
}

[ "$#" -ge 1 ] || usage
case "$1" in
    top) CMD=top ;;
    where)
        CMD=where
        [ "$#" -eq 2 ] || usage
        case "$2" in
            ''|[!A-Za-z_]*|*[!A-Za-z0-9_]*)
                echo "atlas-symbols: not a symbol name: $2" >&2
                exit 2 ;;
        esac ;;
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
    where) cmd_where "$@" ;;
esac
