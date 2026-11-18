#!/usr/bin/env bash
# ABOUTME: Asserts wrap states its rules at normal volume and its no-files line names every file wrap writes.
# ABOUTME: 3.8.0 prompt hygiene, handed over from stream A: F09, F11, F21, F23.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
W="$PLUGIN_DIR/skills/wrap/SKILL.md"
assert_file "$W" || exit 1
rc=0
BODY=$(tr -d '\r' < "$W")
for p in 'NO SESSION END WITHOUT WRAP OFFER' 'proactively offer' 'MUST appear' '(MANDATORY)' 'handles persistence automatically'; do
    ! printf '%s\n' "$BODY" | grep -qF -- "$p" || { echo "    wrap still has: $p"; rc=1; }
done
printf '%s\n' "$BODY" | grep -qF -- 'Keep `@.claude/turbocharge-session.json` on the first line of every resume prompt' \
    || { echo "    wrap missing the resume prompt's first-line rule"; rc=1; }
# F11: the How to Deliver exception list names the .gitignore line and the ATLAS.md refresh.
DELIVER=$(printf '%s\n' "$BODY" | grep -F '**Output the resume prompt directly in chat**')
for p in "step 9's" 'ATLAS.md' 'where git tracks it'; do
    printf '%s\n' "$DELIVER" | grep -qF -- "$p" || { echo "    wrap's How to Deliver exceptions missing: $p"; rc=1; }
done
exit $rc
