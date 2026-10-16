#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/missing-atlasmd-nudge.md"
assert_file "$F" || exit 1
assert_grep "$F" "/turbocharge:atlas"     || exit 1
assert_grep "$F" "pre-loaded"             || exit 1
LINES=$(wc -l < "$F")
[ "$LINES" -le 8 ] || { echo "    nudge is $LINES lines, expected ≤ 8"; exit 1; }
