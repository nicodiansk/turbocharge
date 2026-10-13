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

# build acts on the Status line: context → resume the same builder; stuck → one Opus retry.
S="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$S" || exit 1
for p in 'model: opus' 'DONE_WITH_CONCERNS' 'Status: BLOCKED' 'Blocked on:' 'Rulings'; do
    grep -qF "$p" "$S" || { echo "    build skill missing: $p"; exit 1; }
done
grep -qF 'Guessing through blockers' "$S" && { echo "    build skill still says 'Guessing through blockers'"; exit 1; }
STEP5=$(awk '{ sub(/\r$/, "") } /^## Step 5/ { s=1 } /^## Step 6/ { s=0 } s' "$S")
for p in 'BLOCKED on context' 'SendMessage'; do
    printf '%s\n' "$STEP5" | grep -qF "$p" || { echo "    build Step 5 missing: $p"; exit 1; }
done
exit 0
