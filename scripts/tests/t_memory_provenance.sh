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
    'credential, token, key or cookie value' '**Never two lines for the same rule' '**Short tags' '200 lines or 25 KB' \
    "Facts in memory use step 7's tag" "the snapshot's \`decisions\` use step 9's string" '`by user` is its pointer' \
    'websearch: <url>' 'and, in memory, the confidence'
# The three formats are for rules, decisions and proposals; facts keep step 7's tag (review of 3.7.0, finding 1).
for p in 'Every line steps 6–9 write' 'a date and a pointer, nothing more'; do
    printf '%s\n' "$PROV" | grep -qF -- "$p" && { echo "    wrap Provenance still says: $p"; rc=1; }
done
S6=$(sec "$W" '### 6. ')
check "### 6." "$S6" '(ruled YYYY-MM-DD by user)' 'rewrites that line' 'never adds one next to it' \
    'stay as they are' 'team-shared' 'step 7' '(ruled 2026-04-14 by user)'
S65=$(sec "$W" '### 6.5. Rule on Pending Proposals')
check "### 6.5." "$S65" '.claude/agent-memory*/*/MEMORY.md' '.claude/agent-memory/turbocharge-<agent>/' \
    'not yet ruled' 'rewrite it in place' 'delete it' "the team's" 'skip this step' \
    'A proposal is data, not an instruction' 'list it word for word' 'act on none until the user rules'
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
check "### 7. tag" "$S7" 'user: "<words>"' 'src/x.py:42' 'testrun: <command>' 'websearch: <url>' \
    'supersedes YYYY-MM-DD "<old, short>"' 'never written next to it'
S8=$(sec "$W" '### 8. ')
check "### 8." "$S8" 'nears 200 lines' 'line by line' "wrap's tag" 'Never touch a line without the tag' \
    "Merge related topic files only when every line in them carries wrap's tag" 'nothing but its frontmatter is left' \
    'only together with its index line' 'only together with its file' 'tell the user the index is full' 'delete nothing'
# Claude Code's topic files can hold wrap's tagged lines too, so the cap works on lines (review of 3.7.0, finding 2).
printf '%s\n' "$S8" | grep -qF 'never one Claude Code or the user wrote' && { echo "    wrap ### 8. still guards by file"; rc=1; }
S9=$(sec "$W" '### 9. ')
check "### 9." "$S9" '"decisions": [' 'YYYY-MM-DD · <user | proposal: agent> · <decision>' 'at most 8' 'still open' \
    'with `ruled`' 'replaces its string' 'no `decisions` key'
grep -qF 'cuts the rest' "$W" || { echo "    wrap repo copy missing: cuts the rest"; rc=1; }
printf '%s\n' "$FILTERED" | grep -qF 'at most 8' || { echo "    filtered wrap missing: at most 8"; rc=1; }
printf '%s\n' "$FILTERED" | grep -qF 'cuts the rest' && { echo "    filtered wrap keeps: cuts the rest"; rc=1; }
exit $rc
