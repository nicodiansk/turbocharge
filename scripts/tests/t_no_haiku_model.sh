#!/usr/bin/env bash
# ABOUTME: Enforces the Sonnet floor — no agent definition may set model: haiku.
# ABOUTME: Also asserts validate.sh carries the guard so the check can't be silently dropped.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"

# No agent file may declare a haiku model.
for f in "$PLUGIN_DIR"/agents/*.md; do
    [ -f "$f" ] || continue
    if grep -qiE "^model:[[:space:]]*haiku" "$f"; then
        echo "    $(basename "$f") sets a banned 'model: haiku' (Sonnet floor)"
        exit 1
    fi
done

# validate.sh must contain the haiku guard (regression: don't let it be removed).
assert_grep "$PLUGIN_DIR/scripts/validate.sh" "model:\[\[:space:\]\]\*haiku" || exit 1
