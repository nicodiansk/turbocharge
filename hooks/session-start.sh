#!/usr/bin/env bash
# ABOUTME: SessionStart hook — bootstrap cat, pre-load ATLAS.md + session snapshot.
# ABOUTME: Pre-loading ATLAS means zero tool calls for "where is X" lookups.
# ABOUTME: Read-only — emits text to stdout only; creates/modifies/deletes nothing, no network.
# ABOUTME: Per-section byte caps keep total output under Claude Code's 10,000-char inline limit.
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"

# Per-section byte caps. Claude Code saves hook output over 10,000 chars to disk
# and injects only a 2,000-char preview, so the sum of these plus the fixed
# prose must stay under 10,000 (guarded by scripts/tests/t_session_start_output_cap.sh).
ATLAS_CAP=3500
SNAPSHOT_CAP=2500
CODEMAP_CAP=1200

# cap_section MAX HINT — print stdin up to MAX bytes, cutting only at line
# boundaries (never mid-character). On overflow, append a marker telling the
# model where the rest lives. Reads all of stdin so the producer never SIGPIPEs.
cap_section() {
    LC_ALL=C awk -v max="$1" -v hint="$2" '
        cut { next }
        used + length($0) + 1 > max { cut = 1; next }
        { used += length($0) + 1; print }
        END { if (cut) print "…truncated — " hint " for the rest" }
    '
}

cat "$HOOK_DIR/session-bootstrap.md"

if [ -f "ATLAS.md" ]; then
    echo ""
    echo "--- ATLAS.md (Where to Look — pre-loaded) ---"
    awk '/^## Where to Look/{found=1} found && /^## [^W]/{exit} {print}' "ATLAS.md" \
        | cap_section "$ATLAS_CAP" "Read ATLAS.md"
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
            echo "ATLAS.md may be stale — project structure changed since last generation. Consider running /turboflow:atlas to update."
        fi
    fi
fi

if [ -d ".codemap" ] && command -v codemap >/dev/null 2>&1; then
    echo ""
    echo "--- CodeMap index available ---"
    codemap stats | cap_section "$CODEMAP_CAP" "Run \`codemap stats\`"
    echo "Use: codemap find 'SymbolName' | codemap show path/to/file"
    echo "--- end CodeMap ---"
fi

# Session snapshot. Pre-3.0.0 /wrap wrote .claude/turbocharge-session.json;
# fall back to it so upgraders keep their resume state.
# MIGRATION FALLBACK (3.0.x only) — remove in 3.1.
SNAPSHOT=""
if [ -f ".claude/turboflow-session.json" ]; then
    SNAPSHOT=".claude/turboflow-session.json"
elif [ -f ".claude/turbocharge-session.json" ]; then
    SNAPSHOT=".claude/turbocharge-session.json"
fi
if [ -n "$SNAPSHOT" ]; then
    echo ""
    echo "--- Session snapshot (previous /wrap) ---"
    cap_section "$SNAPSHOT_CAP" "Read $SNAPSHOT" < "$SNAPSHOT"
    echo "--- end snapshot ---"
fi

# Claude Code loads ./CLAUDE.md or ./.claude/CLAUDE.md, and its AGENTS.md rule also
# counts CLAUDE.local.md as "a CLAUDE.md exists" — any of the three means no nudge.
if [ ! -f "CLAUDE.md" ] && [ ! -f ".claude/CLAUDE.md" ] && [ ! -f "CLAUDE.local.md" ]; then
    echo ""
    if [ -f "AGENTS.md" ]; then
        cat "$HOOK_DIR/agentsmd-only-nudge.md"
    else
        cat "$HOOK_DIR/missing-claudemd-nudge.md"
    fi
fi
