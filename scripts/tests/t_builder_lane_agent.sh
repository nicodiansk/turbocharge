#!/usr/bin/env bash
# ABOUTME: Asserts the builder runs a whole plan lane: pathspec commits, per-task tests, no full suite mid-overlap.
# ABOUTME: Also asserts its 1h prompt-cache TTL (experimental.cacheTtl) so SendMessage fix rounds stay warm.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/agents/builder.md"
assert_file "$F" || exit 1
FM="$(frontmatter "$F")"
printf '%s\n' "$FM" | grep -qx 'experimental:'  || { echo "    builder frontmatter missing experimental: map"; exit 1; }
printf '%s\n' "$FM" | grep -qx '  cacheTtl: 1h' || { echo "    builder frontmatter missing '  cacheTtl: 1h'"; exit 1; }
rc=0
for p in "-- <this task's files>" 'index.lock' 'full suite' 'SendMessage' '.pre-commit-config.yaml' \
         '.lintstagedrc' 'package.json' '.husky/' 'plan-time'; do
    grep -qF -- "$p" "$F" || { echo "    builder.md missing: $p"; rc=1; }
done
exit $rc
