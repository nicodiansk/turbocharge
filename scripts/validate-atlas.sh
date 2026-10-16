#!/usr/bin/env bash
# ABOUTME: Validates ATLAS.md in CWD has turbocharge's required lookup-first headers.
# ABOUTME: Exits 0 on pass, 1 on any missing header or missing file.
set -u
TARGET="${1:-ATLAS.md}"
REQUIRED=("## Where to Look" "## Entry Points" "## Module Map" "## Key Symbols" "## Integration Points" "## Conventions & Gotchas")
if [ ! -f "$TARGET" ]; then
    echo "ATLAS-VALIDATE: $TARGET not found." >&2
    exit 1
fi
MISSING=0
for h in "${REQUIRED[@]}"; do
    if ! grep -q "^${h}\$" "$TARGET"; then
        echo "ATLAS-VALIDATE: missing required header: $h" >&2
        MISSING=$((MISSING+1))
    fi
done
if [ "$MISSING" -gt 0 ]; then
    echo "ATLAS-VALIDATE: $MISSING header(s) missing." >&2
    exit 1
fi
echo "ATLAS-VALIDATE: $TARGET OK"
