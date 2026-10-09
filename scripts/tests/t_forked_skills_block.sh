#!/usr/bin/env bash
# ABOUTME: Asserts every `context: fork` skill sets `background: false` so it blocks until done.
# ABOUTME: Claude Code 2.1.218+ runs forked skills in the background; plan/review output gates the next step.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
for s in plan review; do
    F="$PLUGIN_DIR/skills/$s/SKILL.md"
    assert_file "$F" || exit 1
    frontmatter "$F" | grep -qx "background: false" \
        || { echo "    skills/$s/SKILL.md frontmatter missing 'background: false'"; exit 1; }
done
# Guard: any future forked skill must opt out of background execution too.
for F in "$PLUGIN_DIR"/skills/*/SKILL.md; do
    frontmatter "$F" | grep -qx "context: fork" || continue
    frontmatter "$F" | grep -qx "background: false" \
        || { echo "    $(basename "$(dirname "$F")") is context: fork without background: false"; exit 1; }
done
exit 0
