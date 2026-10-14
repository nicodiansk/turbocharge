#!/usr/bin/env bash
# ABOUTME: Behavioral test for hooks/builder-exit-gate.sh and its registration in hooks.json.
# ABOUTME: Builds a fixture repo (path with a space) plus a fixture builder transcript and feeds hook JSON on stdin.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
GATE="$PLUGIN_DIR/hooks/builder-exit-gate.sh"
if ! command -v jq >/dev/null 2>&1; then echo "    jq not installed, skipping"; exit 0; fi
assert_file "$GATE" || exit 1

ROOT="$(mktemp -d)"; trap 'rm -rf "$ROOT"' EXIT
REPO="$ROOT/my repo"; mkdir -p "$REPO/build"
git -C "$REPO" init -q
git -C "$REPO" config user.email t@example.com; git -C "$REPO" config user.name t
printf 'build/\n' > "$REPO/.gitignore"; echo one > "$REPO/a.txt"
git -C "$REPO" add -A; git -C "$REPO" commit -q -m init

SESSION="$ROOT/proj/sess1"; AID="agentx1"
mkdir -p "$SESSION/subagents"
TR="$SESSION/subagents/agent-$AID.jsonl"
tool() { jq -nc --arg n "$1" --arg p "$2" '{type:"assistant",message:{content:[{type:"tool_use",name:$n,input:{file_path:$p}}]}}'; }
make_tr() { { tool Edit "$REPO/a.txt"; tool Write "$REPO/new.txt"; tool Write "$REPO/build/out.txt"; } > "$TR"; }
make_tr

dirty()  { echo two > "$REPO/a.txt"; echo n > "$REPO/new.txt"; echo o > "$REPO/build/out.txt"; }
clean()  { git -C "$REPO" checkout -q -- a.txt; rm -f "$REPO/new.txt" "$REPO/other.txt"; }
# input EVENT AGENT_TYPE ACTIVE [extra jq filter]
input() {
    jq -nc --arg ev "$1" --arg at "$2" --argjson act "$3" --arg cwd "$REPO" --arg tp "$SESSION.jsonl" --arg atp "$TR" --arg aid "$AID" \
      '{hook_event_name:$ev,agent_type:$at,agent_id:$aid,cwd:$cwd,transcript_path:$tp,agent_transcript_path:$atp}
       + (if $ev=="SubagentStop" then {stop_hook_active:$act} else {tool_name:"SubagentHandback"} end)' | jq -c "${4:-.}"
}
run() { OUT="$ROOT/out"; ERR="$ROOT/err"; bash "$GATE" >"$OUT" 2>"$ERR"; RC=$?; }
fail() { echo "    $1"; echo "    stderr: $(cat "$ERR")"; exit 1; }
expect_block() {
    [ "$RC" = 2 ] || fail "$1: expected exit 2, got $RC"
    for s in 'commit these by pathspec' 'full report again' 'a.txt' 'new.txt'; do grep -q "$s" "$ERR" || fail "$1: stderr lacks '$s'"; done
    ! grep -q 'out.txt' "$ERR" || fail "$1: ignored out.txt reported"
    ! grep -q 'No such file' "$ERR" || fail "$1: stderr contains 'No such file'"
}
expect_quiet() { [ "$RC" = 0 ] || fail "$1: expected exit 0, got $RC"; [ ! -s "$OUT" ] && [ ! -s "$ERR" ] || fail "$1: expected silence"; }

dirty
input SubagentStop turbocharge:builder false > "$ROOT/in"; run < "$ROOT/in"; expect_block "dirty stop"
clean; run < "$ROOT/in"; expect_quiet "clean"
dirty; run < <(input SubagentStop turbocharge:builder true); expect_quiet "stop_hook_active"
run < <(input SubagentStop turbocharge:task-reviewer false); expect_quiet "other agent"
mv "$TR" "$TR.gone"; run < "$ROOT/in"; expect_quiet "missing transcript"; mv "$TR.gone" "$TR"
clean; echo x > "$REPO/other.txt"; run < "$ROOT/in"; expect_quiet "other lane's file"
clean; echo o > "$REPO/build/out.txt"; run < "$ROOT/in"; expect_quiet "ignored only"

dirty
# derived transcript path (no agent_transcript_path)
run < <(input SubagentStop turbocharge:builder false 'del(.agent_transcript_path)'); expect_block "derived path"
# ~/ path
HOME_SAVE="$HOME"; export HOME="$ROOT"
run < <(input SubagentStop turbocharge:builder false '.agent_transcript_path="~/proj/sess1/subagents/agent-'$AID'.jsonl"'); expect_block "tilde path"
run < <(input SubagentStop turbocharge:builder false 'del(.agent_transcript_path)|.transcript_path="~/proj/sess1.jsonl"'); expect_block "tilde transcript_path"
export HOME="$HOME_SAVE"

# PreToolUse
run < <(input PreToolUse turbocharge:builder false 'del(.agent_transcript_path)'); expect_block "pretooluse"
run < <(input PreToolUse turbocharge:researcher false 'del(.agent_transcript_path)'); expect_quiet "pretooluse other agent"
run < <(input PreToolUse turbocharge:builder false 'del(.agent_transcript_path)|.tool_name="Bash"'); expect_quiet "pretooluse other tool"

# Transcript entries in the shapes recorded from real builder transcripts (3.4.0 spike).
GATE_TXT='turbocharge exit gate: commit these by pathspec before you stop'
prompt_e() { jq -nc --arg pid "$1" --arg t "${2:-Implement the lane}" '{type:"user",promptId:$pid,message:{content:$t}}'; }
resume_e() { jq -nc --arg pid "$1" '{type:"user",isMeta:true,origin:{kind:"coordinator"},promptId:$pid,message:{content:"The coordinator sent a message while you were working:\nfix it\n\nAddress this before completing your current task."}}'; }
deny_pre_e() { jq -nc --arg pid "$1" --arg g "$GATE_TXT" '{type:"user",promptId:$pid,toolDenialKind:"permission-rule",message:{content:[{type:"tool_result",is_error:true,content:("PreToolUse:SubagentHandback hook error: [bash \"/p/hooks/builder-exit-gate.sh\"]: " + $g)}]}}'; }
deny_stop_e() { jq -nc --arg pid "$1" --arg g "$GATE_TXT" '{type:"user",isMeta:true,promptId:$pid,message:{content:("Stop hook feedback:\n[bash \"/p/hooks/builder-exit-gate.sh\"]: " + $g)}}'; }
# tr_of ENTRY... : rebuild the transcript from the edit entries plus the given lines
tr_of() { make_tr; for e in "$@"; do printf '%s\n' "$e" >> "$TR"; done; }
pre() { run < <(input PreToolUse turbocharge:builder false 'del(.agent_transcript_path)'); }
dirty

# block once: the gate's own denial follows the latest prompt
tr_of "$(prompt_e p1)" "$(deny_pre_e p1)"; pre; expect_quiet "pretooluse denial"
tr_of "$(prompt_e p1)" "$(deny_stop_e p1)"; run < <(input SubagentStop turbocharge:builder false); expect_quiet "stop denial"
# no promptId anywhere: falls back to entry order
tr_of "$(prompt_e p1 | jq -c 'del(.promptId)')" "$(deny_pre_e x | jq -c 'del(.promptId)')"; pre; expect_quiet "denial without promptId"
# denial alone (no prompt entry) still counts as blocked once
tr_of "$(deny_pre_e p1)"; pre; expect_quiet "denial without prompt entry"

# quoting the gate's text is not the gate's denial
tr_of "$(jq -nc --arg g "$GATE_TXT" '{type:"user",message:{content:[{type:"tool_result",content:("- Fixed: " + $g)}]}}')"
pre; expect_block "read result quoting the gate"
tr_of "$(jq -nc --arg g "$GATE_TXT" '{type:"user",message:{content:[{type:"tool_result",is_error:true,content:("Error: " + $g)}]}}')"
pre; expect_block "error result quoting the gate"
tr_of "$(jq -nc '{type:"assistant",message:{content:[{type:"text",text:"turbocharge exit gate: commit these"}]}}')"
pre; expect_block "assistant text quoting the gate"
tr_of "$(prompt_e p1 'Note: the turbocharge exit gate: commit these by pathspec message may appear')"
pre; expect_block "dispatch prompt quoting the gate"

# a builder resumed for a fix round is checked again
tr_of "$(prompt_e p1)" "$(deny_pre_e p1)" "$(resume_e p2)" "$(tool Edit "$REPO/a.txt")"
pre; expect_block "resume after denial (PreToolUse)"
tr_of "$(prompt_e p1)" "$(deny_stop_e p1)" "$(resume_e p2)" "$(tool Edit "$REPO/a.txt")"
run < <(input SubagentStop turbocharge:builder false); expect_block "resume after denial (SubagentStop)"
tr_of "$(prompt_e p1 | jq -c 'del(.promptId)')" "$(deny_pre_e x | jq -c 'del(.promptId)')" "$(resume_e x | jq -c 'del(.promptId)')"
pre; expect_block "resume after denial without promptId"
# ...and silent again once its own denial follows the resume
tr_of "$(prompt_e p1)" "$(deny_pre_e p1)" "$(resume_e p2)" "$(deny_pre_e p2)"
pre; expect_quiet "second denial after resume"

# half-written last line is skipped, not fatal
tr_of "$(prompt_e p1)"; printf '{"type":"user","message":{"cont' >> "$TR"
pre; expect_block "truncated last line"
tr_of "$(prompt_e p1)" "$(deny_pre_e p1)"; printf '{"type":"user","message":{"cont' >> "$TR"
pre; expect_quiet "truncated last line after denial"
make_tr

# malformed input fails open
echo 'not json' | run; [ "$RC" = 0 ] || fail "malformed input should exit 0"

# registration
H="$PLUGIN_DIR/hooks/hooks.json"
assert_jq "$H" '.hooks.SubagentStop[0].matcher == "^turbocharge:builder$"' || exit 1
assert_jq "$H" '.hooks.PreToolUse[0].matcher == "^SubagentHandback$"' || exit 1
assert_jq "$H" '.hooks.SubagentStop[0].hooks[0].command | contains("builder-exit-gate.sh")' || exit 1
assert_jq "$H" '.hooks.PreToolUse[0].hooks[0].command | contains("builder-exit-gate.sh")' || exit 1
assert_jq "$H" '.hooks.SessionStart' || exit 1
exit 0
