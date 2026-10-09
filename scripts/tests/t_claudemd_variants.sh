#!/usr/bin/env bash
# ABOUTME: Behavioral — SessionStart treats CLAUDE.md, .claude/CLAUDE.md and CLAUDE.local.md as "a CLAUDE.md exists".
# ABOUTME: Matches the docs' AGENTS.md rule; a project using any of them must get neither setup nudge.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
assert_file "$F" || exit 1

TMP="$(mktemp -d)"
cleanup() { cd /; rm -rf "$TMP"; }
cd "$TMP"

no_nudge() {  # no_nudge LABEL — fail if either CLAUDE.md nudge appears
    OUT="$(bash "$F" 2>&1 || true)"
    echo "$OUT" | grep -q "No CLAUDE.md Detected" && { echo "    $1: missing-CLAUDE.md nudge shown"; return 1; }
    echo "$OUT" | grep -q "AGENTS.md Detected"    && { echo "    $1: AGENTS.md-only nudge shown"; return 1; }
    return 0
}

mkdir -p .claude
echo "# fixture" > .claude/CLAUDE.md
no_nudge ".claude/CLAUDE.md only" || { cleanup; exit 1; }
echo "# Agents" > AGENTS.md
no_nudge ".claude/CLAUDE.md + AGENTS.md" || { cleanup; exit 1; }
rm -f .claude/CLAUDE.md AGENTS.md

echo "# local" > CLAUDE.local.md
no_nudge "CLAUDE.local.md only" || { cleanup; exit 1; }
rm -f CLAUDE.local.md

# Regression guard: nothing present → plain nudge still shows.
OUT="$(bash "$F" 2>&1 || true)"
cleanup
echo "$OUT" | grep -q "No CLAUDE.md Detected" || { echo "    plain nudge missing when no CLAUDE.md variant exists"; exit 1; }
exit 0
