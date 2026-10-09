#!/usr/bin/env bash
# ABOUTME: Asserts SessionStart falls back to the pre-3.0.0 snapshot name for upgraders (3.0.x only).
# ABOUTME: New name wins when both exist; wrap writes only the new name; fallback carries a removal marker.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
W="$PLUGIN_DIR/skills/wrap/SKILL.md"
assert_file "$F" || exit 1
assert_grep "$F" "turbocharge-session.json" || exit 1
assert_grep "$F" "remove in 3.1"            || exit 1
# wrap must write the new name only
assert_no_grep "$W" "turbocharge-session" || exit 1

TMP="$(mktemp -d)"
cleanup() { cd /; rm -rf "$TMP"; }
cd "$TMP"; mkdir -p .claude

# Only the old file present → hook still emits it.
echo '{"marker":"OLD_SNAPSHOT_MARKER_5150"}' > .claude/turbocharge-session.json
OUT="$(bash "$F" 2>&1 || true)"
echo "$OUT" | grep -q "OLD_SNAPSHOT_MARKER_5150" \
    || { echo "    hook ignored .claude/turbocharge-session.json fallback"; cleanup; exit 1; }

# Both present → new name wins, old one is not emitted.
echo '{"marker":"NEW_SNAPSHOT_MARKER_6260"}' > .claude/turboflow-session.json
OUT="$(bash "$F" 2>&1 || true)"
cleanup
echo "$OUT" | grep -q "NEW_SNAPSHOT_MARKER_6260" || { echo "    new snapshot not emitted"; exit 1; }
echo "$OUT" | grep -q "OLD_SNAPSHOT_MARKER_5150" && { echo "    old snapshot emitted alongside new one"; exit 1; }
exit 0
