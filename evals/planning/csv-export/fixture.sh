#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.name "Eval Fixture"
git config user.email "fixture@example.com"
cat > contacts.json <<'JSON'
[
  {"name": "Ada Lovelace", "email": "ada@example.com", "phone": "555-0101"},
  {"name": "Grace Hopper", "email": "grace@example.com", "phone": "555-0102"},
  {"name": "Alan Turing", "email": "alan@example.com", "phone": "555-0103"}
]
JSON
cat > contacts.py <<'PY'
"""Tiny contacts tool: lists contacts stored in contacts.json."""
import json
import sys
from pathlib import Path

DATA_FILE = Path(__file__).with_name("contacts.json")


def load_contacts(path=DATA_FILE):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def format_contact(contact):
    return f"{contact['name']} <{contact['email']}> {contact['phone']}"


def main(argv):
    if len(argv) == 2 and argv[1] == "list":
        for contact in load_contacts():
            print(format_contact(contact))
        return 0
    print("usage: python contacts.py list", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
PY
cat > test_contacts.py <<'PY'
import unittest

from contacts import format_contact, load_contacts


class ContactsTest(unittest.TestCase):
    def test_load_contacts_reads_the_data_file(self):
        self.assertEqual(len(load_contacts()), 3)

    def test_format_contact(self):
        contact = {"name": "Ada", "email": "ada@example.com", "phone": "555-0101"}
        self.assertEqual(format_contact(contact), "Ada <ada@example.com> 555-0101")


if __name__ == "__main__":
    unittest.main()
PY
cat > SPEC.md <<'MD'
# CSV export

Add an `export` verb to the contacts tool:

    python contacts.py export out.csv

It writes the contacts to `out.csv` with the header row `name,email,phone`,
then one row per contact, sorted by name.

The existing `list` verb keeps working. Tests use `python -m unittest`.
MD
git add -A
git commit -q -m "feat: contacts list command"
