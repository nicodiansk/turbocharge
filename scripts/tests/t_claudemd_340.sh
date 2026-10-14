#!/usr/bin/env bash
# ABOUTME: Asserts .claude/CLAUDE.md records the 3.4.0 additions: 6 agents, the review workflow, the verifier and PR triage.
# ABOUTME: Also asserts the macOS eval host note (the sandbox breaks bare git; dogfood D15) and the workflow file type.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/.claude/CLAUDE.md"
assert_file "$F" || exit 1
for p in '6 agents' 'workflows/review-swarm.js' '| **Verifier** |' '| **Review swarm** |' '| **PR triage** |' \
         '`workflows/<name>.js`' "model: 'sonnet'" 'D15' 'tc-eval-git'; do
    grep -qF -- "$p" "$F" || { echo "    CLAUDE.md missing: $p"; exit 1; }
done
grep -qF '5 agents' "$F" && { echo "    CLAUDE.md still says 5 agents"; exit 1; }
exit 0
