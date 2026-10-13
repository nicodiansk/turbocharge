#!/usr/bin/env bash
# ABOUTME: Asserts reviewers judge unspecified behavior by reasonable-user expectations and list what they declined to judge.
# ABOUTME: 3.3.0 quality pack item 2: code-reviewer, task-reviewer, and the review skill (with its inline fallback).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
C="$PLUGIN_DIR/agents/code-reviewer.md"
T="$PLUGIN_DIR/agents/task-reviewer.md"
for f in "$C" "$T"; do
    assert_file "$f" || exit 1
    for p in 'reasonable user' 'Declined to judge' 'Declined to judge: none'; do
        grep -qF "$p" "$f" || { echo "    $(basename "$f") missing: $p"; exit 1; }
    done
done

# code-reviewer: Declined to judge comes before the Assessment step, and Review Focus pins are checked.
d=$(grep -nF 'Declined to judge' "$C" | head -1 | cut -d: -f1)
a=$(grep -nF 'Assessment' "$C" | head -1 | cut -d: -f1)
[ -n "$d" ] && [ -n "$a" ] && [ "$d" -lt "$a" ] || { echo "    code-reviewer: Declined to judge (line $d) must precede Assessment (line $a)"; exit 1; }
grep -qF 'Review Focus' "$C" || { echo "    code-reviewer must check the plan's Review Focus pins"; exit 1; }

# task-reviewer: build reads the two verdict lines first, so the Report Shape fence must still open with Spec.
first=$(awk '{ sub(/\r$/, "") } /^## Report Shape/ { s=1 } s && /^```/ { f=1; next } f { print; exit }' "$T")
[ "$first" = 'Spec: ✅ | ❌' ] || { echo "    task-reviewer Report Shape fence must open with 'Spec: ✅ | ❌' (got '$first')"; exit 1; }

# review skill: same rule, declined lines in the report, and an inline fallback when the agent can't be dispatched.
R="$PLUGIN_DIR/skills/review/SKILL.md"
assert_file "$R" || exit 1
for p in 'Declined to judge' 'reasonable user' 'not registered' 'inline'; do
    grep -qF "$p" "$R" || { echo "    review skill missing: $p"; exit 1; }
done
exit 0
