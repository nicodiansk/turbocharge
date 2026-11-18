#!/usr/bin/env bash
# ABOUTME: Asserts debug states its root-cause rule with the reason, keeps Red Flags and the three-fix rule, and carries the zsh traps.
# ABOUTME: 3.8.0 prompt hygiene F16, F17, C3; the reference files drop another project's dated incident stats.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
D="$PLUGIN_DIR/skills/debug"
S="$D/SKILL.md"
assert_file "$S" || exit 1
rc=0
BODY=$(tr -d '\r' < "$S")
no() { printf '%s\n' "$2" | grep -qF -- "$3" && { echo "    $1 still has: $3"; rc=1; }; return 0; }
has() { printf '%s\n' "$2" | grep -qF -- "$3" || { echo "    $1 missing: $3"; rc=1; }; }
for p in 'ALWAYS find root cause' 'Violating the letter' 'You MUST complete' 'BEFORE attempting ANY' 'NO FIXES WITHOUT'; do
    no "debug" "$BODY" "$p"
done
for p in 'leaves the cause in place' 'Phase 1 has found the root cause' '## Red Flags' 'If 3+ fixes failed'; do
    has "debug" "$BODY" "$p"
done
exit $rc
