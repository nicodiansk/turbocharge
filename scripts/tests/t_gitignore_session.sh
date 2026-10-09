#!/usr/bin/env bash
# ABOUTME: Tests .gitignore contains .claude/turboflow-session.json specifically.
# ABOUTME: Verifies we don't exclude all of .claude/ (settings.json is team-shared).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/.gitignore"
assert_file "$F" || exit 1
grep -q '\.claude/turboflow-session\.json' "$F" || { echo "    .claude/turboflow-session.json not in .gitignore"; exit 1; }
# Must NOT exclude all of .claude/ (settings.json is team-shared)
if grep -qE '^\.claude/?\r?$' "$F"; then echo "    .gitignore excludes all of .claude/ — would hide team-shared settings.json"; exit 1; fi
# Pre-3.0.0 snapshot name stays ignored while SessionStart still reads it (3.0.x fallback; remove in 3.1).
grep -q '\.claude/turbocharge-session\.json' "$F" || { echo "    legacy .claude/turbocharge-session.json not in .gitignore"; exit 1; }
