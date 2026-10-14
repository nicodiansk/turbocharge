#!/usr/bin/env bash
# ABOUTME: Builds the directory's `release` commit from an annotated vX.Y.Z tag: only the plugin's files, chained
# ABOUTME: onto origin's release branch. Prints the commit; with --push, plain-pushes it (never rewrites history).
set -euo pipefail

SHIPPED=(.claude-plugin agents hooks skills templates workflows CHANGELOG.md LICENSE README.md)

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

TREE="$(g ls-tree "$TAG_TREE" -- "${SHIPPED[@]}" | g mktree)"
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
