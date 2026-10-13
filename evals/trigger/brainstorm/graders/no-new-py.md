---
type: regex
target: files
pattern: '\.py$'
flags: m
match: not_contains
---
Passes when no new .py file was created by any means (Write, Bash, or otherwise).
