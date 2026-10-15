#!/usr/bin/env bash
# ABOUTME: Asserts every skill and agent frontmatter is strict YAML. Claude Code reads a loose value such as
# ABOUTME: "description: ... merges: a review", but the claude.ai directory's scan can't, and holds the version (REACH_UNKNOWN).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
if command -v ruby >/dev/null 2>&1; then
    parse() { ruby -ryaml -e 'begin; YAML.safe_load(STDIN.read); rescue => e; warn e.message; exit 1; end'; }
elif command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' 2>/dev/null; then
    parse() { python3 -c 'import sys, yaml
try:
    yaml.safe_load(sys.stdin.read())
except yaml.YAMLError as e:
    sys.stderr.write(str(e)); sys.exit(1)'; }
else
    echo "    no strict YAML parser (ruby or python3 with PyYAML), skipping"; exit 0
fi
rc=0
for f in "$PLUGIN_DIR"/skills/*/SKILL.md "$PLUGIN_DIR"/agents/*.md; do
    [ -f "$f" ] || continue
    err="$(frontmatter "$f" | parse 2>&1)" || { echo "    ${f#$PLUGIN_DIR/}: frontmatter is not strict YAML: $err"; rc=1; }
done
exit $rc
