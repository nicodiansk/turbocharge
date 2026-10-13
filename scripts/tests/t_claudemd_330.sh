#!/usr/bin/env bash
# ABOUTME: Asserts .claude/CLAUDE.md records the 3.3.0 additions: the exit gate's two events, the Opus retry, and the eval release step.
# ABOUTME: Also asserts the Review Focus and Eval case domain terms.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/.claude/CLAUDE.md"
assert_file "$F" || exit 1
for p in 'SubagentStop' 'SubagentHandback' 'model: opus' 'scripts/eval.sh' 'evals/summary/' '| **Review Focus** |' '| **Eval case** |'; do
    grep -qF -- "$p" "$F" || { echo "    CLAUDE.md missing: $p"; exit 1; }
done
exit 0
