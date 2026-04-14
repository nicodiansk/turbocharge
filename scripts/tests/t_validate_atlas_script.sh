#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/scripts/validate-atlas.sh"
assert_file "$F" || exit 1
bash -n "$F" || { echo "    syntax error"; exit 1; }
# Drives required-header logic
assert_grep "$F" "Where to Look"       || exit 1
assert_grep "$F" "Entry Points"        || exit 1
assert_grep "$F" "Module Map"          || exit 1
assert_grep "$F" "Key Symbols"         || exit 1
assert_grep "$F" "Integration Points"  || exit 1
# Fails cleanly when ATLAS.md missing
TMP="$(mktemp -d)"; cd "$TMP"
if bash "$F"; then echo "    expected nonzero when ATLAS.md missing"; cd - >/dev/null; rm -rf "$TMP"; exit 1; fi
cd - >/dev/null; rm -rf "$TMP"
# Passes when minimal ATLAS.md with all headers present
TMP="$(mktemp -d)"; cd "$TMP"
cat > ATLAS.md <<'EOF'
# ATLAS — Test
## Where to Look
## Entry Points
## Module Map
## Key Symbols
## Integration Points
## Conventions & Gotchas
EOF
if ! bash "$F"; then echo "    expected zero on valid ATLAS.md"; cd - >/dev/null; rm -rf "$TMP"; exit 1; fi
cd - >/dev/null; rm -rf "$TMP"
