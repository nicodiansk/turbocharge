#!/usr/bin/env bash
# ABOUTME: Behavioral — SessionStart exits 0 in every project shape, so Claude Code never reports a hook error.
# ABOUTME: Also runs a copy of the hook with TOTAL_BUDGET=100 to prove the snapshot block is skipped, not printed empty.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
assert_file "$F" || exit 1

TMP="$(mktemp -d)"
cleanup() { cd /; rm -rf "$TMP"; }
mkdir -p "$TMP/proj" "$TMP/hooks"
cd "$TMP/proj"
run() {  # run LABEL [HOOK] — the hook must exit 0
    bash "${2:-$F}" >/dev/null 2>&1
    local rc=$?
    [ "$rc" -eq 0 ] || { echo "    $1: hook exited $rc"; return 1; }
}
echo "# x" > CLAUDE.md
run "CLAUDE.md, no snapshot" || { cleanup; exit 1; }
mkdir -p .claude; echo '{"a":1}' > .claude/turboflow-session.json
run "CLAUDE.md + snapshot"   || { cleanup; exit 1; }
rm -f CLAUDE.md
run "no CLAUDE.md"           || { cleanup; exit 1; }
echo "# Agents" > AGENTS.md
run "AGENTS.md only"         || { cleanup; exit 1; }

# No budget left: a copy of the hook with TOTAL_BUDGET=100 must skip the snapshot block entirely.
cp "$PLUGIN_DIR"/hooks/*.md "$TMP/hooks/"
sed 's/^TOTAL_BUDGET=.*/TOTAL_BUDGET=100/' "$F" > "$TMP/hooks/session-start.sh"
grep -q '^TOTAL_BUDGET=100$' "$TMP/hooks/session-start.sh" || { echo "    could not set TOTAL_BUDGET in the copy"; cleanup; exit 1; }
run "no budget left" "$TMP/hooks/session-start.sh" || { cleanup; exit 1; }
OUT="$(bash "$TMP/hooks/session-start.sh" 2>&1 || true)"
cleanup
echo "$OUT" | grep -q -- "--- Session snapshot" && { echo "    snapshot block printed with no budget left"; exit 1; }
exit 0
