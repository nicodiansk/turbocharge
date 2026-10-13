---
type: llm
focus: {source: file, path: docs/plans/plan.md}
arm: with-only
---
PASS if no file path appears in the "Owns files" column of two different rows of the plan's Lanes table.

FAIL if any file path is owned by two lanes. FAIL if the plan has no Lanes table.
