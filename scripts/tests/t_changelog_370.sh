#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.7.0] entry: named references (Like:), lanes by task shape (merge, at most 3),
# ABOUTME: memory with provenance (ruled, supersedes, proposals, decisions), and no source-of-inspiration names.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.7\.0\]" "$F" || { echo "    missing [3.7.0] entry"; exit 1; }
SECTION="$(mktemp)"; trap 'rm -f "$SECTION"' EXIT
awk '/^## \[3\.7\.0\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in 'Named references' '### Added' '### Changed' '### Upgrading' '`Like:`' 'differs:' 'at most 3' \
    'one mutation' 'ruled' 'supersedes' 'not yet ruled' 'decisions' 'Directory copy' 'turbocharge@turbocharge' \
    "The evals weren't rerun" 't_plan_like.sh' 't_lane_shape.sh' 't_memory_provenance.sh' 't_agent_scope.sh'; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.7.0] section missing: $p"; rc=1; }
done
# Release Naming: name a release by what it does, never after the source of inspiration.
grep -qiE 'glitch|Lab [0-9]' "$SECTION" && { echo "    [3.7.0] section names its source of inspiration"; rc=1; }
exit $rc
