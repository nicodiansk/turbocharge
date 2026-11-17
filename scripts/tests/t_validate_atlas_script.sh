#!/usr/bin/env bash
# ABOUTME: Drives skills/atlas/validate-atlas.sh: required headers, CRLF input, every cited path and Key Symbols name,
# ABOUTME: the atlas-sha footer, Key Flows, and the size warnings (warn, never block).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/atlas/validate-atlas.sh"
assert_file "$F" || exit 1
[ ! -e "$PLUGIN_DIR/scripts/validate-atlas.sh" ] || { echo "    scripts/validate-atlas.sh still exists: the validator lives in skills/atlas/"; exit 1; }
bash -n "$F" || { echo "    syntax error"; exit 1; }
# Drives required-header logic
assert_grep "$F" "Where to Look"       || exit 1
assert_grep "$F" "Entry Points"        || exit 1
assert_grep "$F" "Module Map"          || exit 1
assert_grep "$F" "Key Symbols"         || exit 1
assert_grep "$F" "Integration Points"  || exit 1

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null 2>/dev/null || true
NL=$'\n'

# fresh DIR: an empty directory under TMP, printed
fresh() { local d; d="$(mktemp -d "$TMP/case.XXXXXX")"; printf '%s' "$d"; }
# run NAME DIR: runs the validator on DIR/ATLAS.md from DIR, output (both streams) in $OUT, status in $RC
run() { OUT="$(cd "$1" && bash "$F" ATLAS.md 2>&1)"; RC=$?; }
expect_ok()   { run "$1"; [ "$RC" = 0 ] || { echo "    $2: expected exit 0, got $RC: $OUT"; exit 1; }; }
expect_fail() { run "$1"; [ "$RC" = 1 ] || { echo "    $2: expected exit 1, got $RC: $OUT"; exit 1; }; }
has_out()     { printf '%s' "$OUT" | grep -qF -- "$1" || { echo "    $2: output lacks '$1': $OUT"; exit 1; }; }
lacks_out()   { printf '%s' "$OUT" | grep -qF -- "$1" && { echo "    $2: output has '$1': $OUT"; exit 1; }; return 0; }

HEADERS="# ATLAS — Test
## Where to Look
## Entry Points
## Module Map
## Key Symbols
## Integration Points
## Conventions & Gotchas"
# atlas WTL KP IP MM: ATLAS.md from section bodies (each "" or table rows, newline separated)
atlas() {
    printf '%s\n' "# ATLAS — Test" "## Where to Look" "| I want to... | Open | Why |" "|---|---|---|" "$1" \
        "## Entry Points" ${5:+"## Key Flows" "$5"} "## Module Map" "| Directory | Purpose | Key files |" "|---|---|---|" "$4" \
        "## Key Symbols" "| Symbol | File | Kind | Refs |" "|---|---|---|---|" "$2" \
        "## Integration Points" "| System | Config key | Path |" "|---|---|---|" "$3" "## Conventions & Gotchas"
}
src_app() { mkdir -p "$1/src" "$1/docs"; printf 'def run_app():\n    pass\n' > "$1/src/app.py"; printf 'n\n' > "$1/docs/my notes.md"; }

# Fails cleanly when ATLAS.md missing
D="$(fresh)"; expect_fail "$D" "missing ATLAS.md"

# Passes when minimal ATLAS.md with all headers present
D="$(fresh)"; printf '%s\n' "$HEADERS" > "$D/ATLAS.md"; expect_ok "$D" "header-only"
has_out "ATLAS-VALIDATE: ATLAS.md OK" "header-only"

# A missing header is named
D="$(fresh)"; printf '%s\n' "$HEADERS" | grep -v 'Module Map' > "$D/ATLAS.md"; expect_fail "$D" "missing header"
has_out "missing required header: ## Module Map" "missing header"

# CRLF endings read like LF endings
D="$(fresh)"; printf '%s\r\n' "# ATLAS — Test" "## Where to Look" "## Entry Points" "## Module Map" "## Key Symbols" "## Integration Points" "## Conventions & Gotchas" > "$D/ATLAS.md"
cp "$D/ATLAS.md" "$D/before.md"
expect_ok "$D" "CRLF header-only"
cmp -s "$D/ATLAS.md" "$D/before.md" || { echo "    the validator rewrote a CRLF ATLAS.md"; exit 1; }

# Where to Look: a missing path is named with its line, an existing one is not
D="$(fresh)"; src_app "$D"
atlas '| find app | `src/app.py` | entry |
| find gone | `src/gone.py` | missing |' "" "" "" > "$D/ATLAS.md"
expect_fail "$D" "where to look path"
has_out "path not found: src/gone.py" "where to look path"
has_out "ATLAS-VALIDATE: line 6:" "where to look path"
lacks_out "src/app.py" "where to look path"
# a CRLF copy of the same file reports the same
sed 's/$/\r/' "$D/ATLAS.md" > "$D/crlf.md"; mv "$D/crlf.md" "$D/ATLAS.md"
expect_fail "$D" "where to look path (CRLF)"
has_out "path not found: src/gone.py" "where to look path (CRLF)"
lacks_out "src/app.py" "where to look path (CRLF)"

# Module Map key files: only the missing one is named
D="$(fresh)"; src_app "$D"
atlas "" "" "" '| `src/` | app | `src/app.py`, `src/missing.py` |' > "$D/ATLAS.md"
expect_fail "$D" "module map"
has_out "path not found: src/missing.py" "module map"
lacks_out "path not found: src/app.py" "module map"
lacks_out "path not found: src/\`" "module map"

# Key Symbols: the symbol must still appear in its file
D="$(fresh)"; src_app "$D"
atlas "" '| `run_app` | `src/app.py` | function | 3 |' "" "" > "$D/ATLAS.md"
expect_ok "$D" "key symbol present"
sed 's/run_app/start_app/' "$D/src/app.py" > "$D/src/app2.py" && mv "$D/src/app2.py" "$D/src/app.py"
expect_fail "$D" "key symbol renamed"
has_out "run_app not found in src/app.py" "key symbol renamed"
# a trailing () on the symbol is stripped
atlas "" '| `start_app()` | `src/app.py` | function | 3 |' "" "" > "$D/ATLAS.md"
expect_ok "$D" "key symbol with ()"

# Integration Points: env names are not paths; dirs need a trailing slash match; spaces work
D="$(fresh)"; src_app "$D"
atlas "" "" '| db | `DATABASE_URL` | `src/` |
| notes | `DATABASE_URL` | `docs/my notes.md` |' "" > "$D/ATLAS.md"
expect_ok "$D" "integration points"
atlas "" "" '| db | `DATABASE_URL` | `src/app.py/` |' "" > "$D/ATLAS.md"
expect_fail "$D" "file with trailing slash"
has_out "path not found: src/app.py/" "file with trailing slash"
atlas "" "" '| db | `DATABASE_URL` | `src/*.py` |' "" > "$D/ATLAS.md"
expect_ok "$D" "glob that matches"
atlas "" "" '| db | `DATABASE_URL` | `src/*.rs` |' "" > "$D/ATLAS.md"
expect_fail "$D" "glob that matches nothing"
# Footer: in a git work tree with a commit, atlas-sha must name a commit
D="$(fresh)"; src_app "$D"
git init -q "$D"; git -C "$D" config user.name Fixture; git -C "$D" config user.email fixture@example.com
git -C "$D" add -A && git -C "$D" commit -q -m one
HEAD_SHA="$(git -C "$D" rev-parse HEAD)"
atlas "" "" "" "" > "$D/ATLAS.md"
expect_fail "$D" "no footer in git"
has_out "missing atlas-sha footer" "no footer in git"
{ atlas "" "" "" ""; echo "<!-- atlas-sha:$HEAD_SHA -->"; } > "$D/ATLAS.md"
expect_ok "$D" "footer = HEAD"
{ atlas "" "" "" ""; echo "<!-- atlas-sha:${HEAD_SHA%"${HEAD_SHA#???????}"} -->"; } > "$D/ATLAS.md"
expect_ok "$D" "footer = 7-char HEAD"
{ atlas "" "" "" ""; echo "<!-- atlas-sha:0000000 -->"; } > "$D/ATLAS.md"
expect_fail "$D" "footer not a commit"
has_out "atlas-sha 0000000 is not a commit in this repository" "footer not a commit"
{ atlas "" "" "" ""; echo "<!-- atlas-hash:abc123def456 -->"; } > "$D/ATLAS.md"
expect_fail "$D" "only an atlas-hash footer"
has_out "missing atlas-sha footer" "only an atlas-hash footer"
# the last footer wins
{ atlas "" "" "" ""; echo "<!-- atlas-sha:0000000 -->"; echo "<!-- atlas-sha:$HEAD_SHA -->"; } > "$D/ATLAS.md"
expect_ok "$D" "last footer wins"
# a git repository with no commit has nothing to name: no footer check
E="$(fresh)"; git init -q "$E"; atlas "" "" "" "" > "$E/ATLAS.md"
expect_ok "$E" "git repository with no commit"
# outside git, no footer is fine
D="$(fresh)"; atlas "" "" "" "" > "$D/ATLAS.md"; expect_ok "$D" "non-git, no footer"

# Key Symbols names the file only: a line number is refused
D="$(fresh)"; src_app "$D"
atlas "" '| `run_app` | `src/app.py:10-42` | function | 3 |' "" "" > "$D/ATLAS.md"
expect_fail "$D" "key symbols line number"
has_out "Key Symbols cites a line number (src/app.py:10-42): name the file only" "key symbols line number"
atlas "" '| `run_app` | `src/app.py:10` | function | 3 |' "" "" > "$D/ATLAS.md"
expect_fail "$D" "key symbols single line number"
has_out "cites a line number (src/app.py:10)" "key symbols single line number"

# Key Flows: optional, every token must exist, at most 5 bullets
D="$(fresh)"; src_app "$D"; printf 'x\n' > "$D/src/b.py"; printf 'x\n' > "$D/src/c.py"
FLOW='- ship: `src/app.py` → `src/b.py` → `src/c.py`'
THREE="$FLOW$NL"'- again: `src/app.py` → `src/b.py`'"$NL"'- third: `src/c.py`'
atlas "" "" "" "" "$THREE" > "$D/ATLAS.md"
expect_ok "$D" "three flows"
atlas "" "" "" "" "$FLOW
$FLOW
$FLOW
$FLOW
$FLOW
$FLOW" > "$D/ATLAS.md"
expect_fail "$D" "six flows"
has_out "Key Flows has 6 flows, at most 5" "six flows"
atlas "" "" "" "" '- broken: `src/app.py` → `src/nope.py`' > "$D/ATLAS.md"
expect_fail "$D" "flow citing a missing file"
has_out "path not found: src/nope.py" "flow citing a missing file"
lacks_out "path not found: src/app.py" "flow citing a missing file"

# Warnings: stderr, never a changed exit code. A pass with warnings says how many.
# rowof N: a table row of exactly N characters (code points)
rowof() { printf '|%s|' "$(printf '%*s' $(($1 - 2)) '' | tr ' ' x)"; }
D="$(fresh)"
atlas "$(rowof 141)" "" "" "" > "$D/ATLAS.md"
expect_ok "$D" "141-character row"
has_out "ATLAS-VALIDATE: warning: line 5: Where to Look row is 141 characters, keep it under 140" "141-character row"
has_out "ATLAS-VALIDATE: ATLAS.md OK, 1 warning(s)" "141-character row"
# exactly 140 characters with ten arrows (160 bytes): no warning, saved LF or CRLF
ARROWS="→→→→→→→→→→"
ROW140="|$(printf '%*s' 128 '' | tr ' ' x)$ARROWS|"
atlas "$ROW140" "" "" "" > "$D/ATLAS.md"
expect_ok "$D" "140-character row with arrows"
lacks_out "warning" "140-character row with arrows"
sed 's/$/\r/' "$D/ATLAS.md" > "$D/crlf.md"; mv "$D/crlf.md" "$D/ATLAS.md"
expect_ok "$D" "140-character CRLF row with arrows"
lacks_out "warning" "140-character CRLF row with arrows"
# 26 data rows warn, 25 don't
rows() { local i=1 r=""; while [ "$i" -le "$1" ]; do r="$r| intent $i | none | why |$NL"; i=$((i+1)); done; printf '%s' "${r%"$NL"}"; }
atlas "$(rows 26)" "" "" "" > "$D/ATLAS.md"
expect_ok "$D" "26 rows"
has_out "ATLAS-VALIDATE: warning: Where to Look has 26 rows, keep at most 25 (most useful first)" "26 rows"
atlas "$(rows 25)" "" "" "" > "$D/ATLAS.md"
expect_ok "$D" "25 rows"
lacks_out "Where to Look has" "25 rows"
# 📌 notes: 2 lines and 280 characters at most; the template comment is not a note
PIN="📌"
note_file() { atlas "" "" "" "" > "$D/ATLAS.md"; printf '%s\n' "$@" >> "$D/ATLAS.md"; }
note_file "- $PIN first" "  second" "  third"
expect_ok "$D" "3-line note"
has_out "📌 note is over its 2-line budget (lines: 3, characters:" "3-line note"
has_out "detail goes in a design doc" "3-line note"
note_file "$PIN$(printf '%*s' 299 '' | tr ' ' y)"
expect_ok "$D" "300-character note"
has_out "characters: 300)" "300-character note"
note_file "- $PIN short note" "- $PIN another" "<!-- $PIN-prefixed lines are manual notes, preserved across atlas updates -->"
expect_ok "$D" "short notes"
lacks_out "📌 note" "short notes"
note_file "$PIN two lines" "second line"
expect_ok "$D" "2-line note"
lacks_out "📌 note" "2-line note"
# size: over 20480 bytes warns, exit stays 0
atlas "" "" "" "" > "$D/ATLAS.md"
BASE="$(wc -c < "$D/ATLAS.md" | tr -d ' ')"
printf '%s\n' "$(printf '%*s' $((21000 - BASE - 1)) '' | tr ' ' z)" >> "$D/ATLAS.md"
[ "$(wc -c < "$D/ATLAS.md" | tr -d ' ')" = 21000 ] || { echo "    fixture isn't 21000 bytes"; exit 1; }
expect_ok "$D" "21000-byte atlas"
has_out "ATLAS.md is 21000 bytes, aim for 15–20 KB" "21000-byte atlas"
# the header-only fixture stays clean
D="$(fresh)"; printf '%s\n' "$HEADERS" > "$D/ATLAS.md"; expect_ok "$D" "header-only"
lacks_out "warning" "header-only"
has_out "ATLAS-VALIDATE: ATLAS.md OK" "header-only"
exit 0
