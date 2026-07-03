#!/usr/bin/env bash
# ABOUTME: Tests that "N skills · N agents · N hooks" taglines in SVGs match ground truth.
# ABOUTME: Skills/agents come from plugin.json; hooks from hooks.json keys (the 2.7.0 6->5 guard).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
H="$PLUGIN_DIR/hooks/hooks.json"
assert_file "$P" || exit 1
assert_file "$H" || exit 1

# Canonical counts: skills/agents from the manifest description, hooks from hooks.json.
SKILLS=$(grep -oE '[0-9]+ skills' "$P" | grep -oE '[0-9]+')
AGENTS=$(grep -oE '[0-9]+ agents' "$P" | grep -oE '[0-9]+')
if command -v jq >/dev/null 2>&1; then
    HOOKS=$(jq -r '.hooks | keys | length' "$H")
else
    HOOKS=$(grep -cE '^    "[A-Za-z]+": \[' "$H")
fi
[ -n "$SKILLS" ] && [ -n "$AGENTS" ] && [ -n "$HOOKS" ] || { echo "    could not read canonical counts (skills=$SKILLS agents=$AGENTS hooks=$HOOKS)"; exit 1; }

rc=0
taglines_found=0
for svg in "$PLUGIN_DIR"/images/*.svg; do
    [ -f "$svg" ] || continue
    # Match only the canonical roster tagline: "N skills ... N agents ... N hooks".
    # This deliberately ignores other "N agents" strings (e.g. the BEFORE panel's
    # "6 agents · 4 commands · 3 rule files", which depicts the old config on purpose).
    while IFS= read -r line; do
        taglines_found=$((taglines_found+1))
        s=$(echo "$line" | grep -oE '[0-9]+ skills' | grep -oE '[0-9]+')
        a=$(echo "$line" | grep -oE '[0-9]+ agents' | grep -oE '[0-9]+')
        h=$(echo "$line" | grep -oE '[0-9]+ hooks?' | grep -oE '[0-9]+')
        [ "$s" = "$SKILLS" ] || { echo "    $(basename "$svg"): roster says '$s skills', expected '$SKILLS'"; rc=1; }
        [ "$a" = "$AGENTS" ] || { echo "    $(basename "$svg"): roster says '$a agents', expected '$AGENTS'"; rc=1; }
        [ "$h" = "$HOOKS"  ] || { echo "    $(basename "$svg"): roster says '$h hooks', expected '$HOOKS'"; rc=1; }
    done < <(grep -oE '[0-9]+ skills[^<]*[0-9]+ agents[^<]*[0-9]+ hooks?' "$svg")
done

# The guard is only useful if it actually found taglines to check.
[ "$taglines_found" -gt 0 ] || { echo "    no roster taglines found in any SVG — guard pattern may be stale"; exit 1; }
exit $rc
