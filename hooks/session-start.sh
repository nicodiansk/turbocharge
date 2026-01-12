#!/usr/bin/env bash
# ABOUTME: SessionStart hook for turbocharge plugin
# ABOUTME: Loads using-turbocharge skill into conversation context on startup

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read using-turbocharge content
using_turbocharge_content=$(cat "${PLUGIN_ROOT}/skills/using-turbocharge/SKILL.md" 2>&1 || echo "Error reading using-turbocharge skill")

# Escape outputs for JSON using pure bash
escape_for_json() {
    local input="$1"
    local output=""
    local i char
    for (( i=0; i<${#input}; i++ )); do
        char="${input:$i:1}"
        case "$char" in
            $'\\') output+='\\' ;;
            '"') output+='\"' ;;
            $'\n') output+='\n' ;;
            $'\r') output+='\r' ;;
            $'\t') output+='\t' ;;
            *) output+="$char" ;;
        esac
    done
    printf '%s' "$output"
}

using_turbocharge_escaped=$(escape_for_json "$using_turbocharge_content")

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
