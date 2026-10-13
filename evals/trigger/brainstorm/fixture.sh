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
cat > README.md <<'MD'
# contacts

A small command line tool. `python contacts.py list` prints every contact.
MD
git add -A
git commit -q -m "feat: contacts list command"
