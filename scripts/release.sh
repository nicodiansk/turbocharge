#!/usr/bin/env bash
# ABOUTME: Builds the directory's `release` commit from an annotated vX.Y.Z tag: only the plugin's files, README
# ABOUTME: filtered by directory-readme.sh, chained onto origin's release. With --push, plain-pushes it (never rewrites).
set -euo pipefail

SHIPPED=(.claude-plugin agents hooks skills templates workflows LICENSE README.md)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
g() { git -C "$ROOT" "$@"; }
die() { echo "release.sh: $*" >&2; exit 1; }

PUSH=0
if [ "$#" -eq 2 ] && [ "$2" = "--push" ]; then PUSH=1
elif [ "$#" -ne 1 ]; then die "usage: scripts/release.sh vX.Y.Z [--push]"; fi
TAG="$1"
printf '%s' "$TAG" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$' || die "version must look like vN.N.N, got '$TAG'"
VERSION="${TAG#v}"

g rev-parse -q --verify "refs/tags/$TAG" >/dev/null || die "tag $TAG does not exist"
[ "$(g cat-file -t "refs/tags/$TAG")" = "tag" ] || die "tag $TAG is not annotated (create it with git tag -a)"

TAG_VERSION="$(g show "$TAG:.claude-plugin/plugin.json" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p;' | sed -n '1p')"
[ "$TAG_VERSION" = "$VERSION" ] || die "tag $TAG says $VERSION but its .claude-plugin/plugin.json version is '$TAG_VERSION'"

TAG_TREE="$TAG^{tree}"
for entry in "${SHIPPED[@]}"; do
    [ -n "$(g ls-tree --name-only "$TAG_TREE" -- "$entry")" ] || die "$entry is missing from $TAG's tree"
done

# The directory copy's README drops the repo-only blocks (images, the repo marketplace, CI, project layout).
README_BLOB="$(g show "$TAG:README.md" | bash "$ROOT/scripts/directory-readme.sh" | g hash-object -w --stdin)" \
    || die "could not filter $TAG's README.md"
TREE="$(g ls-tree "$TAG_TREE" -- "${SHIPPED[@]}" \
    | awk -F'\t' -v b="$README_BLOB" '{ split($1, m, " "); if ($2 == "README.md") m[3] = b; print m[1] " " m[2] " " m[3] "\t" $2 }' \
    | g mktree)"

# What the directory scan holds a version for: shipped text naming a bundled image or font, or fetch-and-run.
# scan prints git grep's matches in the release tree (none is fine) and fails only when git grep itself fails.
scan() { local out rc=0; out="$(g grep "$@" 2>&1)" || rc=$?; [ "$rc" -le 1 ] || die "git grep failed ($rc): $out"; printf '%s' "$out"; }
ASSETS="$(g ls-tree -r --name-only "$TREE" | sed -n -E 's#^(.*/)?([^/]+\.(png|jpe?g|gif|webp|ico|svg|woff2?|ttf|otf))$#\2#p')"
for a in $ASSETS; do
    HITS="$(scan -lF -e "$a" "$TREE" -- . ":(exclude)*$a")"
    [ -z "$HITS" ] || die "shipped text names the bundled $a, which the directory scan holds for review: $HITS"
done
HITS="$(scan -nEi -e '(curl|wget)[^|]*[|][[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh([^[:alnum:]]|$)' "$TREE")"
[ -z "$HITS" ] || die "shipped text pipes a download into a shell: $HITS"
HITS="$(scan -nF -e 'repo-only -->' "$TREE")"
[ -z "$HITS" ] || die "a repo-only marker reached the release tree: $HITS"

TAG_COMMIT="$(g rev-parse "$TAG^{commit}")"

PARENT=""
rc=0
g ls-remote --exit-code --heads origin release >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 0 ]; then
    g fetch -q origin refs/heads/release
    PARENT="$(g rev-parse FETCH_HEAD)"
    if [ "$(g rev-parse "$PARENT^{tree}")" = "$TREE" ]; then
        echo "release already has $TAG's files ($PARENT)"
        exit 0
    fi
elif [ "$rc" -ne 2 ]; then
    die "could not reach origin to look for the release branch (git ls-remote exit $rc)"
fi

LIST="${SHIPPED[*]}"
LIST="${LIST// /, }"
if [ -n "$PARENT" ]; then
    COMMIT="$(g commit-tree "$TREE" -p "$PARENT" -m "release $TAG" -m "Trimmed from $TAG_COMMIT: $LIST.")"
else
    COMMIT="$(g commit-tree "$TREE" -m "release $TAG" -m "Trimmed from $TAG_COMMIT: $LIST.")"
fi

echo "$COMMIT"
g ls-tree --name-only "$COMMIT"

if [ "$PUSH" -eq 1 ]; then
    g push origin "$COMMIT:refs/heads/release"
else
    echo "To publish: git push origin $COMMIT:refs/heads/release"
fi
