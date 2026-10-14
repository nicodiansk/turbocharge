#!/usr/bin/env bash
# ABOUTME: Builder exit gate — blocks a turbocharge:builder's stop (SubagentStop) or handback (PreToolUse SubagentHandback) once while files it edited are uncommitted.
# ABOUTME: Reads hook JSON on stdin with jq; checks only paths this builder edited via git status. Fails open (exit 0) on anything unexpected.
# ABOUTME: Read-only — writes nothing, no network, runs only jq and git. Exit 2 sends stderr to the builder as its next instruction.
# ABOUTME: Known limit — the transcript is written asynchronously, so the last turn (the report) can be missing; the edits come turns earlier.
# ABOUTME: Known limit — blocks once per prompt: silent when its own denial follows the builder's latest prompt (dispatch or SendMessage resume).
# ABOUTME: Known limit — a file that was already dirty before the builder started is listed too; the message's "or say why" covers it.
# ABOUTME: Known limit — a relative path resolves against the hook's cwd, which can differ from the builder's own directory (Edit and Write pass absolute paths).
set -u

command -v jq >/dev/null 2>&1 || exit 0

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

# Block once per prompt: silent only when our own denial follows the builder's latest prompt
# (its dispatch, or a SendMessage resume). Quoting the gate's text elsewhere doesn't count.
# Lines are parsed one by one so a half-written last line is skipped.
OWN_DENIAL_FILTER='
def is_denial: .type == "user" and (
  (.isMeta == true and (.message.content | type) == "string"
     and (.message.content | test("^Stop hook feedback:\n\\[[^\n]*\\]: turbocharge exit gate:")))
  or ((.message.content | type) == "array"
     and any(.message.content[]; type == "object" and .type == "tool_result" and .is_error == true and (.content | type) == "string"
       and (.content | test("^PreToolUse:SubagentHandback hook error: \\[[^\n]*\\]: turbocharge exit gate:")))));
def is_prompt: .type == "user" and (.message.content | type) == "string"
  and ((.isMeta | not) or (.origin.kind? == "coordinator"));
[inputs | (fromjson? // empty) | select(type == "object")] as $e
| ([$e[] | select(.type == "user") | .promptId // empty] | last) as $cur
| if $cur != null then any($e[]; is_denial and .promptId == $cur)
  else (([$e | to_entries[] | select(.value | is_prompt) | .key] | max // -1) as $p
       | ([$e | to_entries[] | select(.value | is_denial) | .key] | max // -1) as $d | $d > $p) end'
[ "$(jq -R -n -r "$OWN_DENIAL_FILTER" "$transcript" 2>/dev/null)" = "true" ] && exit 0

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
    np="${p//\\//}"
    case "$np" in /*|[A-Za-z]:/*) ;; *) np="$cwd/$np" ;; esac
    dir="$(dirname "$np")"
    [ -d "$dir" ] || continue
    status="$(git -C "$dir" status --porcelain -- "$np" 2>/dev/null)" || continue
    [ -n "$status" ] && dirty="${dirty}  ${p}"$'\n'
done <<< "$paths"
[ -n "$dirty" ] || exit 0

{
    echo "turbocharge exit gate: commit these by pathspec before you stop (git add <new files>; git commit -m \"<message>\" -- <files>), or say why they must stay uncommitted. Then give your full report again, ending with the Status line — the orchestrator sees only your last message:"
    printf '%s' "$dirty"
} >&2
exit 2
