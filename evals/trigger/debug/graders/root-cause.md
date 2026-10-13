---
type: llm
---
The user's test expects `discounted(100, 10)` to be 90.0 but got 10.0.

PASS if the final reply identifies that `discounted` now returns the discount amount (total * pct / 100) instead of the price after the discount (total minus that amount). Naming the "simplify discount math" refactor commit as the cause is a plus but not required.

FAIL if the reply gives a different cause, only suggests re-running or editing the test, or does not identify what changed in `discounted`.
