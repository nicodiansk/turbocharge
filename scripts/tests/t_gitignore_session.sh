#!/usr/bin/env bash
# ABOUTME: Tests .gitignore contains .claude/turbocharge-session.json specifically.
# ABOUTME: Verifies we don't exclude all of .claude/ (settings.json is team-shared).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/.gitignore"
assert_file "$F" || exit 1
grep -q '\.claude/turbocharge-session\.json' "$F" || { echo "    .claude/turbocharge-session.json not in .gitignore"; exit 1; }
# Must NOT exclude all of .claude/ (settings.json is team-shared)
if grep -qE '^\.claude/?\r?$' "$F"; then echo "    .gitignore excludes all of .claude/ — would hide team-shared settings.json"; exit 1; fi
# Legacy pre-3.0.0 snapshot name is no longer read by SessionStart, so its ignore line is gone.
if grep -q 'turbocharge-session' "$F"; then echo "    legacy turbocharge-session line still in .gitignore"; exit 1; fi
