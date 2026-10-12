#!/usr/bin/env bash
# ABOUTME: Asserts build routes plan lanes inline or to one builder, overlaps independent lanes, and joins with one full gate.
# ABOUTME: Covers routing flags, per-spawn effort, pathspec commits, SendMessage fix rounds and the visibility line.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$F" || exit 1
rc=0
for p in \
    'Lanes table' \
    'No Lanes table' \
    '--inline' \
    '--delegate' \
    'effort' \
    '-- <lane paths>' \
    'index.lock' \
    'Full Gate, once' \
    'SendMessage' \
    'lanes: L (inline I · builder B)'; do
    grep -qF -- "$p" "$F" || { echo "    build missing: $p"; rc=1; }
done

# Per-lane review: the pathspec isolates one lane even though other lanes' commits interleave.
grep -qF 'git diff $BEFORE_SHA..HEAD -- <lane paths>' "$F" || { echo "    reviewer must diff the lane by pathspec"; rc=1; }
grep -qF 'NO BUILD COMPLETE WITHOUT THE FULL SUITE GREEN AT THE JOIN' "$F" || { echo "    Iron Law must gate on the join"; rc=1; }

# Agent Teams multi-track is gone (overlapping lanes replace it).
for p in 'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' 'TeamCreate' 'Multi-Track'; do
    grep -qF "$p" "$F" && { echo "    build still has Agent Teams prose: $p"; rc=1; }
done

# Red Flags cover the overlap hazards.
RF="$(awk '/^## Red Flags/{f=1} f' "$F")"
for p in 'git add -A' 'in flight' 'SendMessage' 'exact-text lane'; do
    printf '%s' "$RF" | grep -qF -- "$p" || { echo "    Red Flags missing: $p"; rc=1; }
done

# Review fixes (3.1.0): pathspec = the task's files (a lane path that doesn't exist yet makes git commit fail);
# dependent lanes get started; stash-based pre-commit hooks disable overlap; fix rounds need the builder's agent ID.
for p in \
    "-- <this task's files>" \
    'whose `After` lanes have all finished' \
    '.pre-commit-config.yaml' \
    'agent ID' \
    '--no-checkpoint' \
    'After every lane finishes' \
    '.lintstagedrc' \
    'package.json' \
    '.husky/' \
    'plan-time' \
    'when Agent Teams are enabled'; do
    grep -qF -- "$p" "$F" || { echo "    build missing: $p"; rc=1; }
done
N=$(grep -oF 'record the lane'"'"'s `BEFORE_SHA` first' "$F" | wc -l)
[ "$N" -ge 2 ] || { echo "    Steps 3 and 4 must both say to record the lane's BEFORE_SHA first ($N)"; rc=1; }
TR="$PLUGIN_DIR/agents/task-reviewer.md"
grep -qF 'completes a task' "$TR" && { echo "    task-reviewer still triggers per task"; rc=1; }
grep -qF 'lane' "$TR"            || { echo "    task-reviewer must review a lane diff"; rc=1; }

# Builder isolation decision (carried over): no worktree self-isolation; lanes share one tree.
assert_grep "$F" "isolation: worktree" || rc=1
assert_grep "$F" "default branch"      || rc=1
assert_no_grep "$PLUGIN_DIR/agents/builder.md" "^isolation:" || rc=1
exit $rc
