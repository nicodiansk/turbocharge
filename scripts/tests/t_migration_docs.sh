#!/usr/bin/env bash
# ABOUTME: Asserts the README's Upgrading section serves the real audience (directory and 2.x users: update as usual)
# ABOUTME: with no turboflow 3.0–3.1 migration (only the maintainer ever ran it), and the frozen [3.0.0] paths stay intact.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
README="$PLUGIN_DIR/README.md"
assert_file "$README" || exit 1
rc=0
grep -qF "### Upgrading" "$README"      || { echo "    README missing the Upgrading section"; rc=1; }
grep -qF "update as usual" "$README"    || { echo "    README must tell directory and 2.x users to update as usual"; rc=1; }
grep -qF "2.1.287 or later" "$README"   || { echo "    README must state the Claude Code floor (2.1.287 since 3.4.0)"; rc=1; }
# Nobody but the maintainer installed the interim turboflow releases: no migration steps for them.
for p in \
    "Coming from turboflow" \
    "claude plugin install turbocharge@turboflow" \
    "claude plugin marketplace update turboflow" \
    "claude plugin marketplace remove turboflow"; do
    grep -qF -- "$p" "$README" && { echo "    README still has turboflow migration text: $p"; rc=1; }
done

# History is frozen: the [3.0.0] entry keeps the 2.x -> 3.0.0 paths it shipped with.
SECTION="$(mktemp)"
awk '/^## \[3\.0\.0\]/{f=1; next} f && /^## \[/{exit} f' "$PLUGIN_DIR/CHANGELOG.md" > "$SECTION"
for p in \
    "claude plugin marketplace update turbocharge" \
    "claude plugin install turboflow@turbocharge" \
    "claude plugin marketplace remove turbocharge" \
    "claude plugin install turboflow@turboflow" \
    "/reload-plugins" \
    "2\.1\.288" \
    "saved options and data" \
    "turbocharge:\*"; do
    assert_grep "$SECTION" "$p" || rc=1
done
assert_grep "$SECTION" "claude plugin marketplace add nicodiansk/turbo""charge" || rc=1
# The old one-liner was wrong: `plugin update` alone cannot cross a marketplace rename.
assert_no_grep "$SECTION" "to pick up the new namespace" || rc=1
rm -f "$SECTION"
exit $rc
