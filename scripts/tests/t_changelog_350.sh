#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.5.0] entry: ship's --watch removed for /autofix-pr, offline triage kept, and the
# ABOUTME: directory copy without the exit gate. Earlier entries stay frozen.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.5\.0\]" "$F" || { echo "    missing [3.5.0] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.5\.0\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "### Removed" "--watch" "/autofix-pr" "pasted" "never pushes" "exit gate" "1 hook" "directory-filter.sh" \
    "directory-only" "t_directory_copy.sh" "Update adds" "### Upgrading"; do
    grep -qF -- "$p" "$SECTION" || grep -qiF -- "$p" "$SECTION" || { echo "    [3.5.0] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
