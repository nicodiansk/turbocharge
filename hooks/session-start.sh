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
CODEMAP_CAP=1200
# Everything the hook prints stays under TOTAL_BUDGET; the snapshot gets what the
# other sections leave over (minus SNAPSHOT_OVERHEAD for its header/footer/marker).
TOTAL_BUDGET=9500
SNAPSHOT_OVERHEAD=200

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

# emit_head — bootstrap, ATLAS, staleness, CodeMap: everything printed before the snapshot.
emit_head() {
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
}

# emit_nudge — the CLAUDE.md / AGENTS.md nudge printed after the snapshot.
# ./CLAUDE.md or ./.claude/CLAUDE.md → no nudge. CLAUDE.local.md also counts as "a
# CLAUDE.md exists" for Claude Code's AGENTS.md rule, so with AGENTS.md beside it
# (and no @AGENTS.md import) AGENTS.md is skipped — the one case it nudges about.
# Only the working directory is checked; Claude Code also looks in parent directories,
# so a session started in a monorepo subfolder can still see a false "No CLAUDE.md".
emit_nudge() {
    if [ -f "CLAUDE.md" ] || [ -f ".claude/CLAUDE.md" ]; then
        return 0
    fi
    if [ -f "CLAUDE.local.md" ]; then
        # Reads only CLAUDE.local.md's import lines, to see whether the nudge's fix is already in place.
        if [ -f "AGENTS.md" ] && ! grep -qE '^[[:space:]]*@(\./)?AGENTS\.md' "CLAUDE.local.md"; then
            echo ""
            cat "$HOOK_DIR/agentsmd-not-loaded-nudge.md"
        fi
        return 0
    fi
    echo ""
    if [ -f "AGENTS.md" ]; then
        cat "$HOOK_DIR/agentsmd-only-nudge.md"
    else
        cat "$HOOK_DIR/missing-claudemd-nudge.md"
    fi
}

# Captured in shell variables (no temp files — the hook stays write-free). Command
# substitution strips trailing newlines, so printf '%s\n' puts one back when printing.
HEAD_OUT="$(emit_head)"
NUDGE_OUT="$(emit_nudge)"
printf '%s\n' "$HEAD_OUT"

SNAPSHOT=""
[ -f ".claude/turboflow-session.json" ] && SNAPSHOT=".claude/turboflow-session.json"
if [ -n "$SNAPSHOT" ]; then
    HEAD_BYTES=$(printf '%s\n' "$HEAD_OUT" | wc -c | tr -d ' ')
    NUDGE_BYTES=0
    [ -n "$NUDGE_OUT" ] && NUDGE_BYTES=$(printf '%s\n' "$NUDGE_OUT" | wc -c | tr -d ' ')
    SNAPSHOT_CAP=$((TOTAL_BUDGET - HEAD_BYTES - NUDGE_BYTES - SNAPSHOT_OVERHEAD))
    # No budget left → skip the optional snapshot rather than print an empty block.
    if [ "$SNAPSHOT_CAP" -gt 0 ]; then
        echo ""
        echo "--- Session snapshot (previous /wrap) ---"
        cap_section "$SNAPSHOT_CAP" "Read $SNAPSHOT" < "$SNAPSHOT"
        echo "--- end snapshot ---"
    fi
fi

[ -n "$NUDGE_OUT" ] && printf '%s\n' "$NUDGE_OUT"
exit 0
