#!/usr/bin/env bash
# ABOUTME: The "where is X" check: atlas-symbols.sh where prints a symbol's definition and its callers by file, and a
# ABOUTME: committed ATLAS.md built from the fixture passes validate-atlas.sh. Deterministic: no eval, no token or call counts.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/atlas/atlas-symbols.sh"
assert_file "$S" || exit 1

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null 2>/dev/null || true
F="$TMP/repo"
git init -q "$F"
git -C "$F" config user.name Fixture
git -C "$F" config user.email fixture@example.com
put() { mkdir -p "$F/$(dirname "$1")"; printf '%s\n' "$2" > "$F/$1"; }

put src/orders/parse.py "$(printf '# parser\nimport re\ndef parse_order(raw):\n    return re.split(",", raw)')"
put src/api/routes.py "$(printf '%s\n' 'import parse' '' '' '' '' '' '' '    order = parse_order(raw)' '' '' '' '' 'x = 1' '    return parse_order(retry)')"
LINES=""; i=1; while [ "$i" -lt 20 ]; do LINES="$LINES"$'\n'"pass"; i=$((i+1)); done
put src/jobs/import.py "$(printf 'import parse%s\nrows = [parse_order(r) for r in batch]' "$LINES")"
git -C "$F" add -A && git -C "$F" commit -q -m fixture

for MODE in ATLAS_SYMBOLS_NO_PYTHON=1 ATLAS_SYMBOLS_UNUSED=1; do
OUT="$(cd "$F" && env "$MODE" bash "$S" where parse_order 2>&1)"; RC=$?
[ "$RC" = 0 ] || { echo "    where parse_order exited $RC: $OUT"; exit 1; }
EXPECTED="$(printf '%s\n' 'defined in:' '  src/orders/parse.py:3 (function)' 'callers (3 in 2 files):' 'src/api/routes.py' \
    '  8: order = parse_order(raw)' '  14: return parse_order(retry)' 'src/jobs/import.py' '  21: rows = [parse_order(r) for r in batch]')"
[ "$OUT" = "$EXPECTED" ] || { echo "    unexpected where output:"; printf '%s\n' "$OUT" | sed 's/^/      /'; exit 1; }
printf '%s\n' "$OUT" | sed -n '/^callers/,$p' | grep -q 'def parse_order' && { echo "    the definition line is listed as a caller"; exit 1; }
done

# The fixture's committed ATLAS.md, with Key Symbols counted by `top` and the footer at HEAD, passes the validator
V="$PLUGIN_DIR/skills/atlas/validate-atlas.sh"
assert_file "$V" || exit 1
REFS="$(cd "$F" && ATLAS_SYMBOLS_NO_PYTHON=1 bash "$S" top 30 | awk -F'\t' '$2 == "parse_order" { print $1 }')"
[ -n "$REFS" ] || { echo "    top didn't rank parse_order"; exit 1; }
SHA="$(git -C "$F" rev-parse HEAD)"
{
    printf '%s\n' '# ATLAS — Fixture' '' '## Where to Look' '| I want to... | Open | Why |' '|---|---|---|' \
        '| parse an order | `src/orders/parse.py` | the parser |' '' \
        '## Entry Points' '| File | Role | Starts |' '|---|---|---|' '| `src/api/routes.py` | API | routes |' '' \
        '## Key Flows' '- order: `src/api/routes.py` → `src/orders/parse.py`' '' \
        '## Module Map' '| Directory | Purpose | Key files |' '|---|---|---|' '| `src/orders/` | orders | `src/orders/parse.py` |' '' \
        '## Key Symbols' '| Symbol | File | Kind | Refs |' '|---|---|---|---|'
    printf '| `parse_order` | `src/orders/parse.py` | function | %s |\n' "$REFS"
    printf '%s\n' '' '## Integration Points' '| System | Config key | Path |' '|---|---|---|' '' '## Conventions & Gotchas' '' "<!-- atlas-sha:$SHA -->"
} > "$F/ATLAS.md"
git -C "$F" add ATLAS.md && git -C "$F" commit -q -m atlas
VOUT="$(cd "$F" && bash "$V" ATLAS.md 2>&1)" || { echo "    validate-atlas.sh rejected the fixture's ATLAS.md: $VOUT"; exit 1; }
exit 0
