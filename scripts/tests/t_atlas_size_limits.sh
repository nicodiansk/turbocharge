#!/usr/bin/env bash
# ABOUTME: Tests that the atlas skill keeps Where to Look to 25 short rows and ATLAS.md to 15-20 KB.
# ABOUTME: The limits are shared text; the SessionStart and validator lines sit in repo-only blocks.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/atlas/SKILL.md"
assert_file "$F" || exit 1
FILTERED="$(bash "$PLUGIN_DIR/scripts/directory-filter.sh" < "$F")" || exit 1
for p in 'within ~140 characters' 'At most 25 rows, most useful first' 'No history in cells' '"since !76"' \
         '📌 notes stay within 2 lines' 'aim for 15–20 KB' 'Module Map or Conventions & Gotchas' "Keep ATLAS.md's line endings"; do
    grep -qF -- "$p" "$F" || { echo "    atlas skill lacks: $p"; exit 1; }
    printf '%s' "$FILTERED" | grep -qF -- "$p" || { echo "    directory copy lost: $p"; exit 1; }
done
case "$FILTERED" in *SessionStart*|*validate-atlas*) echo "    directory copy names SessionStart or validate-atlas"; exit 1;; esac
assert_grep "$F" 'SessionStart' || exit 1
# warning: sits inside a repo-only block
awk '/^<!-- repo-only -->$/ {r=1; next} /^<!-- \/repo-only -->$/ {r=0; next} r && /warning:/ {f=1} END {exit !f}' "$F" \
    || { echo "    no 'warning:' inside a repo-only block"; exit 1; }
assert_grep "$F" 'history in a cell' || exit 1
