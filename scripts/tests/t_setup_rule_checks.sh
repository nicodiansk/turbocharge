#!/usr/bin/env bash
# ABOUTME: Asserts setup's agents.md and rule-file checks: rebuild the agents table from the plugin, flag stale lines.
# ABOUTME: Sections read with \r stripped; the directory copy of setup names no left-out workflow file.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/setup/SKILL.md"
assert_file "$S" || exit 1
rc=0
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
has() { # has <label> <text> <phrase>
    printf '%s\n' "$2" | grep -qF -- "$3" || { echo "    $1 missing: $3"; rc=1; }
}
hasnt() { # hasnt <label> <text> <phrase>
    printf '%s\n' "$2" | grep -qF -- "$3" && { echo "    $1 still has: $3"; rc=1; }
}

# Task 18: Step 3 rebuilds the agents table from the plugin
S3=$(sec "$S" '### 3. Check agents.md Rule' '### ')
for p in '${CLAUDE_PLUGIN_ROOT}/agents/*.md' 'Dispatched by' 'an enabled plugin' 'line endings'; do
    has "setup Step 3" "$S3" "$p"
done
hasnt "setup Step 3" "$S3" 'agents not in `~/.claude/agents/`'
REPO=$(printf '%s\n' "$S3" | awk '/^<!-- repo-only -->/ { s=1; next } /^<!-- \/repo-only -->/ { s=0 } s')
has "setup Step 3 repo-only block" "$REPO" 'workflows/'
DIR=$(bash "$PLUGIN_DIR/scripts/directory-filter.sh" < "$S")
hasnt "setup directory copy" "$DIR" 'review-swarm'
hasnt "setup directory copy" "$DIR" 'workflows/'

# Task 19: Step 8 finds stale references in every rule and skill file
S8=$(sec "$S" '### 8. Check Rule and Skill Files for Stale Lines' '## ')
for p in '~/.claude/rules/**/*.md' '~/.claude/skills/*/SKILL.md' 'built-in command' 'an enabled plugin' 'MAX_THINKING_TOKENS' 'effort' 'TodoWrite' 'Glob'; do
    has "setup Step 8" "$S8" "$p"
done
for p in 'Opus 5' 'Sonnet 5'; do
    hasnt "setup Step 8" "$S8" "$p"
done
exit $rc
