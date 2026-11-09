#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.5.9] entry: the directory refused 3.5.8 for file types and frontmatter keys
# ABOUTME: (Verified organizations only), so the directory copy leaves out two debug files and drops four keys.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.5\.9\]" "$F" || { echo "    missing [3.5.9] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.5\.9\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "LOCAL_CODE_FILE_TYPE" "LOCAL_CODE_FRONTMATTER_KEY" "Verified organization" "find-polluter.sh" \
    "condition-based-waiting-example.ts" "memory" "maxTurns" "background" "experimental" "NOTICE" \
    "turbocharge@turbocharge" "release.sh" "t_release_tree.sh" "t_directory_copy.sh" "evals"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.5.9] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
