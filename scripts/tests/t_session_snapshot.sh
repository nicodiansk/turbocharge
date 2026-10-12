#!/usr/bin/env bash
# ABOUTME: Asserts SessionStart reads .claude/turbocharge-session.json (2.x and 3.2+), falling back to the 3.0–3.1 name
# ABOUTME: .claude/turboflow-session.json; the turbocharge name wins when both exist; wrap writes only the turbocharge name.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
W="$PLUGIN_DIR/skills/wrap/SKILL.md"
assert_file "$F" || exit 1
assert_grep "$F" "turbocharge-session.json" || exit 1
assert_grep "$F" "turboflow-session.json"   || exit 1
assert_no_grep "$W" "turboflow-session"     || exit 1

TMP="$(mktemp -d)"
cleanup() { cd /; rm -rf "$TMP"; }
cd "$TMP"; mkdir -p .claude

# Only the 3.x file present -> emitted (fallback).
echo '{"marker":"FLOW_SNAPSHOT_5150"}' > .claude/turboflow-session.json
OUT="$(bash "$F" 2>&1 || true)"
echo "$OUT" | grep -q "FLOW_SNAPSHOT_5150" \
    || { echo "    3.x .claude/turboflow-session.json not read as a fallback"; cleanup; exit 1; }

# Both present -> the turbocharge file wins, the 3.x one is not emitted.
echo '{"marker":"CHARGE_SNAPSHOT_6260"}' > .claude/turbocharge-session.json
OUT="$(bash "$F" 2>&1 || true)"
cleanup
echo "$OUT" | grep -q "CHARGE_SNAPSHOT_6260" || { echo "    turbocharge snapshot not emitted"; exit 1; }
echo "$OUT" | grep -q "FLOW_SNAPSHOT_5150"   && { echo "    3.x snapshot emitted alongside the turbocharge one"; exit 1; }
exit 0
