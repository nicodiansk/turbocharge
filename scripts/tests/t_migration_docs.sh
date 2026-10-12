#!/usr/bin/env bash
# ABOUTME: Asserts the README documents the paths from turboflow 3.0–3.1 back to turbocharge 3.2+ for both marketplace
# ABOUTME: keys (turboflow, and turbocharge for pre-3.0 adds), and that the frozen [3.0.0] entry keeps its original 2.x paths.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
README="$PLUGIN_DIR/README.md"
assert_file "$README" || exit 1
rc=0
for p in \
    "Coming from turboflow 3.0–3.1" \
    "claude plugin marketplace list" \
    "claude plugin marketplace update turboflow" \
    "claude plugin install turbocharge@turboflow" \
    "claude plugin marketplace update turbocharge" \
    "claude plugin marketplace remove turboflow" \
    "claude plugin marketplace add nicodiansk/turbocharge" \
    "claude plugin install turbocharge@turbocharge" \
    "/reload-plugins" \
    "2.1.288" \
    "saved options and data" \
    'turboflow:*'; do
    grep -qF -- "$p" "$README" || { echo "    README missing: $p"; rc=1; }
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
