#!/usr/bin/env bash
# ABOUTME: Asserts CLAUDE.md, README and the two diagrams describe build's per-lane model routing (Opus on plan-marked lanes).
# ABOUTME: Guards the old "one Sonnet builder" and "Opus in one place" wording against resurfacing.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
C="$PLUGIN_DIR/.claude/CLAUDE.md"
R="$PLUGIN_DIR/README.md"
TIER="$PLUGIN_DIR/images/model-tiering.svg"
CHAIN="$PLUGIN_DIR/images/build-review-chain.svg"
sec() { tr -d '\r' < "$1" | awk -v h="$2" -v e="$3" 'index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s'; }
rc=0
has() { printf '%s\n' "$1" | grep -qF -- "$2" || { echo "    $3 missing: $2"; rc=1; }; }
hasnt() { printf '%s\n' "$1" | grep -qF -- "$2" && { echo "    $3 still has: $2"; rc=1; }; return 0; }

AM=$(sec "$C" '### Agent Models' '### Release Naming')
for p in 'two places' '`opus · <reason>`' 'stuck Sonnet lane' 'A stuck Opus lane goes' 'No agent file pins Opus' 'never Haiku' 'model: inherit'; do
    has "$AM" "$p" "CLAUDE.md Agent Models"
done
hasnt "$AM" 'Opus appears in one place' "CLAUDE.md Agent Models"
LANE=$(tr -d '\r' < "$C" | grep -F '| **Lane** |')
has "$LANE" 'Opus on lanes the plan marks' "CLAUDE.md Lane row"
hasnt "$LANE" 'one Sonnet builder' "CLAUDE.md Lane row"

RD=$(tr -d '\r' < "$R")
hasnt "$RD" 'one place only' "README"
has "$(printf '%s\n' "$RD" | grep -F '| **builder** |')" 'Opus on lanes the plan marks' "README builder row"
TIERIMG=$(printf '%s\n' "$RD" | grep -F 'model-tiering.svg')
has "$TIERIMG" 'two places' "README model-tiering img"
has "$TIERIMG" 'stuck Opus lane' "README model-tiering img"
FILT=$(bash "$PLUGIN_DIR/scripts/directory-filter.sh" < "$R" | tr -d '\r')
for p in '**Advisor.**' '`/advisor`' 'neither sets nor reads it'; do has "$FILT" "$p" "filtered README"; done
has "$(printf '%s\n' "$RD" | grep -F '| **build** |')" 'Opus on lanes the plan marks' "README build row"
has "$(printf '%s\n' "$RD" | grep -F '| **build** |')" 'at most 3 builders at once' "README build row"
hasnt "$RD" 'one Sonnet builder' "README"
has "$(printf '%s\n' "$RD" | grep -F 'build-review-chain.svg')" 'Opus when the plan marks the lane' "README build-review-chain img"
for p in 'no Model column' 'plan: done YYYY-MM-DD' 'docs/plans/archive/' 'rerunning a done plan asks first'; do has "$FILT" "$p" "filtered README"; done
exit $rc
