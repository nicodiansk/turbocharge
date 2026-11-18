#!/usr/bin/env bash
# ABOUTME: Asserts story states its acceptance-criteria rule once, with the reason, and no capital-letter fence.
# ABOUTME: 3.8.0 prompt hygiene F19: the INVEST table stays.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/story/SKILL.md"
assert_file "$S" || exit 1
rc=0
BODY=$(tr -d '\r' < "$S")
for p in 'NO STORY WITHOUT' 'No exceptions' 'Later never comes'; do
    ! printf '%s\n' "$BODY" | grep -qF -- "$p" || { echo "    story still has: $p"; rc=1; }
done
for p in 'the obvious ones included' '## The Iron Law' '## INVEST Criteria'; do
    printf '%s\n' "$BODY" | grep -qF -- "$p" || { echo "    story missing: $p"; rc=1; }
done
exit $rc
