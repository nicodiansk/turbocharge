#!/usr/bin/env bash
# ABOUTME: Stop hook — nudges the model to OFFER /turbocharge:wrap at natural stops.
# ABOUTME: Emits hookSpecificOutput.additionalContext so the model is steered, not just printed at.
# ABOUTME: Read-only — emits a single JSON object to stdout; no writes, no network, no mutation.

MSG="If this is a natural stopping point, the session is ending, or context is getting full, offer /turbocharge:wrap to capture session state (decisions, progress, resume prompt) for seamless resumption. Do not run it unprompted — offer it."

# Emit structured Stop output. additionalContext is injected into the model's context
# so the nudge actually steers behavior instead of only printing to the transcript.
if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$MSG" '{
    hookSpecificOutput: {
      hookEventName: "Stop",
      additionalContext: $ctx
    }
  }'
else
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "additionalContext": "$MSG"
  }
}
EOF
fi
