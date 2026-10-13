#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.name "Eval Fixture"
git config user.email "fixture@example.com"
cat > pricing.py <<'PY'
"""Price helpers for the checkout."""


def discounted(total, pct):
    """Return the price after taking pct percent off total."""
    return total - total * pct / 100
PY
cat > test_pricing.py <<'PY'
import unittest

from pricing import discounted


class DiscountedTest(unittest.TestCase):
    def test_ten_percent_off_one_hundred(self):
        self.assertEqual(discounted(100, 10), 90.0)

    def test_zero_percent_changes_nothing(self):
        self.assertEqual(discounted(80, 0), 80.0)


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "feat: discounted price helper"
cat > pricing.py <<'PY'
"""Price helpers for the checkout."""


def discounted(total, pct):
    """Return the price after taking pct percent off total."""
    return total * pct / 100
PY
git add -A
git commit -q -m "refactor: simplify discount math"
