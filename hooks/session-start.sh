#!/usr/bin/env bash
# ABOUTME: SessionStart hook for turbocharge plugin
# ABOUTME: Loads using-turbocharge skill into conversation context on startup

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read using-turbocharge content
using_turbocharge_content=$(cat "${PLUGIN_ROOT}/skills/using-turbocharge/SKILL.md" 2>&1 || echo "Error reading using-turbocharge skill")

# Escape string for JSON embedding using bash parameter substitution.
# Each ${s//old/new} is a single C-level pass - orders of magnitude
# faster than a character-by-character loop.
escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

using_turbocharge_escaped=$(escape_for_json "$using_turbocharge_content")

# Create .turbocharge/memory/ in the project working directory if it doesn't exist
mkdir -p ".turbocharge/memory" 2>/dev/null || true

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nYou have turbocharge skills.\n\n**Below is the full content of your 'turbocharge:using-turbocharge' skill - your introduction to using skills. For all other skills, use the 'Skill' tool:**\n\n${using_turbocharge_escaped}\n\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0
