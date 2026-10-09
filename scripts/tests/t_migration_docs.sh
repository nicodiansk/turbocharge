#!/usr/bin/env bash
# ABOUTME: Asserts README and the CHANGELOG [3.0.0] entry document both 2.x -> 3.0.0 migration paths.
# ABOUTME: Quick (keep the old marketplace key) and Clean (remove + re-add), plus the Claude Code 2.1.288 floor.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
README="$PLUGIN_DIR/README.md"
assert_file "$README" || exit 1
SECTION="$(mktemp)"
awk '/^## \[3\.0\.0\]/{f=1; next} f && /^## \[/{exit} f' "$PLUGIN_DIR/CHANGELOG.md" > "$SECTION"
rc=0
for F in "$README" "$SECTION"; do
    for p in \
        "claude plugin marketplace update turbocharge" \
        "claude plugin install turboflow@turbocharge" \
        "claude plugin marketplace remove turbocharge" \
        "claude plugin marketplace add nicodiansk/turbocharge" \
        "claude plugin install turboflow@turboflow" \
        "/reload-plugins" \
        "2\.1\.288" \
        "saved options and data" \
        "turbocharge:\*"; do
        assert_grep "$F" "$p" || rc=1
    done
done
# The old one-liner was wrong: `plugin update` alone cannot cross a marketplace rename.
assert_no_grep "$SECTION" "to pick up the new namespace" || rc=1
rm -f "$SECTION"
exit $rc
