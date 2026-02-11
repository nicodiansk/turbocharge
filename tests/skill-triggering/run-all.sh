#!/bin/bash
# ABOUTME: Runs all skill triggering tests for turbocharge
# ABOUTME: Iterates through all 16 skills with naive prompts and reports pass/fail

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

SKILLS=(
    "brainstorming"
    "systematic-debugging"
    "writing-plans"
    "executing-plans"
    "test-driven-development"
    "subagent-driven-development"
    "using-git-worktrees"
    "dispatching-parallel-agents"
    "requesting-code-review"
    "receiving-code-review"
    "verification-before-completion"
    "finishing-a-development-branch"
    "writing-skills"
    "story-breakdown"
    "session-memory"
)

echo "=== Running Turbocharge Skill Triggering Tests ==="
echo ""

PASSED=0
FAILED=0
SKIPPED=0
RESULTS=()

for skill in "${SKILLS[@]}"; do
    prompt_file="$PROMPTS_DIR/${skill}.txt"

    if [ ! -f "$prompt_file" ]; then
        echo "SKIP: No prompt file for $skill"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    echo "Testing: $skill"

    if "$SCRIPT_DIR/run-test.sh" "$skill" "$prompt_file" 3 2>&1 | tee /tmp/skill-test-$skill.log; then
        PASSED=$((PASSED + 1))
        RESULTS+=("PASS $skill")
    else
        FAILED=$((FAILED + 1))
        RESULTS+=("FAIL $skill")
    fi

    echo ""
    echo "---"
    echo ""
done

echo ""
echo "=== Summary ==="
for result in "${RESULTS[@]}"; do
    echo "  $result"
done
echo ""
echo "Passed:  $PASSED"
echo "Failed:  $FAILED"
echo "Skipped: $SKIPPED"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
