#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.2.0] entry restoring the turbocharge name: why (the directory listing is ours),
# ABOUTME: upgrade notes for 2.8.x directory users and turboflow 3.x users, and the snapshot/marker/renames compatibility.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.2\.0\]" "$F" || { echo "    missing [3.2.0] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.2\.0\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "directory" "turboflow-session.json" "renames" "2.1.288" "/turbocharge:" "<!-- turboflow:" "2.8.1"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.2.0] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
