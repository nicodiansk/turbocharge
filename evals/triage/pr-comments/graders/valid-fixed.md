---
type: llm
focus: {source: file, path: slug.py}
---
Review comment 101 says `slugify('  Hello  World ')` produces extra hyphens (`--hello--world-`) and suggests `split()` instead of `split(" ")`. It is valid.

PASS if slug.py now handles repeated and surrounding spaces, so `'  Hello  World '` no longer yields extra hyphens (for example by using `split()`).

FAIL if slug.py still splits on single spaces only and would produce the extra hyphens.
