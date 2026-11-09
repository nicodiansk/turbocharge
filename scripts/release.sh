#!/usr/bin/env bash
# ABOUTME: Builds the directory's `release` commit from an annotated vX.Y.Z tag: the plugin's files as the directory copy
# ABOUTME: (filtered markdown, allowed file types, trimmed frontmatter, no hooks or review workflow, user-only ship), chained onto
# ABOUTME: origin's release. --push plain-pushes it.
set -euo pipefail

SHIPPED=(.claude-plugin agents hooks skills templates workflows LICENSE NOTICE README.md)
# The directory copy holds no hooks and no review workflow; repo installs keep both. The directory refused 3.5.7 with
# LOCAL_CODE_HOOK_COMMAND: it accepts command hooks only from Verified organizations, and SessionStart takes only command
# and mcp_tool hooks, so the bootstrap can't become a prompt hook. The workflow is the one other piece of code the listing
# held for (3.5.0 to 3.5.2, "Update adds credential forward"); without it, review runs one code-reviewer.
# From a non-Verified organization the directory takes only Markdown, text, JSON, YAML and images, nothing that starts
# with #!, and no package manager configuration: it refused 3.5.8 with LOCAL_CODE_FILE_TYPE (count 2) for the debug
# skill's bisection script and TypeScript example, so the copy leaves both out.
# An entry drops that path and everything under it.
DIRECTORY_DROP=(hooks workflows/review-swarm.js skills/debug/find-polluter.sh skills/debug/condition-based-waiting-example.ts)
ALLOWED_EXT_RE='[.](md|txt|json|yaml|yml|png|jpg|jpeg|gif|webp|ico)$'
ALLOWED_PLAIN=(LICENSE NOTICE .gitignore)
IMAGE_EXT_RE='[.](png|jpg|jpeg|gif|webp|ico)$'
PACKAGE_CONFIG_RE='^(package[.]json|composer[.]json|bower[.]json|deno[.]jsonc?|deno[.]lock|pubspec[.]yaml|pubspec[.]lock|package-lock[.]json|npm-shrinkwrap[.]json|pnpm-workspace[.]yaml|pnpm-lock[.]yaml|yarn[.]lock|[.]npmrc|[.]yarnrc|[.]yarnrc[.]yml|bunfig[.]toml|bun[.]lockb?|uv[.]toml|pyproject[.]toml|requirements[.]txt|Pipfile|Pipfile[.]lock|poetry[.]lock|Gemfile|Gemfile[.]lock|go[.]mod|go[.]sum|Cargo[.]toml|Cargo[.]lock)$'
# The directory also takes frontmatter keys outside an allowed list only from Verified organizations: it refused 3.5.8
# with LOCAL_CODE_FRONTMATTER_KEY (count 10). The list isn't public. The copy drops these keys, with their values, from
# every skill and agent: the plugin works without them (no agent memory, no turn caps, the builder's default cache,
# a plan that runs in the background).
DIRECTORY_STRIP_KEYS=(memory maxTurns background experimental)
COMPONENT_DIRS=(agents skills commands output-styles)
# 3.5.9 dropped those four and still got LOCAL_CODE_FRONTMATTER_KEY with count 2. Three groups make exactly 2: the
# tools: allowlists of builder and planner (they grant Bash, Edit and Write), disable-model-invocation on setup and ship,
# and plan's context and agent. In the copy, an agent's tools: allowlist becomes this denylist (no Agent, so no nested
# spawn), and setup is model-invocable while ship stays user-only. 3.5.10's count says which group it was: 0 is tools,
# 1 is disable-model-invocation (ship keeps it), 2 is neither.
DIRECTORY_TOOLS_DENY='Agent, NotebookEdit, WebFetch, WebSearch'
DIRECTORY_MODEL_INVOCABLE=(skills/setup/SKILL.md)
GUARD_KEYS=("${DIRECTORY_STRIP_KEYS[@]}" tools)
HOOKS_REPO='2 hooks'
HOOK_COUNT_RE='(^|[^[:alnum:]])[0-9]+ hooks?([^[:alnum:]]|$)'
WORKFLOWS_REPO='1 workflow'
# The directory copy keeps these skills user-only: only the user starts them, Claude can't. Ship pushes and opens PRs with
# the user's git and GitHub CLI setup; it was user-only in 2.8.1 and 3.3.0 too. 3.5.5 tested it against the directory's
# credential-forward hold, which stayed.
DIRECTORY_USER_ONLY=(skills/ship/SKILL.md)
USER_ONLY_FLAG='disable-model-invocation: true'

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

# Build the directory copy in a scratch index: the tag's SHIPPED files, then the directory's changes on top.
IDX_DIR="$(mktemp -d)"
trap 'rm -rf "$IDX_DIR"' EXIT
gi() { GIT_INDEX_FILE="$IDX_DIR/index" g "$@"; }
put() { local blob; blob="$(g hash-object -w --stdin)" && gi update-index --add --cacheinfo "100644,$blob,$1"; }
g ls-tree -r "$TAG_TREE" -- "${SHIPPED[@]}" \
    | awk -F'\t' -v drop="${DIRECTORY_DROP[*]}" 'BEGIN { n = split(drop, d, " ") }
                                              { keep = 1; for (i = 1; i <= n; i++) if ($2 == d[i] || index($2, d[i] "/") == 1) keep = 0 }
                                              keep' \
    | gi update-index --add --index-info

# scan prints git grep's matches (none is fine) and fails only when git grep itself fails.
scan() { local out rc=0; out="$(g grep "$@" 2>&1)" || rc=$?; [ "$rc" -le 1 ] || die "git grep failed ($rc): $out"; printf '%s' "$out"; }

MARKED="$(scan -lF -e '<!-- repo-only -->' -e '<!-- directory-only' "$TAG_TREE" -- "${SHIPPED[@]}")"
for f in $MARKED; do
    f="${f#*:}"
    g show "$TAG:$f" | bash "$ROOT/scripts/directory-filter.sh" | put "$f" || die "could not filter $f"
done
# user_only puts the flag last in the frontmatter (stdin), in place of any disable-model-invocation line there.
user_only() {
    awk -v flag="$USER_ONLY_FLAG" '
        NR == 1 { if ($0 != "---") exit 1; fm = 1; print; next }
        fm && /^disable-model-invocation:/ { next }
        fm && $0 == "---" { print flag; fm = 0; done = 1 }
        { print }
        END { if (!done) exit 1 }
    '
}
for f in "${DIRECTORY_USER_ONLY[@]}"; do
    gi show ":$f" | user_only | put "$f" || die "could not make $f user-only (it needs a --- frontmatter block)"
done
# fm_keys prints the top-level keys of the frontmatter (stdin). It reads to the end, so the writer never gets SIGPIPE.
fm_keys() {
    awk 'NR == 1 { fm = ($0 == "---"); next }
         fm && $0 == "---" { fm = 0 }
         fm && /^[A-Za-z_][A-Za-z0-9_-]*:/ { k = $0; sub(/:.*/, "", k); print k }'
}
# strip_keys drops DIRECTORY_STRIP_KEYS from the frontmatter (stdin), each with its indented or listed value lines.
strip_keys() {
    awk -v keys="${DIRECTORY_STRIP_KEYS[*]}" '
        BEGIN { n = split(keys, k, " "); for (i = 1; i <= n; i++) drop[k[i]] = 1 }
        NR == 1 && $0 == "---" { fm = 1; print; next }
        fm && $0 == "---" { fm = 0; skip = 0; print; next }
        fm && /^[A-Za-z_][A-Za-z0-9_-]*:/ { key = $0; sub(/:.*/, "", key); skip = (key in drop); if (!skip) print; next }
        fm && skip && ($0 == "" || /^[[:space:]]/ || /^-/) { next }
        { skip = 0; print }
    '
}
# tools_to_deny swaps an agent's tools: allowlist (stdin frontmatter) for disallowedTools: DIRECTORY_TOOLS_DENY.
tools_to_deny() {
    awk -v deny="$DIRECTORY_TOOLS_DENY" '
        NR == 1 && $0 == "---" { fm = 1; print; next }
        fm && $0 == "---" { fm = 0; print; next }
        fm && /^tools:/ { print "disallowedTools: " deny; next }
        { print }
    '
}
# model_invocable drops disable-model-invocation from the frontmatter (stdin).
model_invocable() {
    awk 'NR == 1 && $0 == "---" { fm = 1; print; next }
         fm && $0 == "---" { fm = 0 }
         fm && /^disable-model-invocation:/ { next }
         { print }'
}
is_strip_key() { local s; for s in "${DIRECTORY_STRIP_KEYS[@]}"; do [ "$1" = "$s" ] && return 0; done; return 1; }
while IFS= read -r f; do
    case "$f" in *.md) ;; *) continue ;; esac
    strip=0; tools=0; deny=0
    for k in $(gi show ":$f" | fm_keys); do
        is_strip_key "$k" && strip=1
        [ "$k" = tools ] && tools=1
        [ "$k" = disallowedTools ] && deny=1
    done
    case "$f" in agents/*) ;; *) tools=0 ;; esac
    [ "$tools" = 1 ] && [ "$deny" = 1 ] && die "$f has both tools: and disallowedTools:, so the copy can't swap one for the other"
    [ "$strip" = 1 ] || [ "$tools" = 1 ] || continue
    gi show ":$f" | strip_keys | { if [ "$tools" = 1 ]; then tools_to_deny; else cat; fi; } | put "$f" \
        || die "could not drop the frontmatter keys from $f"
done < <(gi ls-files -- "${COMPONENT_DIRS[@]}")
for f in "${DIRECTORY_MODEL_INVOCABLE[@]}"; do
    [ -n "$(gi ls-files -- "$f")" ] || continue
    gi show ":$f" | model_invocable | put "$f" || die "could not make $f model-invocable"
done
# NOTICE lists every copied file; the copy's NOTICE leaves out the lines for the files the copy leaves out.
if [ -n "$(gi ls-files -- NOTICE)" ]; then
    NOTICE_DROP=()
    while IFS= read -r f; do
        [ -n "$f" ] && NOTICE_DROP+=(-e "- $f")
    done < <(g ls-tree -r --name-only "$TAG_TREE" -- "${DIRECTORY_DROP[@]}")
    if [ "${#NOTICE_DROP[@]}" -gt 0 ]; then
        gi show ":NOTICE" | { grep -vxF "${NOTICE_DROP[@]}" || true; } | put NOTICE \
            || die "could not drop the left-out files from NOTICE"
    fi
fi
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
    [ -n "$(gi ls-files -- "$f")" ] || continue
    g show "$TAG:$f" | sed -e "s/, $HOOKS_REPO//g" -e "s/, $WORKFLOWS_REPO//g" | put "$f" \
        || die "could not drop the hook and workflow counts in $f"
done
TREE="$(gi write-tree)"

# What the directory takes from a non-Verified organization: the allowed file types (LOCAL_CODE_FILE_TYPE) and no
# frontmatter key the copy drops (LOCAL_CODE_FRONTMATTER_KEY). Text files must be UTF-8 with no NUL bytes.
while IFS= read -r f; do
    [ -n "$f" ] || continue
    base="${f##*/}"
    [[ "$base" =~ $PACKAGE_CONFIG_RE ]] \
        && die "the directory copy holds $f, a package manager configuration, which the directory accepts only from Verified organizations"
    plain=0
    for p in "${ALLOWED_PLAIN[@]}"; do [ "$base" = "$p" ] && plain=1; done
    [[ "$f" =~ $ALLOWED_EXT_RE ]] || [ "$plain" = 1 ] \
        || die "the directory copy holds $f, and the directory accepts files outside the allowed types (Markdown, text, JSON, YAML, images) only from Verified organizations"
    [ "$(g cat-file -p "$TREE:$f" | awk 'NR == 1 { print substr($0, 1, 2) }')" != '#!' ] \
        || die "the directory copy holds $f, which starts with #!: the directory accepts scripts only from Verified organizations"
    [[ "$f" =~ $IMAGE_EXT_RE ]] && continue
    [ "$(g cat-file -p "$TREE:$f" | LC_ALL=C tr -d '\000' | wc -c | tr -d ' ')" = "$(g cat-file -s "$TREE:$f")" ] \
        || die "the directory copy holds $f, a text file with a NUL byte, which the directory refuses"
    g cat-file -p "$TREE:$f" | iconv --from-code=UTF-8 --to-code=UTF-8 >/dev/null 2>&1 \
        || die "the directory copy holds $f, a text file that isn't UTF-8, which the directory refuses"
done < <(g ls-tree -r --name-only "$TREE")
# guard_keys prints each frontmatter line (stdin) that holds a key in GUARD_KEYS, quoted, indented or with CRLF line
# ends too: a key the copy can't drop or swap still stops the release.
guard_keys() {
    awk -v keys="${GUARD_KEYS[*]}" '
        BEGIN { n = split(keys, k, " ") }
        { sub(/\r$/, "") }
        NR == 1 { fm = ($0 == "---"); next }
        fm && $0 == "---" { fm = 0 }
        fm { line = $0; gsub(/["\047]/, "", line)
             for (i = 1; i <= n; i++) if (line ~ ("^[[:space:]]*" k[i] "[[:space:]]*:")) { print; break } }'
}
while IFS= read -r f; do
    case "$f" in *.md) ;; *) continue ;; esac
    HITS="$(g cat-file -p "$TREE:$f" | guard_keys)"
    [ -z "$HITS" ] \
        || die "the directory copy keeps a frontmatter key in $f that the directory accepts only from Verified organizations: $HITS"
done < <(g ls-tree -r --name-only "$TREE" -- "${COMPONENT_DIRS[@]}")

# The directory accepts command hooks only from Verified organizations (it refused 3.5.7 with LOCAL_CODE_HOOK_COMMAND).
# hooks/ is left out, so these catch a hook declared anywhere else: a hooks.json in another folder, or a command hook
# in plugin.json or in a skill's or agent's frontmatter (JSON or YAML form). There is no \b: git grep's ERE can't be trusted with it.
HOOKS_JSON_PATHS="$(g ls-tree -r --name-only "$TREE" | grep -E '(^|/)hooks[.]json$' || true)"
[ -z "$HOOKS_JSON_PATHS" ] || die "the directory copy holds a hooks.json, and the directory accepts command hooks only from Verified organizations: $HOOKS_JSON_PATHS"
HOOK_COMMAND_RE="[\"']?type[\"']?[[:space:]]*:[[:space:]]*[\"']?command([^[:alnum:]_-]|\$)"
HITS="$(scan -nEi -e "$HOOK_COMMAND_RE" "$TREE")"
[ -z "$HITS" ] || die "the directory copy holds a hook of type command, which the directory accepts only from Verified organizations: $HITS"

# What the directory scan holds a version for: shipped text naming a bundled image or font, or fetch-and-run.
ASSETS="$(g ls-tree -r --name-only "$TREE" | sed -n -E 's#^(.*/)?([^/]+\.(png|jpe?g|gif|webp|ico|svg|woff2?|ttf|otf))$#\2#p')"
for a in $ASSETS; do
    HITS="$(scan -lF -e "$a" "$TREE" -- . ":(exclude)*$a")"
    [ -z "$HITS" ] || die "shipped text names the bundled $a, which the directory scan holds for review: $HITS"
done
HITS="$(scan -nEi -e '(curl|wget)[^|]*[|][[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh([^[:alnum:]]|$)' "$TREE")"
[ -z "$HITS" ] || die "shipped text pipes a download into a shell: $HITS"
# A segment that starts with a password-store command and an argument reads to the scan as a secret being read: the
# report named "(pass sometimes," in a debug skill file, paired it with the SessionStart hook as the sender, and held
# 3.4.1 to 3.5.6 for "Uses a credential from the user's machine".
PASSWORD_STORE_RE="(^|[({|;\`]|&&|[|][|]|[\$][(])[[:space:]]*[\"']?(pass|gopass|secret-tool|lpass|keepassxc-cli)[\"']?[[:space:]]+[^[:space:]|)}]"
HITS="$(scan -niE -e "$PASSWORD_STORE_RE" "$TREE")"
[ -z "$HITS" ] || die "shipped text reads as a password-store command, which the directory scan holds as a credential read: $HITS"
HITS="$(scan -nF -e 'repo-only -->' -e '<!-- directory-only' "$TREE")"
[ -z "$HITS" ] || die "a repo-only or directory-only marker reached the release tree: $HITS"
# Every file left out is searched by its stem when the stem has a dash (session-start), else by its full name
# (hooks.json), so the plain word "hooks" is never searched. A left-out directory is searched as "dir/".
while IFS= read -r f; do
    [ -n "$f" ] || continue
    name="${f##*/}"; stem="${name%.*}"
    case "$stem" in *-*) needle="$stem" ;; *) needle="$name" ;; esac
    HITS="$(scan -nF -e "$needle" "$TREE")"
    [ -z "$HITS" ] || die "the directory copy leaves out $f but still names it: $HITS"
done < <(g ls-tree -r --name-only "$TAG_TREE" -- "${DIRECTORY_DROP[@]}")
for e in "${DIRECTORY_DROP[@]}"; do
    [ "$(g cat-file -t "$TAG:$e" 2>/dev/null || true)" = "tree" ] || continue
    HITS="$(scan -nF -e "$e/" "$TREE")"
    [ -z "$HITS" ] || die "the directory copy leaves out $e/ but still names it: $HITS"
done
HITS="$(scan -nE -e "$HOOK_COUNT_RE" "$TREE")"
[ -z "$HITS" ] || die "the directory copy ships no hooks but still counts them: $HITS"
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

LIST="$(g ls-tree --name-only "$TREE" | paste -sd, - | sed 's/,/, /g')"
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
