#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
assert_file "$F" || exit 1
bash -n "$F" || exit 1
# When ATLAS.md exists in cwd, hook must output Where to Look section (lazy-load)
TMP="$(mktemp -d)"; cp "$PLUGIN_DIR/hooks/"*.md "$TMP/" 2>/dev/null || true
cd "$TMP"
cat > ATLAS.md <<'EOF'
# ATLAS — Fixture

## Where to Look

| I want to... | Open | Why |
|--------------|------|-----|
| Find the marker | `marker.txt` | UNIQUE_ATLAS_MARKER_37812 |

## Module Map

| Directory | Purpose | Key files |
|-----------|---------|-----------|
| `src/` | UNIQUE_MODULE_MARKER_55555 | `foo.ts` |
EOF
OUT="$(bash "$F" 2>&1 || true)"
cd - >/dev/null
echo "$OUT" | grep -q "UNIQUE_ATLAS_MARKER_37812" || { echo "    session-start.sh did not output Where to Look section"; rm -rf "$TMP"; exit 1; }
echo "$OUT" | grep -q "UNIQUE_MODULE_MARKER_55555" && { echo "    session-start.sh leaked Module Map (should be lazy)"; rm -rf "$TMP"; exit 1; }
echo "$OUT" | grep -q "Full ATLAS.md available" || { echo "    session-start.sh missing lazy-load hint"; rm -rf "$TMP"; exit 1; }
# When turbocharge-session.json snapshot exists, hook must cat it too
cd "$TMP"
mkdir -p ".claude"
cat > ".claude/turbocharge-session.json" <<'EOF'
{"marker":"UNIQUE_SESSION_MARKER_99123"}
EOF
OUT="$(bash "$F" 2>&1 || true)"
cd - >/dev/null
rm -rf "$TMP"
echo "$OUT" | grep -q "UNIQUE_SESSION_MARKER_99123" || { echo "    session-start.sh did not cat session snapshot"; exit 1; }
