#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.5.5] entry: the directory copy keeps ship user-only, for the directory's
# ABOUTME: "Update adds credential forward" hold, and 3.5.4 is explained. Earlier entries stay frozen.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.5\.5\]" "$F" || { echo "    missing [3.5.5] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.5\.5\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "credential forward" "disable-model-invocation: true" "3.3.0" "3.4.0" "3.5.4" "git push" "gh pr create" \
    "/turbocharge:ship" "t_release_tree.sh"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.5.5] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
