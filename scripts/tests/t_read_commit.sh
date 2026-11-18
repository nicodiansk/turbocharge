#!/usr/bin/env bash
# ABOUTME: Asserts the planner and researcher check which commit they read, and that both plan templates carry a Code read at line.
# ABOUTME: A stale checkout (behind its base, no commits of its own) reads from the base; a branch with its own commits does not count as stale.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
rc=0
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
has() { # has <label> <text> <phrase>
    printf '%s\n' "$2" | grep -qF -- "$3" || { echo "    $1 missing: $3"; rc=1; }
}
S="$PLUGIN_DIR/skills/plan/SKILL.md"; P="$PLUGIN_DIR/agents/planner.md"; R="$PLUGIN_DIR/agents/researcher.md"
for f in "$S" "$P" "$R"; do assert_file "$f" || exit 1; done

RULE=('git status -sb' 'git merge-base --is-ancestor HEAD <base>' 'git rev-list --count HEAD..<base>' 'git show <base>:<path>' 'commits of its own' 'skip the check' 'git rev-parse --short <ref>')
PVDU=$(sec "$P" '### Verify Domain Understanding First' '## ')
RRC=$(sec "$R" '## Read the Right Commit' '## ')
for p in "${RULE[@]}"; do
    has "planner Verify Domain Understanding First" "$PVDU" "$p"
    has "researcher Read the Right Commit" "$RRC" "$p"
done
has "planner Verify Domain Understanding First" "$PVDU" 'commits behind'

# Both templates: Code read at sits between Architecture and Tech Stack
order() { # order <label> <text>
    local a c t
    a=$(printf '%s\n' "$2" | grep -nF -- '**Architecture:**' | head -1 | cut -d: -f1)
    c=$(printf '%s\n' "$2" | grep -nF -- '**Code read at:** <sha7> (<ref>)' | head -1 | cut -d: -f1)
    t=$(printf '%s\n' "$2" | grep -nF -- '**Tech Stack:**' | head -1 | cut -d: -f1)
    if [ -z "$a" ] || [ -z "$c" ] || [ -z "$t" ] || ! [ "$a" -lt "$c" ] || ! [ "$c" -lt "$t" ]; then
        echo "    $1: Code read at must sit after Architecture and before Tech Stack (a=$a c=$c t=$t)"; rc=1
    fi
}
order "plan Plan Document Header" "$(sec "$S" '## Plan Document Header' '## ')"
order "planner Plan Format" "$(sec "$P" '## Plan Format' '## Quality Checklist')"

# Unchanged neighbours
has "planner" "$(cat "$P")" '5. **Search before you plan new code.**'
has "planner" "$(cat "$P")" '(step 4)'
exit $rc
