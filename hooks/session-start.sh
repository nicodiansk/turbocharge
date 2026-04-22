#!/usr/bin/env bash
# ABOUTME: SessionStart hook — bootstrap cat, pre-load ATLAS.md + session snapshot.
# ABOUTME: Pre-loading ATLAS means zero tool calls for "where is X" lookups.
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"

cat "$HOOK_DIR/session-bootstrap.md"

if [ -f "ATLAS.md" ]; then
    echo ""
    echo "--- ATLAS.md (Where to Look — pre-loaded) ---"
    awk '/^## Where to Look/{found=1} found && /^## [^W]/{exit} {print}' "ATLAS.md"
    echo ""
    echo "(Full ATLAS.md available via Read — contains Module Map, Key Symbols, Integration Points, Conventions & Gotchas)"
    echo "--- end ATLAS.md ---"
else
    echo ""
    cat "$HOOK_DIR/missing-atlasmd-nudge.md"
fi

# Staleness check
if [ -f "ATLAS.md" ]; then
    STORED=$(sed -n 's/.*<!-- atlas-hash:\([a-f0-9]*\) -->.*/\1/p' "ATLAS.md" 2>/dev/null || true)
    if [ -n "$STORED" ]; then
        CURRENT=""
        if command -v md5sum >/dev/null 2>&1; then
            CURRENT=$(ls -1 2>/dev/null | grep -v -e '^\.' -e '^node_modules$' -e '^__pycache__$' -e '^venv$' -e '^dist$' -e '^build$' | sort | md5sum | cut -c1-12 || true)
        elif command -v md5 >/dev/null 2>&1; then
            CURRENT=$(ls -1 2>/dev/null | grep -v -e '^\.' -e '^node_modules$' -e '^__pycache__$' -e '^venv$' -e '^dist$' -e '^build$' | sort | md5 -r | cut -c1-12 || true)
        fi
        if [ -n "$CURRENT" ] && [ "$STORED" != "$CURRENT" ]; then
            echo ""
            echo "ATLAS.md may be stale — project structure changed since last generation. Consider running /turbocharge:atlas to update."
        fi
    fi
fi

if [ -d ".codemap" ] && command -v codemap >/dev/null 2>&1; then
    echo ""
    echo "--- CodeMap index available ---"
    codemap stats
    echo "Use: codemap find 'SymbolName' | codemap show path/to/file"
    echo "--- end CodeMap ---"
fi

if [ -f ".claude/turbocharge-session.json" ]; then
    echo ""
    echo "--- Session snapshot (previous /wrap) ---"
    cat ".claude/turbocharge-session.json"
    echo "--- end snapshot ---"
fi

if [ ! -f "CLAUDE.md" ]; then
    echo ""
    cat "$HOOK_DIR/missing-claudemd-nudge.md"
fi
