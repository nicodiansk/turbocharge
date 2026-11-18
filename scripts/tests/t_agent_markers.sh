#!/usr/bin/env bash
# ABOUTME: Asserts the planner, builder and verifier carry no capital-letter markers (MANDATORY, MUST include, ONE claim).
# ABOUTME: Each section already gives its reason; the headings keep the prefixes other tests match.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
rc=0
P="$PLUGIN_DIR/agents/planner.md"; B="$PLUGIN_DIR/agents/builder.md"; V="$PLUGIN_DIR/agents/verifier.md"
for f in "$P" "$B" "$V"; do assert_file "$f" || exit 1; done
lacks() { # lacks <file> <phrase>
    tr -d '\r' < "$1" | grep -qF -- "$2" && { echo "    $(basename "$1") must not have: $2"; rc=1; }
}
starts() { # starts <file> <prefix>
    tr -d '\r' < "$1" | grep -q -- "^$2" || { echo "    $(basename "$1") has no line starting: $2"; rc=1; }
}
lacks "$P" '(MANDATORY'
lacks "$P" 'MUST include'
lacks "$B" '(MANDATORY)'
lacks "$V" 'ONE claim'
starts "$P" '### Verify Domain Understanding First'
starts "$P" '## Spec Self-Review'
starts "$B" '### Verify Domain Understanding'
exit $rc
