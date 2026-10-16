#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.4.2] entry for the directory fix: the filtered README, no CHANGELOG in the
# ABOUTME: directory copy, release.sh's refusals and their tests. Earlier entries stay frozen.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.4\.2\]" "$F" || { echo "    missing [3.4.2] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.4\.2\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "UNREAD_ASSET_REFERENCED" "RUNTIME_FETCH_EXEC" "directory-readme.sh" "repo-only" "t_directory_readme.sh" \
    "CHANGELOG stays on GitHub"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.4.2] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
