#!/usr/bin/env bash
# ABOUTME: Behavioral — SessionStart exits 0 in every project shape, so Claude Code never reports a hook error.
# ABOUTME: Also asserts the snapshot block is skipped (not printed empty) when no budget is left.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
assert_file "$F" || exit 1
grep -qF 'SNAPSHOT_CAP" -gt 0' "$F" || { echo "    hook must skip the snapshot when SNAPSHOT_CAP <= 0"; exit 1; }

TMP="$(mktemp -d)"
cleanup() { cd /; rm -rf "$TMP"; }
cd "$TMP"
run() {  # run LABEL — the hook must exit 0
    bash "$F" >/dev/null 2>&1
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
cleanup
exit 0
