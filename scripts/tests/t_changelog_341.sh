#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.4.1] entry for the directory fix: strict YAML frontmatter and its test.
# ABOUTME: Earlier entries stay frozen; plugin.json's version is checked separately by t_version_matches_changelog.sh.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.4\.1\]" "$F" || { echo "    missing [3.4.1] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.4\.1\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "REACH_UNKNOWN" "strict YAML" "t_frontmatter_yaml.sh" "merges: a review"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.4.1] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
