#!/usr/bin/env bash
# ABOUTME: Asserts wrap writes every memory, CLAUDE.md and snapshot line with who decided and where it came from.
# ABOUTME: Named refs and lane shape, wrap lane: Provenance, steps 6 to 9 of skills/wrap/SKILL.md.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
W="$PLUGIN_DIR/skills/wrap/SKILL.md"
assert_file "$W" || exit 1
rc=0
# An H3 section ends at the next line starting with ##.
sec() { awk -v h="$2" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && /^##/ { s=0 } s' "$1"; }
check() { # name, section text, phrases...
    local name="$1" text="$2" p; shift 2
    for p in "$@"; do
        printf '%s\n' "$text" | grep -qF -- "$p" || { echo "    wrap $name missing: $p"; rc=1; }
    done
}
line_of() { grep -nF -- "$1" "$W" | head -1 | cut -d: -f1; }

P55=$(line_of '### 5.5.'); PV=$(line_of '### Provenance'); P6=$(line_of '### 6.')
if [ -z "$P55" ] || [ -z "$PV" ] || [ -z "$P6" ] || ! [ "$P55" -lt "$PV" ] || ! [ "$PV" -lt "$P6" ]; then
    echo "    wrap ### Provenance must sit below ### 5.5. and above ### 6. ($P55 $PV $P6)"; rc=1
fi
PROV=$(sec "$W" '### Provenance')
check Provenance "$PROV" '`<rule> (ruled YYYY-MM-DD by user)`' \
    '`<new rule> (ruled YYYY-MM-DD, supersedes YYYY-MM-DD "<old, short>")`' \
    '`[proposal · <agent> · YYYY-MM-DD · not yet ruled] <text>`' \
    'the old line is deleted' '**No pointer, no line.**' "sed -n '<line>p' <file>" \
    'credential, token, key or cookie value' '**Never two lines for the same rule' '**Short tags' '200 lines or 25 KB'
S6=$(sec "$W" '### 6. ')
check "### 6." "$S6" '(ruled YYYY-MM-DD by user)' 'rewrites that line' 'never adds one next to it' \
    'stay as they are' 'team-shared' 'step 7' '(ruled 2026-04-14 by user)'
S65=$(sec "$W" '### 6.5. Rule on Pending Proposals')
check "### 6.5." "$S65" '.claude/agent-memory*/*/MEMORY.md' '.claude/agent-memory/turbocharge-<agent>/' \
    'not yet ruled' 'rewrite it in place' 'delete it' "the team's" 'skip this step'
check "## How to Deliver" "$(sec "$W" '## How to Deliver')" '.claude/agent-memory*/*/MEMORY.md'
FILTERED=$(bash "$PLUGIN_DIR/scripts/directory-filter.sh" < "$W")
printf '%s\n' "$FILTERED" | grep -qF '### 6.5.' || { echo "    filtered wrap lost ### 6.5."; rc=1; }
printf '%s\n' "$FILTERED" | grep -qi 'agent memory' && { echo "    filtered wrap says agent memory"; rc=1; }
printf '%s\n' "$FILTERED" | grep -qF 'SessionStart' && { echo "    filtered wrap says SessionStart"; rc=1; }
S7=$(sec "$W" '### 7. ')
grep -qF -- "### 7. Write Memory in Auto Memory's Shape" "$W" || { echo "    wrap missing heading: ### 7. Write Memory in Auto Memory's Shape"; rc=1; }
check "### 7." "$S7" '- [Title](file.md) — one-line hook' 'No `MEMORY.md` yet' \
    '# Memory Index' '`name`, `description` and `metadata.type`' '`user`, `feedback`, `project` or `reference`' \
    'Never write what the code or CLAUDE.md already says' 'tagged bullets from an older wrap' 'delete none'
exit $rc
