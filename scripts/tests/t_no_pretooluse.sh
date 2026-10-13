#!/usr/bin/env bash
# ABOUTME: Guards against a broad PreToolUse hook; the 2.4.0 Read hook (pretool-read-codemap) stays gone.
# ABOUTME: Allows exactly one PreToolUse entry: matcher ^SubagentHandback$, whose only command runs builder-exit-gate.sh.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/hooks.json"
assert_file "$F" || exit 1
assert_no_grep "$F" "pretool-read-codemap" || exit 1
[ ! -f "$PLUGIN_DIR/hooks/pretool-read-codemap.sh" ] || { echo "    pretool-read-codemap.sh still exists"; exit 1; }
if command -v jq >/dev/null 2>&1; then
    jq -e '.hooks.SessionStart' "$F" >/dev/null || { echo "    SessionStart missing"; exit 1; }
    jq -e '.hooks.Stop' "$F" >/dev/null 2>&1    && { echo "    Stop hook should be removed"; exit 1; }
    jq -e '(.hooks.PreToolUse | length) == 1
        and .hooks.PreToolUse[0].matcher == "^SubagentHandback$"
        and (.hooks.PreToolUse[0].hooks | length) == 1
        and (.hooks.PreToolUse[0].hooks[0].command | contains("builder-exit-gate.sh"))' "$F" >/dev/null \
        || { echo "    PreToolUse must be exactly one ^SubagentHandback\$ entry running builder-exit-gate.sh"; exit 1; }
else
    assert_grep "$F" '\^SubagentHandback\$' || exit 1
fi
exit 0
