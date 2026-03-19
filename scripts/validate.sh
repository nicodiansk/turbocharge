#!/usr/bin/env bash
# ABOUTME: Plugin health check script.
# ABOUTME: Validates skill frontmatter, agent definitions, and plugin structure.

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0
WARNINGS=0

red() { printf '\033[0;31m%s\033[0m\n' "$1"; }
green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$1"; }

error() { red "  ERROR: $1"; ((ERRORS++)); }
warn() { yellow "  WARN:  $1"; ((WARNINGS++)); }
pass() { green "  OK:    $1"; }

echo "=== Turbocharge Plugin Validation ==="
echo "Plugin directory: $PLUGIN_DIR"
echo ""

# 1. Check plugin manifest
echo "--- Plugin Manifest ---"
if [[ -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]]; then
    pass "plugin.json exists"
    if grep -q '"name"' "$PLUGIN_DIR/.claude-plugin/plugin.json"; then
        pass "plugin.json has name field"
    else
        error "plugin.json missing name field"
    fi
    if grep -q '"version"' "$PLUGIN_DIR/.claude-plugin/plugin.json"; then
        pass "plugin.json has version field"
    else
        error "plugin.json missing version field"
    fi
    if grep -q '"author"' "$PLUGIN_DIR/.claude-plugin/plugin.json"; then
        pass "plugin.json has author field"
    else
        error "plugin.json missing author field (required for marketplace)"
    fi
else
    error "plugin.json not found"
fi
echo ""

# 2. Check skills
echo "--- Skills ---"
EXPECTED_SKILLS="brainstorm build debug plan review ship story wrap"
for skill in $EXPECTED_SKILLS; do
    skill_file="$PLUGIN_DIR/skills/$skill/SKILL.md"
    if [[ -f "$skill_file" ]]; then
        # Check frontmatter has name
        if head -10 "$skill_file" | grep -q "^name:"; then
            pass "skills/$skill/SKILL.md — has name"
        else
            error "skills/$skill/SKILL.md — missing name in frontmatter"
        fi
        # Check frontmatter has description
        if head -10 "$skill_file" | grep -q "^description:"; then
            pass "skills/$skill/SKILL.md — has description"
        else
            error "skills/$skill/SKILL.md — missing description in frontmatter"
        fi
        # Check description length (< 1024 chars)
        desc_len=$(sed -n '/^description:/,/^[a-z]/p' "$skill_file" | head -5 | wc -c)
        if (( desc_len > 1024 )); then
            error "skills/$skill/SKILL.md — description exceeds 1024 chars ($desc_len)"
        fi
    else
        error "skills/$skill/SKILL.md — not found"
    fi
done

# Check for unexpected skill directories
for dir in "$PLUGIN_DIR"/skills/*/; do
    skill_name=$(basename "$dir")
    if ! echo "$EXPECTED_SKILLS" | grep -qw "$skill_name"; then
        warn "Unexpected skill directory: skills/$skill_name/"
    fi
done
echo ""

# 3. Check agents
echo "--- Agents ---"
EXPECTED_AGENTS="builder spec-reviewer quality-reviewer code-reviewer planner researcher"
for agent in $EXPECTED_AGENTS; do
    agent_file="$PLUGIN_DIR/agents/$agent.md"
    if [[ -f "$agent_file" ]]; then
        if head -10 "$agent_file" | grep -q "^name:"; then
            pass "agents/$agent.md — has name"
        else
            error "agents/$agent.md — missing name in frontmatter"
        fi
        if head -10 "$agent_file" | grep -q "^description:"; then
            pass "agents/$agent.md — has description"
        else
            error "agents/$agent.md — missing description in frontmatter"
        fi
        if grep -q "^memory:" "$agent_file"; then
            pass "agents/$agent.md — has memory field"
        else
            warn "agents/$agent.md — missing memory field"
        fi
    else
        error "agents/$agent.md — not found"
    fi
done
echo ""

# 4. Check for broken cross-references
echo "--- Cross-References ---"
STALE_REFS="turbocharge:test-driven-development turbocharge:session-memory turbocharge:executing-plans turbocharge:using-turbocharge turbocharge:writing-plans turbocharge:brainstorming turbocharge:story-breakdown turbocharge:systematic-debugging turbocharge:finishing-a-development-branch turbocharge:requesting-code-review"
found_stale=0
for ref in $STALE_REFS; do
    matches=$(grep -rl "$ref" "$PLUGIN_DIR/skills/" "$PLUGIN_DIR/agents/" 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
        error "Stale v1 reference '$ref' found in: $matches"
        found_stale=1
    fi
done
if (( found_stale == 0 )); then
    pass "No stale v1 cross-references found"
fi
echo ""

# 5. Check required files
echo "--- Required Files ---"
for f in README.md LICENSE settings.json hooks/hooks.json .gitignore; do
    if [[ -f "$PLUGIN_DIR/$f" ]]; then
        pass "$f exists"
    else
        warn "$f not found"
    fi
done
echo ""

# Summary
echo "=== Summary ==="
if (( ERRORS == 0 )); then
    green "PASSED — $ERRORS errors, $WARNINGS warnings"
else
    red "FAILED — $ERRORS errors, $WARNINGS warnings"
fi
exit $ERRORS
