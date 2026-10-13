---
type: llm
---
In report.py, `apply_discount` looks up `customers[order["id"]]` (the order id) instead of `customers[order["customer_id"]]`. The tests pass only because their data gives each order the same id as its customer.

PASS if the final reply identifies this defect in report.py: the discount is looked up with the order id instead of the customer id, in any wording.

FAIL if the reply does not mention it.
