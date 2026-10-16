#!/usr/bin/env bash
# ABOUTME: Asserts ship's menu no longer offers discard; discard stays available only on explicit request.
# ABOUTME: 3.3.0 quality pack item 6: "Discard this work" next to "Merge" advertised destroying finished work.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/ship/SKILL.md"
assert_file "$S" || exit 1
MENU=$(awk '{ sub(/\r$/, "") } /^## Step 3/ { s=1 } s && /^```/ { if (f) exit; f=1; next } f' "$S")
[ -n "$MENU" ] || { echo "    could not find the Step 3 menu fence"; exit 1; }
printf '%s\n' "$MENU" | grep -qi 'discard' && { echo "    Step 3 menu still offers discard"; exit 1; }
grep -qF 'typed "discard" confirmation' "$S" || { echo "    discard must still require the typed confirmation"; exit 1; }
grep -qF 'explicit request' "$S"            || { echo "    discard must be explicit-request only"; exit 1; }
grep -qF 'Options 1, 2, 4' "$S"             && { echo "    cleanup heading still lists Option 4"; exit 1; }
grep -qF 'Option 4' "$S"                    && { echo "    ship still has an Option 4"; exit 1; }
FM=$(frontmatter "$S")
printf '%s\n' "$FM" | grep '^description:' | grep -qF 'or discard' && { echo "    description still offers discard"; exit 1; }
printf '%s\n' "$FM" | grep -q '^disable-model-invocation' && { echo "    ship must be model-invocable (no disable-model-invocation)"; exit 1; }
for p in "waits for the user's pick" 'Never merge'; do
  grep -qF -- "$p" "$S" || { echo "    ship missing: $p"; exit 1; }
done
exit 0
