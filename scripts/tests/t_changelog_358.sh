#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.5.8] entry: the directory refused 3.5.7 for its command hook (Verified
# ABOUTME: organizations only), so the directory copy ships no hooks. Earlier entries stay frozen.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.5\.8\]" "$F" || { echo "    missing [3.5.8] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.5\.8\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "LOCAL_CODE_HOOK_COMMAND" "LOCAL_CODE_NOT_CHECKED" "Verified organization" "prompt" "mcp_tool" "SessionStart" \
    "hooks.json" "turbocharge@turbocharge" "release.sh" "t_release_tree.sh" "t_directory_copy.sh" "evals"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.5.8] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
