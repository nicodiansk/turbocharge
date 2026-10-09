#!/usr/bin/env bash
# ABOUTME: Asserts SessionStart swaps the missing-CLAUDE.md nudge for an AGENTS.md-aware one.
# ABOUTME: AGENTS.md is read only when no CLAUDE.md exists, so the nudge must steer to an @AGENTS.md import.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
N="$PLUGIN_DIR/hooks/agentsmd-only-nudge.md"
assert_file "$N" || exit 1
assert_grep "$N" "@AGENTS.md"        || exit 1
assert_grep "$N" "/turboflow:setup"  || exit 1
LINES=$(wc -l < "$N")
[ "$LINES" -le 10 ] || { echo "    nudge is $LINES lines, expected ≤ 10"; exit 1; }

TMP="$(mktemp -d)"
cleanup() { cd /; rm -rf "$TMP"; }
cd "$TMP"

# AGENTS.md only → AGENTS-aware nudge, NOT the plain missing-CLAUDE.md nudge.
echo "# Agents fixture" > AGENTS.md
OUT="$(bash "$F" 2>&1 || true)"
echo "$OUT" | grep -q "AGENTS.md Detected" || { echo "    AGENTS.md-aware nudge not shown"; cleanup; exit 1; }
echo "$OUT" | grep -q "No CLAUDE.md Detected" && { echo "    plain CLAUDE.md nudge shown despite AGENTS.md"; cleanup; exit 1; }

# Neither file → plain nudge (unchanged behavior).
rm AGENTS.md
OUT="$(bash "$F" 2>&1 || true)"
echo "$OUT" | grep -q "No CLAUDE.md Detected" || { echo "    plain CLAUDE.md nudge missing"; cleanup; exit 1; }

# CLAUDE.md present → no nudge at all.
echo "# AGENTS" > AGENTS.md; echo "@AGENTS.md" > CLAUDE.md
OUT="$(bash "$F" 2>&1 || true)"
cleanup
echo "$OUT" | grep -q "AGENTS.md Detected"    && { echo "    nudge shown although CLAUDE.md exists"; exit 1; }
echo "$OUT" | grep -q "No CLAUDE.md Detected" && { echo "    nudge shown although CLAUDE.md exists"; exit 1; }
exit 0
