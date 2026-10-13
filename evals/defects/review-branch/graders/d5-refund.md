---
type: llm
---
SPEC.md says refunded orders are excluded from customer totals. In report.py, `customer_totals` subtracts refunded amounts instead of excluding them, and no test includes a refunded order.

PASS if the final reply identifies this defect in report.py: refunds are subtracted rather than excluded from customer totals. It also passes if the reply says refunds are untested in customer_totals.

FAIL if the reply does not mention refunds in customer_totals.
