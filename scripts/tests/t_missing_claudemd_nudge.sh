#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/missing-claudemd-nudge.md"
assert_file "$F" || exit 1
assert_grep "$F" "/init"                  || exit 1
assert_grep "$F" "/turbocharge:setup"     || exit 1
# No more manual 5-section dump
assert_no_grep "$F" "### ABOUTME Convention" || exit 1
assert_no_grep "$F" "### TDD Workflow"        || exit 1
LINES=$(wc -l < "$F")
[ "$LINES" -le 10 ] || { echo "    nudge is $LINES lines, expected ≤ 10"; exit 1; }
