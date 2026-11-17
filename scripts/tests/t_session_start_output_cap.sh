#!/usr/bin/env bash
# ABOUTME: Behavioral test — SessionStart output stays under Claude Code's 10,000-char inline limit.
# ABOUTME: Oversized ATLAS, stale-lines and snapshot fixtures must each truncate with a Read/Run pointer marker.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
assert_file "$F" || exit 1
bash -n "$F" || exit 1

TMP="$(mktemp -d)"
cleanup() { cd /; rm -rf "$TMP"; }
cd "$TMP"

# Worst case: every section present and oversized, 300 cited files changed since the footer's commit,
# AGENTS.md but no CLAUDE.md.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
g() { git -c user.name=t -c user.email=t@t "$@"; }
git init -q .
for i in $(seq 1 300); do mkdir -p "src/module_$i"; echo one > "src/module_$i/file.ts"; done
g add -A && g commit -q -m one
SHA1="$(git rev-parse HEAD)"
for i in $(seq 1 300); do echo two >> "src/module_$i/file.ts"; done
g commit -q -am two
{
    echo "# ATLAS — Fixture"; echo ""; echo "## Where to Look"; echo ""
    echo "| I want to... | Open | Why |"; echo "|---|---|---|"
    for i in $(seq 1 300); do
        echo "| Find thing $i — em dash | \`src/module_$i/file.ts\` | ATLAS_ROW_$i padding padding padding |"
    done
    echo ""; echo "## Module Map"; echo "UNIQUE_MODULE_LEAK_4411"
    echo "<!-- atlas-sha:$SHA1 -->"
} > ATLAS.md
mkdir -p .claude
{
    echo "{"
    for i in $(seq 1 300); do echo "  \"key_$i\": \"SNAPSHOT_LINE_$i padding padding padding padding\","; done
    echo "  \"end\": true"; echo "}"
} > .claude/turbocharge-session.json
echo "# Agents fixture" > AGENTS.md

OUT="$(bash "$F" 2>&1 || true)"
# Bytes are an upper bound on chars, so this is locale-independent and conservative.
BYTES=$(printf '%s' "$OUT" | wc -c | tr -d ' ')
[ "$BYTES" -lt 10000 ] || { echo "    hook output is $BYTES bytes, must be < 10000"; cleanup; exit 1; }

echo "$OUT" | grep -qF "truncated — Read ATLAS.md for the rest" \
    || { echo "    ATLAS section missing truncation marker"; cleanup; exit 1; }
echo "$OUT" | grep -qF "truncated — Read .claude/turbocharge-session.json for the rest" \
    || { echo "    snapshot section missing truncation marker"; cleanup; exit 1; }
echo "$OUT" | grep -qF 'truncated — Run `git diff --name-only --no-renames' \
    || { echo "    stale-lines section missing truncation marker"; cleanup; exit 1; }
# Truncation keeps the head of each section (not empty) and still respects lazy-load.
echo "$OUT" | grep -q "ATLAS_ROW_1 "    || { echo "    ATLAS head missing"; cleanup; exit 1; }
echo "$OUT" | grep -q "SNAPSHOT_LINE_1 " || { echo "    snapshot head missing"; cleanup; exit 1; }
echo "$OUT" | grep -q "^  line [0-9]*: src/module_" || { echo "    stale-lines head missing"; cleanup; exit 1; }
echo "$OUT" | grep -q "UNIQUE_MODULE_LEAK_4411" && { echo "    Module Map leaked"; cleanup; exit 1; }

# Small inputs must pass through untouched — no marker.
rm -f AGENTS.md
printf '# ATLAS\n\n## Where to Look\n\n| a | b | c |\n' > ATLAS.md
echo '{"marker":"SMALL_SNAPSHOT_7781"}' > .claude/turbocharge-session.json
OUT="$(bash "$F" 2>&1 || true)"
echo "$OUT" | grep -q "SMALL_SNAPSHOT_7781" || { echo "    small snapshot not emitted"; cleanup; exit 1; }
echo "$OUT" | grep -q "truncated —" && { echo "    small inputs were truncated"; cleanup; exit 1; }

# Leftover budget: tiny ATLAS + ~6 KB snapshot -> snapshot gets more than the old fixed 2,500 B, total stays < 10,000.
cd "$TMP"; mkdir -p .claude
printf '# ATLAS\n\n## Where to Look\n\n| a | b | c |\n' > ATLAS.md
{ for i in $(seq 1 120); do echo "BIGSNAP_LINE_$i padding padding padding padding pad"; done; } > .claude/turbocharge-session.json
SNAP_SRC=$(wc -c < .claude/turbocharge-session.json | tr -d ' ')
OUT="$(bash "$F" 2>&1 || true)"
cleanup
SNAP_BYTES=$(printf '%s\n' "$OUT" | grep '^BIGSNAP_LINE_' | wc -c | tr -d ' ')
[ "$SNAP_BYTES" -gt 2500 ] || { echo "    snapshot got only $SNAP_BYTES bytes (source $SNAP_SRC), expected > 2500"; exit 1; }
TOTAL=$(printf '%s' "$OUT" | wc -c | tr -d ' ')
[ "$TOTAL" -lt 10000 ] || { echo "    leftover-budget case is $TOTAL bytes, must be < 10000"; exit 1; }
! grep -qi 'codemap' "$F" || { echo "    hook still names codemap"; exit 1; }
! grep -q 'zero tool calls' "$F" "$PLUGIN_DIR/hooks/missing-atlasmd-nudge.md" || { echo "    a savings claim ('zero tool calls') remains"; exit 1; }
grep -q 'SNAPSHOT_CAP=2500' "$F" && { echo "    hook still has SNAPSHOT_CAP=2500"; exit 1; }
exit 0
