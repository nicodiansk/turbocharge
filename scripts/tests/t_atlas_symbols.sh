#!/usr/bin/env bash
# ABOUTME: Drives skills/atlas/atlas-symbols.sh against a fixture git repo: definitions by regex per language,
# ABOUTME: ranked by references, with dunder and short names dropped, ATLAS.md left out of the count, and bad input refused.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/atlas/atlas-symbols.sh"
assert_file "$S" || exit 1
bash -n "$S" || { echo "    syntax error"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null 2>/dev/null || true
F="$TMP/repo"
git init -q "$F"
git -C "$F" config user.name Fixture
git -C "$F" config user.email fixture@example.com
put() { mkdir -p "$F/$(dirname "$1")"; printf '%s\n' "$2" > "$F/$1"; }

put src/orders.py "$(printf 'def parse_order(raw):\n    return raw\n\nclass OrderBook:\n    pass')"
put src/api.py "$(printf 'x = parse_order(1)\ny = parse_order(2)')"
put src/jobs.py 'z = parse_order(3)'
put src/other.py 'w = parse_order(4)'
put web/cart.ts "$(printf 'export function addToCart(x) {}\nexport const CART_LIMIT = 5\ninterface Cart {}')"
put web/page.ts "$(printf 'addToCart(1)\nif (n > CART_LIMIT) {}')"
put cmd/main.go "$(printf 'package main\nfunc RunServer() {}')"
put bin/tool.sh "$(printf '#!/usr/bin/env bash\ndeploy_all() {\n  echo hi\n}')"
put src/small.py "$(printf 'def ab():\n    pass\nclass K:\n    def __init__(self):\n        pass')"
put src/a.py 'def helper(): pass'
put lib/b.py 'def helper(): pass'
put src/use.py 'helper()'
git -C "$F" add -A && git -C "$F" commit -q -m fixture

top() { (cd "$F" && ATLAS_SYMBOLS_NO_PYTHON=1 bash "$S" top "$@" 2>&1); }
TAB="$(printf '\t')"
OUT="$(top)" || { echo "    top failed: $OUT"; exit 1; }
has() { printf '%s\n' "$OUT" | grep -qxF "$1" || { echo "    missing row: $1"; printf '%s\n' "$OUT" | sed 's/^/      /'; return 1; }; }

has "4${TAB}parse_order${TAB}function${TAB}src/orders.py" || exit 1
has "1${TAB}addToCart${TAB}function${TAB}web/cart.ts" || exit 1
L1="$(printf '%s\n' "$OUT" | grep -n "${TAB}parse_order${TAB}" | cut -d: -f1)"
L2="$(printf '%s\n' "$OUT" | grep -n "${TAB}addToCart${TAB}" | cut -d: -f1)"
[ -n "$L1" ] && [ -n "$L2" ] && [ "$L1" -lt "$L2" ] || { echo "    parse_order isn't ranked above addToCart ($L1 vs $L2)"; exit 1; }

# Kinds across languages
printf '%s\n' "$OUT" | grep -qE "${TAB}CART_LIMIT${TAB}const${TAB}web/cart.ts\$" || { echo "    CART_LIMIT isn't a const row"; exit 1; }
printf '%s\n' "$OUT" | grep -qE "${TAB}Cart${TAB}type${TAB}web/cart.ts\$" || { echo "    Cart isn't a type row"; exit 1; }
printf '%s\n' "$OUT" | grep -qE "${TAB}RunServer${TAB}function${TAB}cmd/main.go\$" || { echo "    RunServer isn't a function row"; exit 1; }
printf '%s\n' "$OUT" | grep -qE "${TAB}deploy_all${TAB}function${TAB}bin/tool.sh\$" || { echo "    deploy_all isn't a function row"; exit 1; }
printf '%s\n' "$OUT" | grep -qE "${TAB}OrderBook${TAB}class${TAB}src/orders.py\$" || { echo "    OrderBook isn't a class row"; exit 1; }

# Short and dunder names dropped
printf '%s\n' "$OUT" | grep -qE "${TAB}(ab|__init__)${TAB}" && { echo "    short or dunder name listed"; exit 1; }

# Same name in two files: two rows, equal refs
H="$(printf '%s\n' "$OUT" | grep "${TAB}helper${TAB}")"
[ "$(printf '%s\n' "$H" | wc -l | tr -d ' ')" = 2 ] || { echo "    helper should have two rows: $H"; exit 1; }
[ "$(printf '%s\n' "$H" | cut -f1 | sort -u | wc -l | tr -d ' ')" = 1 ] || { echo "    helper rows have different refs: $H"; exit 1; }

# ATLAS.md citing CART_LIMIT leaves the count alone
BEFORE="$(printf '%s\n' "$OUT" | grep "${TAB}CART_LIMIT${TAB}")"
put ATLAS.md '| `CART_LIMIT` | web/cart.ts | const | 9 |  CART_LIMIT CART_LIMIT'
git -C "$F" add ATLAS.md && git -C "$F" commit -q -m atlas
OUT="$(top)"
AFTER="$(printf '%s\n' "$OUT" | grep "${TAB}CART_LIMIT${TAB}")"
[ "$BEFORE" = "$AFTER" ] || { echo "    ATLAS.md changed CART_LIMIT refs: '$BEFORE' vs '$AFTER'"; exit 1; }

# top N
[ "$(top 2 | wc -l | tr -d ' ')" = 2 ] || { echo "    top 2 should print exactly 2 lines"; exit 1; }
top x >/dev/null; [ $? = 2 ] || { echo "    top x should exit 2"; exit 1; }
top 0 >/dev/null; [ $? = 2 ] || { echo "    top 0 should exit 2"; exit 1; }
(cd "$F" && bash "$S" bogus >/dev/null 2>&1); [ $? = 2 ] || { echo "    unknown command should exit 2"; exit 1; }

# Outside a git repository
mkdir -p "$TMP/plain"
ERR="$(cd "$TMP/plain" && bash "$S" top 2>&1 >/dev/null)"; RC=$?
[ "$RC" = 2 ] || { echo "    non-git dir should exit 2, got $RC"; exit 1; }
printf '%s' "$ERR" | grep -q 'git repository' || { echo "    stderr lacks 'git repository': $ERR"; exit 1; }
exit 0
