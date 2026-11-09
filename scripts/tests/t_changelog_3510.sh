#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.5.10] entry: 3.5.9 still had two refused frontmatter keys, so the directory copy
# ABOUTME: swaps the tools: allowlists for a denylist and makes setup model-invocable, and the count says which it was.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.5\.10\]" "$F" || { echo "    missing [3.5.10] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.5\.10\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "LOCAL_CODE_FRONTMATTER_KEY" "count 2" "tools" "disallowedTools" "Agent" "disable-model-invocation" "setup" \
    "ship" "context" "agent" "release.sh" "t_release_tree.sh" "turbocharge@turbocharge" "evals" \
    "0 means" "1 means" "2 means" "counts occurrences of keys"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.5.10] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
