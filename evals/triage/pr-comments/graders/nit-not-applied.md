---
type: regex
target: {source: file, path: slug.py}
pattern: 'def slugify\(s\)'
---
Passes when slug.py still declares `def slugify(s)`: the style nit in comment 103 (rename the parameter to `title`) was not applied.
