---
type: llm
focus: {source: file, path: docs/plans/plan.md}
---
PASS if every task in the plan names the files it creates or changes, states a test with a concrete expected result (an exact output, value or behavior, not "works correctly"), and gives a command that verifies it.

FAIL if any task lacks its files, lacks a concrete expected result, or lacks a verifying command. FAIL if the file is missing or has no tasks.
