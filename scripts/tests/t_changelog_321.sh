#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.2.1] entry that corrects the [3.2.0] name-history claim and documents
# ABOUTME: the directory install id. Earlier entries stay frozen; the correction lives in the new entry.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.2\.1\]" "$F" || { echo "    missing [3.2.1] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.2\.1\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "Another author" "turbocharge-nicodiansk@anthropic-plugin-directory" "[3.2.0]"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.2.1] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
