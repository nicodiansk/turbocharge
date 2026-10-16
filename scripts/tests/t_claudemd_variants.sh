#!/usr/bin/env bash
# ABOUTME: Behavioral — SessionStart's CLAUDE.md/AGENTS.md nudges across every CLAUDE.md variant the docs count.
# ABOUTME: CLAUDE.md or .claude/CLAUDE.md → no nudge; CLAUDE.local.md + AGENTS.md → "May Not Be Loaded", from existence only.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
assert_file "$F" || exit 1

TMP="$(mktemp -d)"
cleanup() { cd /; rm -rf "$TMP"; }
cd "$TMP"

no_nudge() {  # no_nudge LABEL — fail if any CLAUDE.md/AGENTS.md nudge appears
    OUT="$(bash "$F" 2>&1 || true)"
    echo "$OUT" | grep -q "No CLAUDE.md Detected" && { echo "    $1: missing-CLAUDE.md nudge shown"; return 1; }
    echo "$OUT" | grep -q "AGENTS.md Detected"    && { echo "    $1: AGENTS.md-only nudge shown"; return 1; }
    echo "$OUT" | grep -q "AGENTS.md May Not Be Loaded" && { echo "    $1: not-loaded nudge shown"; return 1; }
    return 0
}

mkdir -p .claude
echo "# fixture" > .claude/CLAUDE.md
no_nudge ".claude/CLAUDE.md only" || { cleanup; exit 1; }
echo "# Agents" > AGENTS.md
no_nudge ".claude/CLAUDE.md + AGENTS.md" || { cleanup; exit 1; }
# The common team setup: a shared CLAUDE.md plus a personal CLAUDE.local.md and AGENTS.md.
echo "# local" > CLAUDE.local.md
no_nudge ".claude/CLAUDE.md + CLAUDE.local.md + AGENTS.md" || { cleanup; exit 1; }
rm -f .claude/CLAUDE.md
echo "# root" > CLAUDE.md
no_nudge "CLAUDE.md + CLAUDE.local.md + AGENTS.md" || { cleanup; exit 1; }
rm -f CLAUDE.md AGENTS.md

no_nudge "CLAUDE.local.md only" || { cleanup; exit 1; }

# CLAUDE.local.md + AGENTS.md, no CLAUDE.md: Claude Code skips AGENTS.md unless CLAUDE.local.md imports it — say so.
echo "# Agents" > AGENTS.md
OUT="$(bash "$F" 2>&1 || true)"
echo "$OUT" | grep -q "AGENTS.md May Not Be Loaded" || { echo "    CLAUDE.local.md + AGENTS.md: not-loaded nudge missing"; cleanup; exit 1; }
echo "$OUT" | grep -qE "No CLAUDE.md Detected|AGENTS.md Detected, No CLAUDE.md" \
    && { echo "    CLAUDE.local.md + AGENTS.md: wrong nudge shown"; cleanup; exit 1; }
# 3.5.2: the hook never reads CLAUDE.local.md (a personal file; the directory held the plugin for "credential forward").
# Its output is the same whatever the file holds, and the same when the file can't be read at all.
printf '@AGENTS.md\n# local\n' > CLAUDE.local.md
[ "$(bash "$F" 2>&1 || true)" = "$OUT" ] || { echo "    hook output depends on CLAUDE.local.md's content"; cleanup; exit 1; }
chmod 000 CLAUDE.local.md
[ "$(bash "$F" 2>&1 || true)" = "$OUT" ] || { echo "    hook output changes when CLAUDE.local.md is unreadable"; chmod 644 CLAUDE.local.md; cleanup; exit 1; }
chmod 644 CLAUDE.local.md
grep -nE '(grep|cat|sed|awk|head|tail|read|<)[^#]*CLAUDE\.local\.md' "$F" | grep -v '^[0-9]*:[[:space:]]*#' \
    && { echo "    session-start.sh reads CLAUDE.local.md"; cleanup; exit 1; }
rm -f CLAUDE.local.md AGENTS.md

N="$PLUGIN_DIR/hooks/agentsmd-not-loaded-nudge.md"
assert_file "$N" || { cleanup; exit 1; }
grep -qF '@AGENTS.md' "$N" && grep -qF '/turbocharge:setup' "$N" \
    || { echo "    not-loaded nudge must name @AGENTS.md and /turbocharge:setup"; cleanup; exit 1; }
[ "$(wc -l < "$N")" -le 10 ] || { echo "    not-loaded nudge longer than 10 lines"; cleanup; exit 1; }

# Regression guard: nothing present → plain nudge still shows.
OUT="$(bash "$F" 2>&1 || true)"
cleanup
echo "$OUT" | grep -q "No CLAUDE.md Detected" || { echo "    plain nudge missing when no CLAUDE.md variant exists"; exit 1; }
exit 0
