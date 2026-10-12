#!/usr/bin/env bash
# ABOUTME: Asserts no plugin component (skills, agents, hooks, templates, examples, images) names the 3.0–3.1 interim
# ABOUTME: name, except the deliberate compatibility references: the 3.x snapshot file and setup's 3.x block markers.
OLD="turbo""flow"
HITS=$(git -C "$PLUGIN_DIR" grep -n -i "$OLD" -- skills agents hooks templates examples images || true)
STRAY=$(printf '%s\n' "$HITS" | grep -v -E "${OLD}-session\.json|<!-- /?${OLD}:" | grep -v '^$' || true)
[ -z "$STRAY" ] || { echo "    interim name '$OLD' outside the compat references:"; echo "$STRAY" | sed 's/^/      /'; exit 1; }
exit 0
