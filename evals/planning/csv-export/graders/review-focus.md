---
type: regex
target: {source: file, path: docs/plans/plan.md}
pattern: '## Review Focus[\s\S]{0,1500}(comma|quot)'
flags: i
arm: with-only
---
Passes when the plan's Review Focus section calls out comma or quote handling.
