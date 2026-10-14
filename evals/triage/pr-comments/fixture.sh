#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.name "Eval Fixture"
git config user.email "fixture@example.com"

printf '# Slug tools\n\nSmall text helpers.\n' > README.md
git add -A
git commit -q -m "chore: readme"

git checkout -q -b feature/slugify

cat > slug.py <<'PY'
"""Turn titles into URL slugs."""


def slugify(s):
    if not s:
        return ""
    return "-".join(s.lower().split(" "))
PY

cat > test_slug.py <<'PY'
import unittest

from slug import slugify


class SlugTest(unittest.TestCase):
    def test_words_are_joined_with_hyphens(self):
        self.assertEqual(slugify("Hello World"), "hello-world")

    def test_empty_string_stays_empty(self):
        self.assertEqual(slugify(""), "")


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "feat: slugify"

# The saved review comments live outside version control.
cat > pr-comments.json <<'JSON'
{
  "pr": 7,
  "branch": "feature/slugify",
  "comments": [
    {
      "id": 101,
      "kind": "inline",
      "author": "dana",
      "path": "slug.py",
      "line": 7,
      "body": "slugify('  Hello  World ') gives '--hello--world-'. Use split() instead of split(' ')."
    },
    {
      "id": 102,
      "kind": "issue",
      "author": "claude[bot]",
      "body": "slugify crashes with an IndexError on an empty string."
    },
    {
      "id": 103,
      "kind": "inline",
      "author": "dana",
      "path": "slug.py",
      "line": 4,
      "body": "nit: call the parameter `title`."
    }
  ]
}
JSON
printf 'pr-comments.json\n' >> .git/info/exclude
