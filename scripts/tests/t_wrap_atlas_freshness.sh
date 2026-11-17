#!/usr/bin/env bash
# ABOUTME: Asserts wrap's step 5.5 reruns atlas only when files changed since the atlas-sha, using git alone (no CodeMap).
# ABOUTME: The excluded paths, the untracked-file listing, the one-line report and the directory copy are pinned.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
W="$PLUGIN_DIR/skills/wrap/SKILL.md"
assert_file "$W" || exit 1
rc=0
sec() { awk -v h="$2" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && /^##/ { s=0 } s' "$1"; }
S=$(sec "$W" '### 5.5.')
[ -n "$S" ] || { echo "    wrap has no ### 5.5. section"; exit 1; }
for p in 'git diff --name-only --no-renames <atlas-sha> --' ':(exclude)CLAUDE.md' ':(exclude).claude' \
    'git ls-files --others --exclude-standard' 'map not rerun' 'git cat-file -e' 'atlas-sha <short sha>'; do
    printf '%s\n' "$S" | grep -qF -- "$p" || { echo "    wrap 5.5 missing: $p"; rc=1; }
done
grep -qF 'Always run' "$W" && { echo "    wrap still says: Always run"; rc=1; }
grep -qi 'codemap' "$W" && { echo "    wrap still names codemap"; rc=1; }
FILTERED=$(bash "$PLUGIN_DIR/scripts/directory-filter.sh" < "$W")
for p in 'git diff --name-only --no-renames' 'map not rerun'; do
    printf '%s\n' "$FILTERED" | grep -qF -- "$p" || { echo "    filtered wrap missing: $p"; rc=1; }
done
exit $rc
