#!/usr/bin/env bash
# ABOUTME: Tests that session-start.sh lists the ATLAS.md lines whose cited files changed since its atlas-sha commit.
# ABOUTME: Covers edits, uncited changes, directory citations, renames, unknown or hand-edited footers, non-git dirs.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
assert_file "$F" || exit 1
bash -n "$F" || exit 1

TMP="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
fail() { echo "    $1"; exit 1; }
g() { git -c user.name=t -c user.email=t@t "$@"; }

# new_repo DIR FOOTER_FN — a repo with src/a.py (cited on line 7 of ATLAS.md) and notes.txt; footer is the first commit.
new_repo() {
    mkdir -p "$1/src/b" && cd "$1" || exit 1
    g init -q . && echo a > src/a.py && echo n > notes.txt && echo b > src/b/old.py
    g add -A && g commit -q -m one
    SHA1="$(g rev-parse HEAD)"
    write_atlas "<!-- atlas-sha:$SHA1 -->"
}
write_atlas() {
    cat > ATLAS.md <<EOF2
# ATLAS — Fixture

## Where to Look

| I want to... | Open | Why |
|--------------|------|-----|
| Run the app | \`src/a.py\` | entry |
| Browse b | \`src/b/\` | dir |

$1
EOF2
}
run() { bash "$F" 2>&1; }

new_repo "$TMP/edit"
echo changed >> src/a.py; g commit -q -am two
BEFORE="$(git status --porcelain)"
OUT="$(run)"
[ "$BEFORE" = "$(git status --porcelain)" ] || fail "the hook changed the work tree"
echo "$OUT" | grep -q "may be stale" || fail "edit of a cited file: no 'may be stale'"
echo "$OUT" | grep -q "line 7: src/a.py" || fail "edit of a cited file: no 'line 7: src/a.py'"

new_repo "$TMP/uncited"
echo more >> notes.txt; g commit -q -am two
run | grep -q "stale" && fail "an uncited change was reported"

new_repo "$TMP/dir"
echo new > src/b/new.py; g add -A; g commit -q -m two
run | grep -q "line 8: src/b/" || fail "a new file under a cited directory was not reported"

new_repo "$TMP/rename"
g mv src/a.py src/z.py; g commit -q -m two
run | grep -q "line 7: src/a.py" || fail "a renamed cited file's old path was not reported (needs --no-renames)"

new_repo "$TMP/unknown"
write_atlas "<!-- atlas-sha:$(printf 'deadbeef%.0s' 1 2 3 4 5) -->"
run | grep -q "a commit this clone doesn't have" || fail "unknown sha: no 'a commit this clone doesn't have'"

new_repo "$TMP/oldhash"
write_atlas "<!-- atlas-hash:000000000000 -->"
run | grep -q "pre-3.8 atlas-hash footer" || fail "atlas-hash footer: no 'pre-3.8 atlas-hash footer'"

new_repo "$TMP/evil"
write_atlas "<!-- atlas-sha:--output=x -->"
OUT="$(run)"
echo "$OUT" | grep -qE "stale|commit this clone" && fail "a hand-edited footer produced a staleness line"
[ -e x ] && fail "a hand-edited footer created a file"

mkdir -p "$TMP/nogit" && cd "$TMP/nogit" || exit 1
write_atlas "<!-- atlas-sha:abcdef0 -->"
OUT="$(run)"; RC=$?
echo "$OUT" | grep -qE "stale|commit this clone" && fail "a non-git dir produced a staleness line"
[ "$RC" -eq 0 ] || fail "non-git dir: exit $RC"
exit 0
