#!/usr/bin/env bash
# ABOUTME: Tests CHANGELOG.md has a [2.5.0] entry with required keywords.
# ABOUTME: Verifies lazy-load, staleness, codemap, and overhead reduction.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[2\.5\.0\]" "$F" || { echo "    missing [2.5.0] entry"; exit 1; }
assert_grep "$F" "Lazy-load"               || exit 1
assert_grep "$F" "Staleness detection"      || exit 1
assert_grep "$F" "Codemap integration"      || exit 1
assert_grep "$F" "Debug skill"              || exit 1
