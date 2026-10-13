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
# block once: marker in transcript
jq -nc '{type:"user",message:{content:[{type:"tool_result",is_error:true,content:"turbocharge exit gate: commit these"}]}}' >> "$TR"
run < <(input PreToolUse turbocharge:builder false 'del(.agent_transcript_path)'); expect_quiet "pretooluse marker"
run < <(input SubagentStop turbocharge:builder false); expect_quiet "stop marker"
# malformed input fails open
echo 'not json' | run; [ "$RC" = 0 ] || fail "malformed input should exit 0"

exit 0
