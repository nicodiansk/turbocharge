#!/usr/bin/env bash
# ABOUTME: Guards the PreToolUse scope; the 2.4.0 Read hook (pretool-read-codemap) stays gone.
# ABOUTME: Allows exactly two PreToolUse entries: ^SubagentHandback$ (builder-exit-gate.sh) and Bash (git-guard.sh, timeout 30 s or less).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/hooks.json"
assert_file "$F" || exit 1
assert_no_grep "$F" "pretool-read-codemap" || exit 1
[ ! -f "$PLUGIN_DIR/hooks/pretool-read-codemap.sh" ] || { echo "    pretool-read-codemap.sh still exists"; exit 1; }
if command -v jq >/dev/null 2>&1; then
    jq -e '.hooks.SessionStart' "$F" >/dev/null || { echo "    SessionStart missing"; exit 1; }
    jq -e '.hooks.Stop' "$F" >/dev/null 2>&1    && { echo "    Stop hook should be removed"; exit 1; }
    SCOPE='(.hooks.PreToolUse | length) == 2
        and ([.hooks.PreToolUse[] | select(.matcher == "^SubagentHandback$"
            and (.hooks | length) == 1 and (.hooks[0].command | contains("builder-exit-gate.sh")))] | length) == 1
        and ([.hooks.PreToolUse[] | select(.matcher == "Bash"
            and (.hooks | length) == 1 and (.hooks[0].command | contains("git-guard.sh"))
            and (.hooks[0].timeout // 9999) <= 30)] | length) == 1'
    jq -e "$SCOPE" "$F" >/dev/null \
        || { echo "    PreToolUse must be exactly ^SubagentHandback\$ (exit gate) and Bash (git-guard)"; exit 1; }
    # A third entry, whatever its matcher, must fail the same check.
    for m in Read '*' '' '.*'; do
        jq --arg m "$m" '.hooks.PreToolUse += [{matcher:$m,hooks:[{type:"command",command:"x"}]}]' "$F" | jq -e "$SCOPE" >/dev/null 2>&1 \
            && { echo "    a third PreToolUse entry (matcher '$m') passed the scope check"; exit 1; }
    done
else
    assert_grep "$F" '\^SubagentHandback\$' || exit 1
    assert_grep "$F" '"matcher": "Bash"' || exit 1
fi
exit 0
