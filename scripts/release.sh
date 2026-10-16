#!/usr/bin/env bash
# ABOUTME: Builds the directory's `release` commit from an annotated vX.Y.Z tag: the plugin's files as the directory copy
# ABOUTME: (filtered markdown, no exit gate or review workflow), chained onto origin's release. --push plain-pushes it.
set -euo pipefail

SHIPPED=(.claude-plugin agents hooks skills templates workflows LICENSE README.md)
# The directory copy leaves out the builder exit gate and the review workflow; repo installs keep both. The directory
# holds every update that adds hook events over the live version ("Update adds hooks"), and most directory installs run
# where hooks are ignored. It held 3.5.0 to 3.5.2 for "Update adds credential forward", and the workflow is the only code
# those added over the live 2.8.1; without it, review runs one code-reviewer.
DIRECTORY_DROP=(hooks/builder-exit-gate.sh workflows/review-swarm.js)
DIRECTORY_HOOKS_JQ='del(.hooks.SubagentStop, .hooks.PreToolUse)'
HOOKS_REPO='2 hooks'
HOOKS_DIRECTORY='1 hook'
WORKFLOWS_REPO='1 workflow'

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

command -v jq >/dev/null 2>&1 || die "jq is required to build the directory's hooks/hooks.json"
[ -n "$(g ls-tree --name-only "$TAG_TREE" -- hooks/hooks.json)" ] || die "hooks/hooks.json is missing from $TAG's tree"

# Build the directory copy in a scratch index: the tag's SHIPPED files, then the directory's changes on top.
IDX_DIR="$(mktemp -d)"
trap 'rm -rf "$IDX_DIR"' EXIT
gi() { GIT_INDEX_FILE="$IDX_DIR/index" g "$@"; }
put() { local blob; blob="$(g hash-object -w --stdin)" && gi update-index --add --cacheinfo "100644,$blob,$1"; }
g ls-tree -r "$TAG_TREE" -- "${SHIPPED[@]}" \
    | awk -F'\t' -v drop="${DIRECTORY_DROP[*]}" 'BEGIN { n = split(drop, d, " "); for (i = 1; i <= n; i++) left_out[d[i]] = 1 }
                                              !($2 in left_out)' \
    | gi update-index --add --index-info

# scan prints git grep's matches (none is fine) and fails only when git grep itself fails.
scan() { local out rc=0; out="$(g grep "$@" 2>&1)" || rc=$?; [ "$rc" -le 1 ] || die "git grep failed ($rc): $out"; printf '%s' "$out"; }

MARKED="$(scan -lF -e '<!-- repo-only -->' -e '<!-- directory-only' "$TAG_TREE" -- "${SHIPPED[@]}")"
for f in $MARKED; do
    f="${f#*:}"
    g show "$TAG:$f" | bash "$ROOT/scripts/directory-filter.sh" | put "$f" || die "could not filter $f"
done
g show "$TAG:hooks/hooks.json" | jq --indent 2 "$DIRECTORY_HOOKS_JQ" | put hooks/hooks.json || die "could not trim hooks/hooks.json"
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
    [ -n "$(gi ls-files -- "$f")" ] || continue
    g show "$TAG:$f" | sed -e "s/$HOOKS_REPO/$HOOKS_DIRECTORY/g" -e "s/, $WORKFLOWS_REPO//g" | put "$f" \
        || die "could not update the hook and workflow counts in $f"
done
TREE="$(gi write-tree)"

# What the directory scan holds a version for: shipped text naming a bundled image or font, or fetch-and-run.
ASSETS="$(g ls-tree -r --name-only "$TREE" | sed -n -E 's#^(.*/)?([^/]+\.(png|jpe?g|gif|webp|ico|svg|woff2?|ttf|otf))$#\2#p')"
for a in $ASSETS; do
    HITS="$(scan -lF -e "$a" "$TREE" -- . ":(exclude)*$a")"
    [ -z "$HITS" ] || die "shipped text names the bundled $a, which the directory scan holds for review: $HITS"
done
HITS="$(scan -nEi -e '(curl|wget)[^|]*[|][[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh([^[:alnum:]]|$)' "$TREE")"
[ -z "$HITS" ] || die "shipped text pipes a download into a shell: $HITS"
HITS="$(scan -nF -e 'repo-only -->' -e '<!-- directory-only' "$TREE")"
[ -z "$HITS" ] || die "a repo-only or directory-only marker reached the release tree: $HITS"
for f in "${DIRECTORY_DROP[@]}"; do
    name="${f##*/}"
    HITS="$(scan -nF -e "${name%.*}" "$TREE")"
    [ -z "$HITS" ] || die "the directory copy leaves out $f but still names it: $HITS"
done
HITS="$(scan -nF -e "$HOOKS_REPO" "$TREE")"
[ -z "$HITS" ] || die "the directory copy has $HOOKS_DIRECTORY but still says $HOOKS_REPO: $HITS"
HITS="$(scan -nF -e "$WORKFLOWS_REPO" "$TREE")"
[ -z "$HITS" ] || die "the directory copy leaves out the review workflow but still says $WORKFLOWS_REPO: $HITS"

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
