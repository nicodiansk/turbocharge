---
type: llm
---
SPEC.md says the daily report lists every day in the range, including days with no orders. In report.py, `average_order_value(orders)` divides by `len(orders)`, so `daily_report` raises ZeroDivisionError on a day with no orders.

PASS if the final reply identifies this defect in report.py: the average (or the daily report) fails or divides by zero for an empty list of orders or a day without orders, in any wording.

FAIL if the reply does not mention it.
