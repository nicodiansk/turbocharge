#!/usr/bin/env bash
# ABOUTME: Asserts the review skill runs in the main session, launches the review-swarm workflow, and falls back to the single reviewer.
# ABOUTME: Its description must not quote an eval prompt (that would measure the eval, not the trigger).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
R="$PLUGIN_DIR/skills/review/SKILL.md"
assert_file "$R" || exit 1
FM=$(frontmatter "$R")
printf '%s\n' "$FM" | grep -q '^context: fork' && { echo "    review must not be context: fork (the workflow launches from the main session)"; exit 1; }
printf '%s\n' "$FM" | grep -q '^agent:' && { echo "    review must not set agent:"; exit 1; }
for p in 'review-swarm' 'Workflow' 'completion notification' 'Nothing to review' 'Not verified' \
         'Declined to judge' 'Refuted' '/config' 'turbocharge:code-reviewer' 'not registered'; do
    assert_grep "$R" "$p" || exit 1
done
DESC=$(printf '%s\n' "$FM" | grep '^description:')
for p in 'review my branch' 'feature/' 'SPEC.md'; do
    printf '%s\n' "$DESC" | grep -qF "$p" && { echo "    review description quotes an eval prompt: '$p'"; exit 1; }
done
exit 0
