#!/usr/bin/env bash
# ABOUTME: Asserts no skill forks: the directory refuses context and agent from non-Verified organizations (3.5.10 kept
# ABOUTME: its count at 2 with them), so plan dispatches turbocharge:planner from the main session and waits for the plan.
# ABOUTME: The name is historical (t_changelog_300.sh names it): forked skills used to have to block.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
for F in "$PLUGIN_DIR"/skills/*/SKILL.md; do
    FM="$(frontmatter "$F")"
    for k in context agent background; do
        printf '%s\n' "$FM" | grep -q "^$k:" \
            && { echo "    $(basename "$(dirname "$F")") sets $k: in its frontmatter; dispatch an agent instead"; exit 1; }
    done
done
P="$PLUGIN_DIR/skills/plan/SKILL.md"
assert_file "$P" || exit 1
for p in 'Dispatch `turbocharge:planner`' 'completion notification' 'No agent here' 'not registered' 'Context Gathering' \
    'Never write the plan in this session' 'Spec Self-Review' 'a rerun resumes' 'Check the saved plan'; do
    assert_grep "$P" "$p" || exit 1
done
grep -qF 'runs forked' "$P" && { echo "    plan skill still says it runs forked"; exit 1; }
grep -qiF 'run forked' "$PLUGIN_DIR/agents/planner.md" && { echo "    planner.md still says it runs forked"; exit 1; }
grep -qiF 'forked plan run' "$PLUGIN_DIR/agents/planner.md" && { echo "    planner.md still says a forked plan run"; exit 1; }
# A dispatched planner sees only its prompt and agents/planner.md, so planner.md carries the rules SKILL.md states.
PL="$PLUGIN_DIR/agents/planner.md"
for p in 'TDD always' 'DRY, YAGNI' 'not test code' 'Exact commands' 'silence on an input is not permission'; do
    assert_grep "$PL" "$p" || exit 1
done
exit 0
