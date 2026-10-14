#!/usr/bin/env bash
# ABOUTME: Asserts brainstorm's description reaches short, underspecified feature requests (3.3 measured Fired 0/3).
# ABOUTME: It must not quote the eval's own prompt: that would measure the eval, not the trigger.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/brainstorm/SKILL.md"
assert_file "$S" || exit 1
D="$(frontmatter "$S" | sed -n 's/^description:[[:space:]]*//p')"
[ -n "$D" ] || { echo "    brainstorm has no description"; exit 1; }
for p in "hasn't said exactly how" 'quick fix'; do
    printf '%s' "$D" | grep -qF "$p" || { echo "    description missing: $p"; exit 1; }
done
printf '%s' "$D" | grep -qiE 'CSV export|add CSV' && { echo "    description quotes the trigger eval's prompt"; exit 1; }
[ "${#D}" -lt 1024 ] || { echo "    description is ${#D} characters; keep it under 1024"; exit 1; }
exit 0
