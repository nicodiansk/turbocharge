#!/usr/bin/env bash
# ABOUTME: Asserts the session bootstrap text drops its capital-letter markers and keeps its five red flags and four rules.
# ABOUTME: 3.8.0 prompt hygiene F35; the red-flag lines stay because F12 is the user's call.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
B="$PLUGIN_DIR/hooks/session-bootstrap.md"
assert_file "$B" || exit 1
rc=0
BODY=$(tr -d '\r' < "$B")
for p in 'ANY' 'SHOULD' 'Critical rules'; do
    ! printf '%s\n' "$BODY" | grep -qF -- "$p" || { echo "    bootstrap still has: $p"; rc=1; }
done
n=$(printf '%s\n' "$BODY" | grep -cF -- '→ Use `/turbocharge:')
[ "$n" -eq 5 ] || { echo "    bootstrap has $n red-flag lines, expected 5"; rc=1; }
for p in 'Verify domain understanding' 'Run the full test suite' 'Never ask permission' 'Reviews must be comprehensive'; do
    printf '%s\n' "$BODY" | grep -qF -- "$p" || { echo "    bootstrap missing: $p"; rc=1; }
done
exit $rc
