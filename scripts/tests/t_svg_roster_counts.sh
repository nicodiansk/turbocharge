#!/usr/bin/env bash
# ABOUTME: Tests that "N skills · N agents · N hooks" taglines in SVGs match plugin.json.
# ABOUTME: Guards against stale roster counts in images/ (the 2.7.0 6->5 hero-banner miss).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
assert_file "$P" || exit 1

# Canonical counts from the manifest description ("... 10 skills, 5 agents ...").
SKILLS=$(grep -oE '[0-9]+ skills' "$P" | head -1 | grep -oE '[0-9]+')
AGENTS=$(grep -oE '[0-9]+ agents' "$P" | head -1 | grep -oE '[0-9]+')
[ -n "$SKILLS" ] && [ -n "$AGENTS" ] || { echo "    could not read canonical counts from plugin.json"; exit 1; }

rc=0
checked=0
for svg in "$PLUGIN_DIR"/images/*.svg; do
    [ -f "$svg" ] || continue
    # Match only the canonical roster tagline: "N skills ... N agents ... N hooks".
    # This deliberately ignores other "N agents" strings (e.g. the BEFORE panel's
    # "6 agents · 4 commands · 3 rule files", which depicts the old config on purpose).
    while IFS= read -r line; do
        checked=$((checked+1))
        s=$(echo "$line" | grep -oE '[0-9]+ skills' | grep -oE '[0-9]+')
        a=$(echo "$line" | grep -oE '[0-9]+ agents' | grep -oE '[0-9]+')
        [ "$s" = "$SKILLS" ] || { echo "    $(basename "$svg"): roster says '$s skills', expected '$SKILLS'"; rc=1; }
        [ "$a" = "$AGENTS" ] || { echo "    $(basename "$svg"): roster says '$a agents', expected '$AGENTS'"; rc=1; }
    done < <(grep -oE '[0-9]+ skills[^<]*[0-9]+ agents[^<]*[0-9]+ hooks' "$svg")
done

# The guard is only useful if it actually found taglines to check.
[ "$checked" -gt 0 ] || { echo "    no roster taglines found in any SVG — guard pattern may be stale"; exit 1; }
exit $rc
