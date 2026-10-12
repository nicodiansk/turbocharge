#!/usr/bin/env bash
# ABOUTME: Asserts SessionStart reads .claude/turbocharge-session.json (2.x and 3.2+), falling back to the 3.0–3.1 name
# ABOUTME: .claude/turboflow-session.json; the turbocharge name wins when both exist; wrap writes only the turbocharge name.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
W="$PLUGIN_DIR/skills/wrap/SKILL.md"
assert_file "$F" || exit 1
assert_grep "$F" "turbocharge-session.json" || exit 1
assert_grep "$F" "turboflow-session.json"   || exit 1
# wrap writes only the turbocharge name and retires the interim 3.x file.
grep -qF 'Write `.claude/turbocharge-session.json`' "$W" || { echo "    wrap must write .claude/turbocharge-session.json"; exit 1; }
grep -qF 'turboflow-session.json` from 3.0–3.1 exists, delete it' "$W" || { echo "    wrap must delete the 3.x snapshot it supersedes"; exit 1; }

TMP="$(mktemp -d)"
cleanup() { cd /; rm -rf "$TMP"; }
cd "$TMP"; mkdir -p .claude

# Only the 3.x file present -> emitted (fallback).
echo '{"marker":"FLOW_SNAPSHOT_5150"}' > .claude/turboflow-session.json
OUT="$(bash "$F" 2>&1 || true)"
echo "$OUT" | grep -q "FLOW_SNAPSHOT_5150" \
    || { echo "    3.x .claude/turboflow-session.json not read as a fallback"; cleanup; exit 1; }

# Both present, turbocharge newer (a 3.2+ /wrap) -> it wins, the 3.x one is not emitted.
echo '{"marker":"CHARGE_SNAPSHOT_6260"}' > .claude/turbocharge-session.json
touch -d '2026-07-01' .claude/turboflow-session.json
OUT="$(bash "$F" 2>&1 || true)"
echo "$OUT" | grep -q "CHARGE_SNAPSHOT_6260" || { echo "    newer turbocharge snapshot not emitted"; cleanup; exit 1; }
echo "$OUT" | grep -q "FLOW_SNAPSHOT_5150"   && { echo "    3.x snapshot emitted alongside the turbocharge one"; cleanup; exit 1; }

# Both present, turboflow newer: a stale 2.x file was left behind by 3.0-3.1 (whose /wrap wrote only the
# turboflow name) -> the newer 3.x snapshot wins.
echo '{"marker":"STALE_2X_7370"}' > .claude/turbocharge-session.json
touch -d '2026-07-01' .claude/turbocharge-session.json
echo '{"marker":"FRESH_3X_8480"}' > .claude/turboflow-session.json
OUT="$(bash "$F" 2>&1 || true)"
cleanup
echo "$OUT" | grep -q "FRESH_3X_8480" || { echo "    newer 3.x snapshot lost to a stale 2.x one"; exit 1; }
echo "$OUT" | grep -q "STALE_2X_7370" && { echo    "    stale 2.x snapshot emitted"; exit 1; }
exit 0
