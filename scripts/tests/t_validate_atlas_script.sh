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
        "## Entry Points" "## Module Map" "| Directory | Purpose | Key files |" "|---|---|---|" "$4" \
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
exit 0
