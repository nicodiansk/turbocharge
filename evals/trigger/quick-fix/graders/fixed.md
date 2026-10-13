---
type: regex
target: {source: file, path: README.md}
pattern: recieve
match: not_contains
---
Passes when README.md no longer contains the misspelling "recieve".
