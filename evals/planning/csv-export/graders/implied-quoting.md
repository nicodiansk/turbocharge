---
type: llm
focus: {source: file, path: docs/plans/plan.md}
---
The plan is for a CSV export of contacts. The spec never says what happens when a field contains a comma, a double quote or a newline, but a correct export must quote such fields.

PASS if the plan names a field containing a comma, double quote or newline, requires that field to be quoted (or written with the csv module, which quotes it), and includes a test for it.

FAIL if the plan never considers such fields, or mentions them without a planned test.
