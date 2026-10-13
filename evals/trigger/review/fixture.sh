#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.name "Eval Fixture"
git config user.email "fixture@example.com"
cat > README.md <<'MD'
# greeter

A tiny greeting library.
MD
git add -A
git commit -q -m "chore: initial commit"
git checkout -q -b feature/greeting
cat > greeting.py <<'PY'
"""Greeting helpers."""


def greet(name):
    """Return a greeting for name."""
    return "Hello, world"
PY
cat > test_greeting.py <<'PY'
import unittest

from greeting import greet


class GreetTest(unittest.TestCase):
    def test_greets(self):
        self.assertTrue(greet("Ada").startswith("Hello"))


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "feat: add greet(name)"
