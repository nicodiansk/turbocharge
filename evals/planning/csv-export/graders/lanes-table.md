---
type: regex
target: {source: file, path: docs/plans/plan.md}
pattern: '\| Lane \| Owns files \| Tasks \| After \| Executor \| Effort \|'
arm: with-only
---
Passes when the plan has turbocharge's Lanes table header.
