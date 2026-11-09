#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.5.11] entry: 3.5.10's count stayed 2, so tools and disable-model-invocation pass,
# ABOUTME: and plan stops forking in both copies (it dispatches the planner) to drop context and agent.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.5\.11\]" "$F" || { echo "    missing [3.5.11] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.5\.11\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "LOCAL_CODE_FRONTMATTER_KEY" "count stayed 2" "context: fork" "agent: planner" "background: false" \
    "turbocharge:planner" "Agent tool" "No agent here" "tools" "disable-model-invocation" "turbocharge@turbocharge" \
    "release.sh" "t_forked_skills_block.sh" "evals"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.5.11] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
