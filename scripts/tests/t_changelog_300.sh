#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.0.0] entry documenting the turboflow rename
# ABOUTME: and every Claude Code 2.1.288 compatibility fix (one test file named per item).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.0\.0\]" "$F" || { echo "    missing [3.0.0] entry"; exit 1; }
assert_grep "$F" "turboflow" || exit 1
assert_grep "$F" "BREAKING" || exit 1

# Compatibility items must be listed inside the [3.0.0] section, not elsewhere.
SECTION="$(mktemp)"
awk '/^## \[3\.0\.0\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in \
    "t_marketplace_renames.sh" \
    "t_session_snapshot_fallback.sh" \
    "t_build_background_wait.sh" \
    "t_forked_skills_block.sh" \
    "t_agent_no_nested_spawn.sh" \
    "t_agentsmd_nudge.sh" \
    "t_setup_agentsmd.sh" \
    "t_dispatch_agentsmd_prefix.sh" \
    "t_claudemd_hook_ref.sh" \
    "t_session_start_output_cap.sh" \
    "background: false" \
    "10,000"; do
    assert_grep "$SECTION" "$p" || rc=1
done
rm -f "$SECTION"
exit $rc
