#!/usr/bin/env bash
# ABOUTME: Asserts the plan contract carries the Lanes Model column: sonnet, or opus · <reason> with one of four fixed
# ABOUTME: reasons, and — for inline; a chain takes the higher Model; a six-column table still builds as all sonnet.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/plan/SKILL.md"
assert_file "$S" || exit 1
rc=0
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
has() { # has <label> <text> <phrase>
    printf '%s\n' "$2" | grep -qF -- "$3" || { echo "    $1 missing: $3"; rc=1; }
}
HEADER='| Lane | Owns files | Tasks | After | Executor | Effort | Model |'

grep -qF -- "$HEADER" "$S" || { echo "    plan skill missing the seven-column Lanes header"; rc=1; }
H="$(sec "$S" '## Plan Document Header' '## Context Gathering')"
for p in '`concurrency`' '`security`' '`irreversible`' '`edge-cases`' '`opus · <reason>`' 'six-column table' 'the higher Model'; do
    has "plan Plan Document Header" "$H" "$p"
done
has "plan 'Check the saved plan' line" "$(grep -F 'Check the saved plan' "$S" | tr -d '\r')" 'one of the four reasons'
has "plan 'No agent here' line" "$(grep -F '**No agent here:**' "$S" | tr -d '\r')" 'one of the four reasons'

# The planner writes the column (Lanes rules and the Plan Format template) and checks every cell before it finishes.
P="$PLUGIN_DIR/agents/planner.md"
assert_file "$P" || exit 1
N="$(tr -d '\r' < "$P" | grep -cF -- "$HEADER")"
[ "$N" -ge 2 ] || { echo "    planner.md holds the seven-column header $N times, wants 2 (Lanes and Plan Format)"; rc=1; }
LN="$(sec "$P" '## Lanes' '## Task Sizing')"
for p in '`concurrency`' '`security`' '`irreversible`' '`edge-cases`' 'the higher Model'; do
    has "planner Lanes" "$LN" "$p"
done
has "planner Spec Self-Review" "$(sec "$P" '## Spec Self-Review' '## Plan Format')" 'one of the four reasons'
has "planner Quality Checklist" "$(sec "$P" '## Quality Checklist' '## Remember')" 'one of the four reasons'

# The planning eval grades the column; lanes-table.md keeps its pattern, so before and after stay comparable.
G="$PLUGIN_DIR/evals/planning/csv-export/graders/lanes-model.md"
if [ -f "$G" ]; then
    FM="$(frontmatter "$G")"
    for p in 'type: llm' 'arm: with-only' 'docs/plans/plan.md'; do has "lanes-model.md frontmatter" "$FM" "$p"; done
    BODY="$(awk '{ sub(/\r$/, "") } NR == 1 && $0 == "---" { f = 1; next } f && $0 == "---" { f = 0; next } !f' "$G")"
    for p in Model sonnet opus; do has "lanes-model.md body" "$BODY" "$p"; done
else
    echo "    missing evals/planning/csv-export/graders/lanes-model.md"; rc=1
fi
T="$(grep '^pattern:' "$PLUGIN_DIR/evals/planning/csv-export/graders/lanes-table.md" | tr -d '\r')"
[ "$T" = "pattern: '\| Lane \| Owns files \| Tasks \| After \| Executor \| Effort \|'" ] \
    || { echo "    lanes-table.md pattern changed: $T"; rc=1; }
exit $rc
