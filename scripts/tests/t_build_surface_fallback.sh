#!/usr/bin/env bash
# ABOUTME: Asserts build runs lanes and lane reviews inline when its agents can't be dispatched (surfaces without agents).
# ABOUTME: Also asserts Reviewed Mode (references/reviewed-mode.md) rules on every "Declined to judge" line: a finding, or set aside.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$S" || exit 1
grep -qF 'not registered' "$S"                             || { echo "    build must handle an unregistered builder type"; exit 1; }
grep -qF 'agents unavailable — running lanes inline' "$S" || { echo "    build must announce the inline fallback"; exit 1; }
STEP6=$(tr -d '\r' < "$PLUGIN_DIR/skills/build/references/reviewed-mode.md" 2>/dev/null)
for p in 'Declined to judge' 'set aside' 'not registered'; do
    printf '%s\n' "$STEP6" | grep -qF "$p" || { echo "    reviewed-mode.md missing: $p"; exit 1; }
done
exit 0
