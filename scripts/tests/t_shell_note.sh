#!/usr/bin/env bash
# ABOUTME: Asserts builder and researcher carry the zsh note (arrays for path lists, no variable named path, status or argv).
# ABOUTME: Also that the researcher no longer carries virtue lines ("fast and thorough", "Be thorough").
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
rc=0
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
has() { printf '%s\n' "$2" | grep -qF -- "$3" || { echo "    $1 missing: $3"; rc=1; }; }
B="$PLUGIN_DIR/agents/builder.md"; R="$PLUGIN_DIR/agents/researcher.md"
for f in "$B" "$R"; do assert_file "$f" || exit 1; done
for f in "$B" "$R"; do
    SH=$(sec "$f" '## Shell' '## ')
    for p in '$SHELL' 'CLAUDE_CODE_SHELL' '"${files[@]}"' '`path`' '`status`' '`argv`'; do
        has "$(basename "$f") Shell" "$SH" "$p"
    done
done
for p in 'fast and thorough' 'Be thorough'; do
    tr -d '\r' < "$R" | grep -qF -- "$p" && { echo "    researcher.md must not have: $p"; rc=1; }
done
tr -d '\r' < "$B" | grep -qi 'ATLAS' && { echo "    builder.md must not reference ATLAS"; rc=1; }
exit $rc
