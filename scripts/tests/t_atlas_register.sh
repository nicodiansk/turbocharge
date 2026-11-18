#!/usr/bin/env bash
# ABOUTME: Asserts atlas states its rule with the reason, words old sections as Update-mode cleanup, and commits only where git tracks it.
# ABOUTME: 3.8.0 prompt hygiene, handed over from stream A: F22, F26, F31, and F34's section list in the session-start hint.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
A="$PLUGIN_DIR/skills/atlas/SKILL.md"; H="$PLUGIN_DIR/hooks/session-start.sh"
for f in "$A" "$H"; do assert_file "$f" || exit 1; done
rc=0
BODY=$(tr -d '\r' < "$A")
for p in 'NO ATLAS WITHOUT' 'Removed from prior format' '**Added:**'; do
    ! printf '%s\n' "$BODY" | grep -qF -- "$p" || { echo "    atlas still has: $p"; rc=1; }
done
for p in 'a row written from file names alone' 'In Update mode, an older ATLAS.md'; do
    printf '%s\n' "$BODY" | grep -qF -- "$p" || { echo "    atlas missing: $p"; rc=1; }
done
AFTER=$(printf '%s\n' "$BODY" | awk 'index($0, "## After Generation") == 1 { s=1; next } s && index($0, "## ") == 1 { s=0 } s')
for p in 'if git tracks it' 'on the default branch, ask first'; do
    printf '%s\n' "$AFTER" | grep -qF -- "$p" || { echo "    atlas After Generation missing: $p"; rc=1; }
done
# F34: the lazy-load hint lists every section after Where to Look.
HINT=$(tr -d '\r' < "$H" | grep -F 'Full ATLAS.md available via Read')
for p in 'Entry Points' 'Key Flows' 'Module Map' 'Key Symbols' 'Integration Points' 'Conventions & Gotchas'; do
    printf '%s\n' "$HINT" | grep -qF -- "$p" || { echo "    session-start hint missing: $p"; rc=1; }
done
exit $rc
