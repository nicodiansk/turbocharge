#!/usr/bin/env bash
# ABOUTME: Asserts SessionStart reads only .claude/turbocharge-session.json (3.0.x legacy fallback removed).
# ABOUTME: A lone pre-3.0.0 turbocharge-session.json is ignored; hook and wrap never name it.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
W="$PLUGIN_DIR/skills/wrap/SKILL.md"
assert_file "$F" || exit 1
assert_no_grep "$F" "turbocharge-session" || exit 1
assert_no_grep "$W" "turbocharge-session" || exit 1

TMP="$(mktemp -d)"
cleanup() { cd /; rm -rf "$TMP"; }
cd "$TMP"; mkdir -p .claude

# Only the legacy file present -> NOT emitted.
echo '{"marker":"OLD_SNAPSHOT_MARKER_5150"}' > .claude/turbocharge-session.json
OUT="$(bash "$F" 2>&1 || true)"
echo "$OUT" | grep -q "OLD_SNAPSHOT_MARKER_5150" \
    && { echo "    hook still emits legacy .claude/turbocharge-session.json"; cleanup; exit 1; }

# New file present -> emitted.
echo '{"marker":"NEW_SNAPSHOT_MARKER_6260"}' > .claude/turbocharge-session.json
OUT="$(bash "$F" 2>&1 || true)"
cleanup
echo "$OUT" | grep -q "NEW_SNAPSHOT_MARKER_6260" || { echo "    new snapshot not emitted"; exit 1; }
echo "$OUT" | grep -q "OLD_SNAPSHOT_MARKER_5150" && { echo "    legacy snapshot emitted"; exit 1; }
exit 0
