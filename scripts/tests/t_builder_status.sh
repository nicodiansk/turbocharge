#!/usr/bin/env bash
# ABOUTME: Asserts the builder rules on minor ambiguity, stops only for named reasons, and ends with a Status line.
# ABOUTME: 3.3.0 quality pack item 3: a background builder cannot ask, so "ask now, don't guess" is gone.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
B="$PLUGIN_DIR/agents/builder.md"
assert_file "$B" || exit 1
for p in 'Status: DONE | DONE_WITH_CONCERNS | BLOCKED' '**Rulings**' 'cost if wrong' 'Blocked on:' 'security-sensitive'; do
    grep -qF "$p" "$B" || { echo "    builder.md missing: $p"; exit 1; }
done
for p in 'ask now' "Don't guess" 'Ask questions early' 'asks questions'; do
    grep -qF "$p" "$B" && { echo "    builder.md still says: $p"; exit 1; }
done
exit 0
