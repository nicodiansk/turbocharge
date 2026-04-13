#!/usr/bin/env bash
# Fails (exit 1) if any banned vocabulary appears in the staged copy fragments
# or in README.md once assembled.
#
# Banned list tracks design doc §Positioning Core → Banned vocabulary.
# Note: "orchestration" is banned in the tagline only (ruflo owns it there) —
# body copy may use it. Per 2026-04-13 plan-review decision, excluded from the
# global regex to avoid false positives on the hero paragraph's "stop
# maintaining your own orchestration" line.
set -euo pipefail

BANNED='powerful|comprehensive|advanced|platform|framework|learns'
TARGETS="${*:-docs/plans/positioning-copy README.md}"

hits=$(grep -REin --include='*.md' "\b(${BANNED})\b" $TARGETS || true)
if [ -n "$hits" ]; then
  echo "BANNED VOCABULARY FOUND:"
  echo "$hits"
  exit 1
fi
echo "lint-positioning: clean"
