#!/usr/bin/env bash
# ABOUTME: Asserts the hook count agrees wherever it is written: plugin.json, marketplace.json and release.sh's
# ABOUTME: HOOKS_REPO say N hooks, where N is the distinct hooks/<name>.sh scripts hooks.json runs (t_svg_roster_counts.sh's rule).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
H="$PLUGIN_DIR/hooks/hooks.json"
assert_file "$H" || exit 1
N=$(grep -oE 'hooks/[A-Za-z0-9_-]+\.sh' "$H" | sort -u | wc -l | tr -d ' ')
[ "$N" -gt 0 ] || { echo "    hooks.json names no hook scripts"; exit 1; }
rc=0
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
    grep -qF "$N hooks" "$PLUGIN_DIR/$f" \
        || { echo "    ${f##*/} says $(grep -oE '[0-9]+ hooks?' "$PLUGIN_DIR/$f" | head -n 1); hooks.json names $N hook scripts"; rc=1; }
done
R="$(sed -n "s/^HOOKS_REPO='\(.*\)'\$/\1/p" "$PLUGIN_DIR/scripts/release.sh")"
[ "$R" = "$N hooks" ] || { echo "    release.sh HOOKS_REPO is '$R'; hooks.json names $N hook scripts"; rc=1; }
exit $rc
