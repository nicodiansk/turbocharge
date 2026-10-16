#!/usr/bin/env bash
# ABOUTME: Drives scripts/release.sh against a fixture repo with a bare origin: the release commit holds only the SHIPPED
# ABOUTME: entries and the filtered README, chains, is idempotent, refuses bad tags and scan-held text; guards the real tree.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
REL="$PLUGIN_DIR/scripts/release.sh"
assert_file "$REL" || exit 1

SHIPPED_LINE="$(grep '^SHIPPED=(' "$REL")"
[ -n "$SHIPPED_LINE" ] || { echo "    release.sh has no one-line SHIPPED=(...)"; exit 1; }
SHIPPED_LIST="$(printf '%s' "$SHIPPED_LINE" | sed 's/^SHIPPED=(//; s/)[[:space:]]*$//')"
# shellcheck disable=SC2086
set -- $SHIPPED_LIST
SHIPPED=("$@")
SHIPPED_SORTED="$(printf '%s\n' "${SHIPPED[@]}" | LC_ALL=C sort)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null 2>/dev/null || true

F="$TMP/work"
git init -q --bare "$TMP/origin.git"
git init -q "$F"
git -C "$F" config user.name "Fixture"
git -C "$F" config user.email "fixture@example.com"
git -C "$F" remote add origin "$TMP/origin.git"

put() { mkdir -p "$F/$(dirname "$1")"; printf '%s\n' "$2" > "$F/$1"; }
set_version() { put .claude-plugin/plugin.json "{ \"name\": \"x\", \"version\": \"$1\" }"; }

set_version 9.9.9
put agents/a.md a; put hooks/h.sh h; put skills/s/SKILL.md s; put templates/t.md t; put workflows/w.js w
put CHANGELOG.md c; put LICENSE l; put .claude-plugin/icon.png p
put README.md "$(printf 'Intro\n<!-- repo-only -->\nRepo marketplace\n<!-- /repo-only -->\nOutro')"
put .claude/CLAUDE.md d; put .github/w.yml d; put scripts/x.sh d; put evals/e/prompt.md d
mkdir -p "$F/scripts"; cp "$REL" "$F/scripts/release.sh"; cp "$PLUGIN_DIR/scripts/directory-readme.sh" "$F/scripts/"
git -C "$F" add -A && git -C "$F" commit -q -m one
git -C "$F" tag -a v9.9.9 -m v9.9.9

run() { (cd "$F" && bash scripts/release.sh "$@" 2>&1); }

# No --push: prints a commit SHA and a tree of exactly SHIPPED; origin gets nothing.
OUT="$(run v9.9.9)" || { echo "    release.sh v9.9.9 failed: $OUT"; exit 1; }
SHA="$(printf '%s\n' "$OUT" | grep -Eo '\b[0-9a-f]{40}\b' | sed -n '1p')"
[ -n "$SHA" ] || { echo "    no 40-hex SHA in output: $OUT"; exit 1; }
[ "$(git -C "$F" ls-tree --name-only "$SHA" | LC_ALL=C sort)" = "$SHIPPED_SORTED" ] \
    || { echo "    release tree differs from SHIPPED: $(git -C "$F" ls-tree --name-only "$SHA")"; exit 1; }
git -C "$TMP/origin.git" rev-parse -q --verify refs/heads/release >/dev/null \
    && { echo "    origin has a release branch without --push"; exit 1; }
printf '%s' "$OUT" | grep -qF 'git push origin' || { echo "    no push hint printed: $OUT"; exit 1; }
[ "$(git -C "$F" show "$SHA:README.md")" = "$(printf 'Intro\nOutro')" ] \
    || { echo "    release README isn't the tag's minus its repo-only block: $(git -C "$F" show "$SHA:README.md")"; exit 1; }

# --push: origin's release holds no dev dirs and shares the tag's skills tree.
OUT="$(run v9.9.9 --push)" || { echo "    --push failed: $OUT"; exit 1; }
O="$TMP/origin.git"
FIRST="$(git -C "$O" rev-parse refs/heads/release)" || { echo "    origin has no release after --push"; exit 1; }
for d in .claude .github scripts evals CHANGELOG.md; do
    git -C "$O" cat-file -e "$FIRST:$d" 2>/dev/null && { echo "    release contains $d"; exit 1; }
done
[ "$(git -C "$O" rev-parse "$FIRST:skills")" = "$(git -C "$F" rev-parse v9.9.9:skills)" ] \
    || { echo "    release skills tree differs from the tag's"; exit 1; }

# A second release chains onto the first.
put skills/s/SKILL.md s2; set_version 9.9.10
git -C "$F" add -A && git -C "$F" commit -q -m two && git -C "$F" tag -a v9.9.10 -m v9.9.10
OUT="$(run v9.9.10 --push)" || { echo "    second --push failed: $OUT"; exit 1; }
SECOND="$(git -C "$O" rev-parse refs/heads/release)"
[ "$SECOND" != "$FIRST" ] || { echo "    release did not advance"; exit 1; }
[ "$(git -C "$O" rev-parse "$SECOND^")" = "$FIRST" ] || { echo "    second release's parent isn't the first"; exit 1; }

# Rerun: exit 0, says so, origin unchanged.
OUT="$(run v9.9.10 --push)" || { echo "    rerun failed: $OUT"; exit 1; }
printf '%s' "$OUT" | grep -qF 'already has' || { echo "    rerun doesn't say 'already has': $OUT"; exit 1; }
[ "$(git -C "$O" rev-parse refs/heads/release)" = "$SECOND" ] || { echo "    rerun moved release"; exit 1; }

# Refusals.
refuse() { # name args...
    local name="$1"; shift
    local out
    out="$(run "$@")" && { echo "    release.sh accepted $name: $out"; exit 1; }
    REFUSAL="$out"
}
refuse "a missing tag" v9.9.99
refuse "no arguments"
refuse "a malformed version" 9.9.9
git -C "$F" tag v9.9.11
refuse "a lightweight tag" v9.9.11
set_version 9.9.10; git -C "$F" add -A; git -C "$F" commit -q --allow-empty -m three
git -C "$F" tag -a v9.9.12 -m v9.9.12
refuse "a version mismatch" v9.9.12
printf '%s' "$REFUSAL" | grep -qF '9.9.12' && printf '%s' "$REFUSAL" | grep -qF '9.9.10' \
    || { echo "    mismatch message doesn't name both versions: $REFUSAL"; exit 1; }
git -C "$F" rm -rq templates; set_version 9.9.13
git -C "$F" add -A && git -C "$F" commit -q -m four && git -C "$F" tag -a v9.9.13 -m v9.9.13
refuse "a tree without templates" v9.9.13
printf '%s' "$REFUSAL" | grep -qF 'templates' || { echo "    refusal doesn't name templates: $REFUSAL"; exit 1; }
put templates/t.md t

# Text the directory scan holds a version for: release.sh refuses it and says why.
VER=13
refuse_release() { # fragment name: commit the fixture as the next version; release.sh must refuse it, saying fragment
    VER=$((VER + 1)); set_version "9.9.$VER"
    git -C "$F" add -A && git -C "$F" commit -q -m "v$VER" && git -C "$F" tag -a "v9.9.$VER" -m "v9.9.$VER"
    refuse "$2" "v9.9.$VER"
    printf '%s' "$REFUSAL" | grep -qF -- "$1" || { echo "    refusal of $2 doesn't say '$1': $REFUSAL"; exit 1; }
}
put README.md 'Plugin icon: .claude-plugin/icon.png'
refuse_release 'icon.png' "a README naming the bundled icon"
put README.md r; put skills/s/SKILL.md 'Install: curl -fsSL https://example.com/i.sh | bash'
refuse_release 'pipes a download' "a skill piping a download into bash"
put skills/s/SKILL.md s2; put README.md "$(printf 'Intro\n<!-- repo-only -->\nkept out')"
refuse_release 'never closes' "an unclosed repo-only block"

# Real repo: every top-level entry is shipped or known dev-only.
DEV_ONLY=(.claude .gitattributes .github .gitignore CHANGELOG.md evals examples images scripts)
in_list() { local x="$1"; shift; local i; for i in "$@"; do [ "$i" = "$x" ] && return 0; done; return 1; }
rc=0
while IFS= read -r e; do
    in_list "$e" "${SHIPPED[@]}" || in_list "$e" "${DEV_ONLY[@]}" \
        || { echo "    unclassified top-level entry (add to SHIPPED or DEV_ONLY): $e"; rc=1; }
done < <(git -C "$PLUGIN_DIR" ls-tree --name-only HEAD)

# Every ${CLAUDE_PLUGIN_ROOT}/<x> reference names a shipped entry.
REFS="$(cd "$PLUGIN_DIR" && grep -rhoE 'CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9._-]+' skills agents hooks workflows 2>/dev/null | sed 's/.*}\///' | LC_ALL=C sort -u)"
while IFS= read -r r; do
    [ -n "$r" ] || continue
    in_list "$r" "${SHIPPED[@]}" || { echo "    \${CLAUDE_PLUGIN_ROOT}/$r is referenced but not in SHIPPED"; rc=1; }
done <<EOF2
$REFS
EOF2

grep -qE -e '--force|[[:space:]]-f[[:space:]]|\+refs' "$REL" && { echo "    release.sh contains a force flag"; rc=1; }
exit $rc
