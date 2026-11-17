#!/usr/bin/env bash
# ABOUTME: Asserts wrap's step 10 archives finished plans: which docs leave docs/plans/ (done marker, exclusions, siblings, 14-day proposal),
# ABOUTME: how they move (git mv only for tracked files, never overwrite, commit by pathspec), the delivered line and the skill's size bound.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
W="$PLUGIN_DIR/skills/wrap/SKILL.md"
assert_file "$W" || exit 1
rc=0
sec() { awk -v h="$2" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && /^##/ { s=0 } s' "$1"; }
line_of() { grep -nF -- "$1" "$W" | head -1 | cut -d: -f1; }
P9=$(line_of '### 9.'); P10=$(line_of '### 10. Archive Finished Docs'); PD=$(line_of '## How to Deliver')
if [ -z "$P9" ] || [ -z "$P10" ] || [ -z "$PD" ] || ! [ "$P9" -lt "$P10" ] || ! [ "$P10" -lt "$PD" ]; then
    echo "    wrap ### 10. Archive Finished Docs must sit after ### 9. and before ## How to Deliver ($P9 $P10 $PD)"; rc=1
fi
S=$(sec "$W" '### 10.')
for p in 'docs/plans/*.md' '`docs/plans/archive/`' 'open_files' 'next_steps' 'blockers' 'current_task' 'Context Files' 'Start With' \
    '<!-- plan: in progress -->' '<!-- plan: done YYYY-MM-DD -->' '`\r` stripped' '-<topic>-design.md' '-<topic>-stories.md' \
    '<topic>-2.md' 'more than 14 days' 'all, none, or the numbers' 'never proposed'; do
    printf '%s\n' "$S" | grep -qF -- "$p" || { echo "    wrap step 10 missing: $p"; rc=1; }
done
FILTERED=$(bash "$PLUGIN_DIR/scripts/directory-filter.sh" < "$W")
printf '%s\n' "$FILTERED" | grep -qF '### 10. Archive Finished Docs' || { echo "    filtered wrap lost ### 10."; rc=1; }
exit $rc
