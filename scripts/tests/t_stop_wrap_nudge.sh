#!/usr/bin/env bash
# ABOUTME: Asserts the Stop wrap nudge emits hookSpecificOutput.additionalContext JSON
# ABOUTME: (context-aware), stays read-only, and is wired into hooks.json on Stop.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/hooks/stop-wrap-reminder.sh"
H="$PLUGIN_DIR/hooks/hooks.json"
assert_file "$S" || exit 1

# Emits structured Stop output (not a bare cat of prose)
assert_grep "$S" "hookSpecificOutput" || exit 1
assert_grep "$S" "additionalContext"  || exit 1
assert_grep "$S" "turbocharge:wrap"   || exit 1

# Read-only attestation (mirrors session-start.sh convention) — no writes/network
assert_grep "$S" "[Rr]ead-only" || exit 1

# Valid JSON when executed (the script prints a single JSON object to stdout)
if command -v jq >/dev/null 2>&1; then
  bash "$S" | jq -e '.hookSpecificOutput.hookEventName == "Stop"' >/dev/null \
    || { echo "    stop hook did not emit valid Stop JSON"; exit 1; }
  bash "$S" | jq -e '.hookSpecificOutput.additionalContext | type == "string"' >/dev/null \
    || { echo "    additionalContext missing/not a string"; exit 1; }
else
  echo "    jq not installed, skipping JSON-shape assertions"
fi

# hooks.json Stop must invoke the .sh, not cat the old .md
assert_grep    "$H" "stop-wrap-reminder.sh" || exit 1
assert_no_grep "$H" "stop-wrap-reminder.md" || exit 1
