#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.5.7] entry: the debug skill line the directory scan read as a password-store
# ABOUTME: command, found in the report's credential_at/env/sender_at fields. Earlier entries stay frozen.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.5\.7\]" "$F" || { echo "    missing [3.5.7] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.5\.7\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "condition-based-waiting.md" "password-store" "credential_at" "sender_at" "SessionStart hook" "release.sh" \
    "t_release_tree.sh" "t_directory_copy.sh"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.5.7] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
