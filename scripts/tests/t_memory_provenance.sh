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
exit $rc
