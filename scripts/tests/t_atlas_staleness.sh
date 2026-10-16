#!/usr/bin/env bash
# ABOUTME: Tests that session-start.sh detects stale ATLAS.md via hash mismatch.
# ABOUTME: Also verifies graceful skip when no hash comment present.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
assert_file "$F" || exit 1
bash -n "$F" || exit 1

# Test 1: Wrong hash → staleness warning
TMP="$(mktemp -d)"; cp "$PLUGIN_DIR/hooks/"*.md "$TMP/" 2>/dev/null || true
cd "$TMP"
cat > ATLAS.md <<'EOF'
# ATLAS — Fixture

## Where to Look

| I want to... | Open | Why |
|--------------|------|-----|
| Test | `test.txt` | test |

<!-- atlas-hash:000000000000 -->
EOF
STALE_OUT="$(bash "$F" 2>&1 | grep -Ei "stale|structure changed" || true)"
cd - >/dev/null
[ -n "$STALE_OUT" ] || { echo "    no staleness warning for mismatched hash"; rm -rf "$TMP"; exit 1; }

# Test 2: No hash → no warning
cd "$TMP"
cat > ATLAS.md <<'EOF'
# ATLAS — Fixture

## Where to Look

| I want to... | Open | Why |
|--------------|------|-----|
| Test | `test.txt` | test |
EOF
STALE_OUT="$(bash "$F" 2>&1 | grep -Ei "stale|structure changed" || true)"
cd - >/dev/null
rm -rf "$TMP"
[ -z "$STALE_OUT" ] || { echo "    false staleness warning when no hash present"; exit 1; }
