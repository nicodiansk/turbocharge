#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.1.0] entry for the fast-build release:
# ABOUTME: lean plans + lanes, inline/builder routing, overlap, SendMessage fix rounds, cacheTtl, and the removals.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.1\.0\]" "$F" || { echo "    missing [3.1.0] entry"; exit 1; }

SECTION="$(mktemp)"
awk '/^## \[3\.1\.0\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "Lanes" "--inline" "--delegate" "SendMessage" "cacheTtl" "turbocharge-session.json" "Agent Teams" "rename it to"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.1.0] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
