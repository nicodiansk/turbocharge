#!/usr/bin/env bash
# ABOUTME: Tests that the atlas skill counts Key Symbols, records the commit and names no CodeMap.
# ABOUTME: Script paths must sit in repo-only blocks: the directory copy ships none of them.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/atlas/SKILL.md"
assert_file "$F" || exit 1
FILTERED="$(bash "$PLUGIN_DIR/scripts/directory-filter.sh" < "$F")" || exit 1

! grep -qi "codemap" "$F" || { echo "    atlas skill still names codemap"; exit 1; }
! grep -q "md5" "$F" || { echo "    atlas skill still computes an md5 hash"; exit 1; }
assert_grep "$F" 'rank them by `git grep -cw <name>`' || exit 1
assert_grep "$F" '`git diff --name-only --no-renames <atlas-sha> HEAD`' || exit 1
assert_grep "$F" '^## Key Flows' || exit 1
assert_grep "$F" '| Symbol | File | Kind | Refs |' || exit 1
assert_grep "$F" 'atlas-sha' || exit 1
assert_grep "$F" 'Every path in backticks is repo-relative' || exit 1
assert_grep "$F" 'skills/atlas/atlas-symbols.sh" top 30' || exit 1
case "$FILTERED" in *atlas-symbols*) echo "    directory copy names atlas-symbols"; exit 1;; esac
for p in 'rank them by `git grep -cw <name>`' '`git diff --name-only --no-renames <atlas-sha> HEAD`' '## Key Flows' '| Symbol | File | Kind | Refs |' 'atlas-sha'; do
    printf '%s' "$FILTERED" | grep -qF -- "$p" || { echo "    directory copy lost: $p"; exit 1; }
done
# The Key Symbols example row carries no line number
ROW="$(awk '/\| Symbol \| File \| Kind \| Refs \|/ {f=1; next} f && /^\|[-|]+\|$/ {next} f {print; exit}' "$F")"
[ -n "$ROW" ] || { echo "    no Key Symbols example row"; exit 1; }
! printf '%s' "$ROW" | grep -q ':[0-9]' || { echo "    Key Symbols example row has a line number: $ROW"; exit 1; }

# After Generation validates before it commits; callers are asked at the time
for p in 'Commit ATLAS.md only when every check passes' 'Who calls whom' '`git grep -nw <name>`'; do
    grep -qF -- "$p" "$F" || { echo "    atlas skill lacks: $p"; exit 1; }
    printf '%s' "$FILTERED" | grep -qF -- "$p" || { echo "    directory copy lost: $p"; exit 1; }
done
assert_grep "$F" 'skills/atlas/validate-atlas.sh" ATLAS.md' || exit 1
assert_grep "$F" 'skills/atlas/atlas-symbols.sh" where' || exit 1
case "$FILTERED" in *validate-atlas*|*atlas-symbols*) echo "    directory copy names an atlas script"; exit 1;; esac
assert_grep "$F" 'Line numbers in Key Symbols' || exit 1
