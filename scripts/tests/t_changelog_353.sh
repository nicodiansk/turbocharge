#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.5.3] entry: the directory copy leaves out the review workflow, for the
# ABOUTME: directory's "Update adds credential forward" hold. Earlier entries stay frozen.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.5\.3\]" "$F" || { echo "    missing [3.5.3] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.5\.3\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "credential forward" "workflows/review-swarm.js" "one code-reviewer" "1 workflow" "gh pr create" \
    "t_directory_copy.sh"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.5.3] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
