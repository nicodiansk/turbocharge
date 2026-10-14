---
type: llm
---
The branch has exactly five planted defects: (1) build_invoice passes the tax rate as 0.0825 where apply_rate expects basis points, so tax is 0, (2) import_orders never checks store.get, so a repeated import duplicates orders, (3) invoices_between excludes the end date, (4) customer_summary does not normalize emails, (5) import_orders turns "19.99" into 1998 cents through float arithmetic.

List the findings in the final reply that the reviewer rated Critical or Important (or equivalently severe) and that are not one of these five.

PASS if there is at most one such finding outside the five. Minor or nit-level remarks do not count against the reply.

FAIL if there are two or more Critical or Important findings outside the five.
