#!/usr/bin/env bash
# ABOUTME: Builder exit gate — blocks a turbocharge:builder's stop (SubagentStop) or handback (PreToolUse SubagentHandback) once while files it edited are uncommitted.
# ABOUTME: Reads hook JSON on stdin with jq; checks only paths this builder edited via git status. Fails open (exit 0) on anything unexpected.
# ABOUTME: Read-only — writes nothing, no network, runs only jq and git. Exit 2 sends stderr to the builder as its next instruction.
# ABOUTME: Known limit — the transcript is written asynchronously, so the last turn (the report) can be missing; the edits come turns earlier.
set -u

command -v jq >/dev/null 2>&1 || exit 0

MARKER="turbocharge exit gate"
EDIT_TOOLS='["Edit","Write","MultiEdit","NotebookEdit"]'

INPUT="$(cat)"
field() { printf '%s' "$INPUT" | jq -r "$1 // empty" 2>/dev/null | tr -d '\r'; }

[ "$(field .agent_type)" = "turbocharge:builder" ] || exit 0
event="$(field .hook_event_name)"
case "$event" in
    SubagentStop) [ "$(field .stop_hook_active)" = "true" ] && exit 0 ;;
    PreToolUse)   [ "$(field .tool_name)" = "SubagentHandback" ] || exit 0 ;;
    *) exit 0 ;;
esac

expand_home() { case "$1" in "~/"*) printf '%s' "${HOME:-}/${1#\~/}" ;; *) printf '%s' "$1" ;; esac; }

transcript="$(expand_home "$(field .agent_transcript_path)")"
if [ -z "$transcript" ]; then
    base="$(expand_home "$(field .transcript_path)")"
    agent_id="$(field .agent_id)"
    [ -n "$base" ] && [ -n "$agent_id" ] || exit 0
    transcript="${base%.jsonl}/subagents/agent-${agent_id}.jsonl"
fi
[ -r "$transcript" ] || exit 0

# Block once per builder: our own earlier denial is in the transcript.
grep -q "$MARKER" "$transcript" 2>/dev/null && exit 0

cwd="$(field .cwd)"
[ -n "$cwd" ] || exit 0

paths="$(jq -r --argjson tools "$EDIT_TOOLS" '
    select(.type == "assistant") | .message.content? // empty | arrays | .[]
    | select(.type == "tool_use" and (.name as $n | $tools | index($n)))
    | .input.file_path // .input.notebook_path // empty' "$transcript" 2>/dev/null | tr -d '\r' | sort -u)"
[ -n "$paths" ] || exit 0

dirty=""
while IFS= read -r p; do
    [ -n "$p" ] || continue
    status="$(git -C "$cwd" status --porcelain -- "$p" 2>/dev/null)" || continue
    [ -n "$status" ] && dirty="${dirty}  ${p}"$'\n'
done <<< "$paths"
[ -n "$dirty" ] || exit 0

{
    echo "$MARKER: commit these by pathspec before you stop (git add <new files>; git commit -m \"<message>\" -- <files>), or say why they must stay uncommitted. Then give your full report again, ending with the Status line — the orchestrator sees only your last message:"
    printf '%s' "$dirty"
} >&2
exit 2
