#!/usr/bin/env bash
# ABOUTME: Asserts the session bootstrap keeps its routing headings, its five red flags and its four rules.
# ABOUTME: 3.8.0 reverted F35 here: without "Before ANY" and "you SHOULD use a skill", defects-review fired review 0/3 (2/3 with them).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
B="$PLUGIN_DIR/hooks/session-bootstrap.md"
assert_file "$B" || exit 1
rc=0
BODY=$(tr -d '\r' < "$B")
for p in '## Before ANY implementation or complex task' 'thoughts that mean you SHOULD use a skill' '## Critical rules:'; do
    printf '%s\n' "$BODY" | grep -qF -- "$p" || { echo "    bootstrap lost its routing text: $p"; rc=1; }
done
n=$(printf '%s\n' "$BODY" | grep -cF -- '→ Use `/turbocharge:')
[ "$n" -eq 5 ] || { echo "    bootstrap has $n red-flag lines, expected 5"; rc=1; }
for p in 'Verify domain understanding' 'Run the full test suite' 'Never ask permission' 'Reviews must be comprehensive'; do
    printf '%s\n' "$BODY" | grep -qF -- "$p" || { echo "    bootstrap missing: $p"; rc=1; }
done
exit $rc
