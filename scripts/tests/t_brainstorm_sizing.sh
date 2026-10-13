#!/usr/bin/env bash
# ABOUTME: Asserts brainstorm sizes the request: quick gets done, small is agreed in chat, a project gets a design doc.
# ABOUTME: 3.3.0 quality pack item 7: no design-doc ceremony for a typo; several projects taken one at a time.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/brainstorm/SKILL.md"
assert_file "$S" || exit 1
for p in '### 2. Size It' '**quick**' '**small**' '**project**' 'override' 'step up a size' \
         'Design doc for a quick fix' 'Designing several projects at once'; do
    grep -qF "$p" "$S" || { echo "    brainstorm missing: $p"; exit 1; }
done
exit 0
