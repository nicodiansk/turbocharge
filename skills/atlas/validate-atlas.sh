#!/usr/bin/env bash
# ABOUTME: Validates an ATLAS.md: required headers, and every backticked path and Key Symbols name it cites.
# ABOUTME: Exits 0 on pass, 1 on any problem or a missing file. CRLF files read like LF ones; the file is never rewritten.
set -uo pipefail
TARGET="${1:-ATLAS.md}"
REQUIRED=("## Where to Look" "## Entry Points" "## Module Map" "## Key Symbols" "## Integration Points" "## Conventions & Gotchas")
if [ ! -f "$TARGET" ]; then
    echo "ATLAS-VALIDATE: $TARGET not found." >&2
    exit 1
fi
ROOT="$(cd "$(dirname "$TARGET")" && pwd)" || exit 1

# One normalized copy with the trailing \r of every line stripped; every check reads it, never the target.
NORM="$(mktemp)" || exit 1
CITED="$(mktemp)" || exit 1
trap 'rm -f "$NORM" "$CITED"' EXIT
awk '{ sub(/\r$/, ""); print }' "$TARGET" > "$NORM"

FLOWS_MAX=5
PROBLEMS=0
problem() {
    echo "ATLAS-VALIDATE: $1" >&2
    PROBLEMS=$((PROBLEMS+1))
}

for h in "${REQUIRED[@]}"; do
    if ! grep -qxF -- "$h" "$NORM"; then
        problem "missing required header: $h"
    fi
done

# Every table cell and Key Flows bullet that cites a path or a symbol, as `line<TAB>kind<TAB>token[<TAB>file]` rows:
# kind `path` is a backticked token to find on disk, kind `sym` is a Key Symbols name to find in its file,
# kind `lineref` is a Key Symbols file token carrying a line number, kind `flow` counts one Key Flows bullet.
awk '
function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
function tokens(cell, kind,    t) {
    while (match(cell, /`[^`]+`/)) {
        t = substr(cell, RSTART + 1, RLENGTH - 2)
        if (kind == "key") print NR "\t" (t ~ /:[0-9]+(-[0-9]+)?$/ ? "lineref" : "path") "\t" t
        else print NR "\t" kind "\t" t
        cell = substr(cell, RSTART + RLENGTH)
    }
}
/^## / { section = $0; first = 1; next }
section == "## Key Flows" && /^[[:space:]]*[-*][[:space:]]/ { print NR "\tflow\t-"; tokens($0, "path"); next }
/^\|/ {
    if ($0 ~ /^\|[[:space:]:|-]+$/) next
    if (first) { first = 0; next }
    n = split($0, c, "|")
    if (section == "## Where to Look")        tokens(c[3], "path")
    else if (section == "## Entry Points")    tokens(c[2], "path")
    else if (section == "## Module Map")      { tokens(c[2], "path"); tokens(c[4], "path") }
    else if (section == "## Integration Points") tokens(c[4], "path")
    else if (section == "## Key Symbols") {
        tokens(c[3], "key")
        sym = trim(c[2]); gsub(/`/, "", sym); sub(/\(\)$/, "", sym)
        if (sym != "" && match(c[3], /`[^`]+`/) && substr(c[3], RSTART + 1, RLENGTH - 2) !~ /:[0-9]+(-[0-9]+)?$/) print NR "\tsym\t" sym "\t" substr(c[3], RSTART + 1, RLENGTH - 2)
    }
}' "$NORM" > "$CITED"

# A token naming something that has to exist under the atlas root.
path_exists() {
    local t="$1"
    case "$t" in
        */) [ -d "$ROOT/$t" ] ;;
        *[*?]*) (cd "$ROOT" && compgen -G "$t" >/dev/null) ;;
        *) [ -e "$ROOT/$t" ] ;;
    esac
}

FLOWS=0
TAB="$(printf '\t')"
while IFS="$TAB" read -r n kind a b; do
    case "$kind" in
        path)
            path_exists "$a" || problem "line $n: path not found: $a"
            ;;
        lineref)
            problem "line $n: Key Symbols cites a line number ($a): name the file only"
            ;;
        flow)
            FLOWS=$((FLOWS+1))
            ;;
        sym)
            if [ -f "$ROOT/$b" ] && ! grep -qwF -- "$a" "$ROOT/$b"; then
                problem "line $n: $a not found in $b"
            fi
            ;;
    esac
done < "$CITED"
if [ "$FLOWS" -gt "$FLOWS_MAX" ]; then
    problem "Key Flows has $FLOWS flows, at most $FLOWS_MAX"
fi

# The footer names the commit the map was written at: only checkable inside a git work tree that has a commit.
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 && git -C "$ROOT" rev-parse -q --verify HEAD >/dev/null 2>&1; then
    SHA="$(grep -oE '<!-- atlas-sha:[0-9a-f]{7,40} -->' "$NORM" | tail -n 1 | sed 's/^<!-- atlas-sha://; s/ -->$//')"
    if [ -z "$SHA" ]; then
        problem "missing atlas-sha footer (a pre-3.8 atlas-hash footer doesn't count)"
    elif ! git -C "$ROOT" cat-file -e "$SHA^{commit}" 2>/dev/null; then
        problem "atlas-sha $SHA is not a commit in this repository"
    fi
fi

if [ "$PROBLEMS" -gt 0 ]; then
    echo "ATLAS-VALIDATE: $PROBLEMS problem(s)." >&2
    exit 1
fi
echo "ATLAS-VALIDATE: $TARGET OK"
