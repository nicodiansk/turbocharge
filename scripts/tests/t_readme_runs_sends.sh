#!/usr/bin/env bash
# ABOUTME: Asserts the README says what the skills run and send (the directory checklist asks for everything a plugin runs,
# ABOUTME: sends or fetches), and that ship is the only shipped file that reaches a remote, so "Nothing else" stays true.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/README.md"
assert_file "$F" || exit 1
rc=0
S="$(awk '/^## What the skills run and send/{f=1; next} f && /^## /{exit} f' "$F")"
[ -n "$S" ] || { echo "    README has no '## What the skills run and send' section"; exit 1; }
for p in '`git pull`' '`git push`' '`gh pr create`' 'Option 1' 'Option 2' 'never pushes' '`claude plugin list --json`' \
    '`claude plugin details turbocharge`' '`~/.claude/agents/`' '`~/.claude/rules/common/`' '`.claude/turbocharge-session.json`' \
    '`~/.claude/projects/<project>/memory/`' '`codemap' 'Nothing else'; do
    printf '%s' "$S" | grep -qF -- "$p" || { echo "    the section doesn't say: $p"; rc=1; }
done
# What the section claims ship runs, ship runs.
for p in 'git pull' 'git push' 'gh pr create'; do
    grep -qF -- "$p" "$PLUGIN_DIR/skills/ship/SKILL.md" || { echo "    ship no longer runs $p: update the README"; rc=1; }
done
# Nothing else reaches a remote.
HITS="$(cd "$PLUGIN_DIR" && grep -rnE 'git (push|pull|fetch|clone)|(^|[^a-z])gh [a-z]|curl |wget |WebFetch|WebSearch' \
    skills agents hooks workflows templates 2>/dev/null | grep -v '^skills/ship/SKILL.md:')"
[ -z "$HITS" ] || { echo "    a shipped file other than ship reaches a remote; add it to the README: $HITS"; rc=1; }
exit $rc
