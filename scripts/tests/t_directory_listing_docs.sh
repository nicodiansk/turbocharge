#!/usr/bin/env bash
# ABOUTME: Asserts README and .claude/CLAUDE.md give the real directory install/update id and the accurate name history:
# ABOUTME: ours is turbocharge-nicodiansk@anthropic-plugin-directory; another author's same-named plugin is listed too.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
R="$PLUGIN_DIR/README.md"
C="$PLUGIN_DIR/.claude/CLAUDE.md"
ID="turbocharge-nicodiansk@anthropic-plugin-directory"
rc=0
for p in \
    "claude plugin install $ID" \
    "claude plugin update $ID" \
    "claude plugin marketplace add nicodiansk/turbocharge" \
    "claude plugin install turbocharge@turbocharge" \
    "claude plugin update turbocharge@turbocharge" \
    "not both"; do
    grep -qF -- "$p" "$R" || { echo "    README missing: $p"; rc=1; }
done
grep -qF "$ID" "$C"                      || { echo "    CLAUDE.md missing the directory install id"; rc=1; }
grep -qF "turbocharge-aguerlain-lr" "$C" || { echo "    CLAUDE.md name history must name the other author's listing"; rc=1; }
grep -qF "wrongly believed" "$C"         && { echo "    CLAUDE.md still claims the 3.0.0 premise was simply wrong"; rc=1; }
exit $rc
