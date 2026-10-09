#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a newest-first [3.0.1] entry documenting the GitHub repo rename,
# ABOUTME: the redirect that keeps old URLs and installs working, and every ref the release flipped.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.0\.1\]" "$F" || { echo "    missing [3.0.1] entry"; exit 1; }
grep -m1 "^## \[" "$F" | grep -q "^## \[3\.0\.1\]" || { echo "    [3.0.1] is not the newest entry"; exit 1; }

SECTION="$(mktemp)"
awk '/^## \[3\.0\.1\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in \
    "nicodiansk/turboflow" \
    "marketplace add nicodiansk/turbo""charge" \
    "redirect" \
    "No user action" \
    "homepage" \
    "repository" \
    "turboflow\.git" \
    "README\.md" \
    "CLAUDE\.md" \
    "t_no_old_repo_path\.sh"; do
    assert_grep "$SECTION" "$p" || rc=1
done
rm -f "$SECTION"
exit $rc
