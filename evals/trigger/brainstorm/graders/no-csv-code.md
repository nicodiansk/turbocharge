---
type: regex
target: {source: file, path: contacts.py}
pattern: 'csv|export'
flags: i
match: not_contains
---
Passes when contacts.py still has no CSV or export code: the request is explored before anything is built.
