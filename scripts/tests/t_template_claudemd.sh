#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/templates/CLAUDE-turboflow.md"
assert_file "$F" || exit 1
for marker in tdd debug naming file-header domain-terms; do
    assert_grep "$F" "<!-- turboflow:${marker} -->"    || exit 1
    assert_grep "$F" "<!-- /turboflow:${marker} -->"   || exit 1
    # Each block has at least one non-empty line between open and close markers.
    body=$(awk -v m="$marker" '
        $0 ~ "<!-- turboflow:" m " -->" { inblock=1; next }
        $0 ~ "<!-- /turboflow:" m " -->" { inblock=0 }
        inblock { print }
    ' "$F" | grep -v '^[[:space:]]*$' | head -1)
    [ -n "$body" ] || { echo "    block '$marker' empty between markers"; exit 1; }
done
