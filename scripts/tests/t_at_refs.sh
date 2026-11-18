#!/usr/bin/env bash
# ABOUTME: Asserts no text claims an @ reference in an Agent prompt is expanded, and agents read the named files unless already in context.
# ABOUTME: The plan and review dispatch text, planner and researcher step 0, and code-reviewer step 0 (no "pre-loaded": only the main session gets a pre-load).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
rc=0
has() { tr -d '\r' < "$1" | grep -qF -- "$2" || { echo "    $(basename "$1") missing: $2"; rc=1; }; }
lacks() { tr -d '\r' < "$1" | grep -qF -- "$2" && { echo "    $(basename "$1") must not have: $2"; rc=1; }; }
A="$PLUGIN_DIR/agents"; K="$PLUGIN_DIR/skills"
for f in "$A/planner.md" "$A/researcher.md" "$A/code-reviewer.md" "$K/plan/SKILL.md" "$K/review/SKILL.md"; do assert_file "$f" || exit 1; done
lacks "$K/plan/SKILL.md" 'auto-read on dispatch'
has "$K/plan/SKILL.md" 'The planner uses those files first, reading any whose contents didn'
lacks "$K/review/SKILL.md" 'so the subagent sees the navigation index'
has "$K/review/SKILL.md" 'which names the files it uses first'
for a in planner researcher; do
    has "$A/$a.md" 'already in your context'
    lacks "$A/$a.md" 'injected into your context via'
done
lacks "$A/code-reviewer.md" 'pre-loaded'
has "$A/code-reviewer.md" 'read ATLAS.md if it exists'
exit $rc
