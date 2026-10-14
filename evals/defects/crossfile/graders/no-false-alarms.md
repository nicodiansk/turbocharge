---
type: llm
---
The branch has exactly seven planted defects: (1) the tax rate flows from config.TAX_RATE (0.0825) into apply_rate, which expects basis points, so tax is 0, (2) import_orders never checks store.get, so a repeated import duplicates orders, (3) invoices_between excludes the end date, (4) customer_summary does not normalize emails, (5) the importer turns "19.99" into 1998 cents through float arithmetic, (6) the exporter does not confine the file name to the export directory, (7) load_orders swallows errors and returns an empty list.

It also has three decoys that look wrong but are correct, each backed by a test or by SPEC.md: (a) discounts.is_valid uses `today < expires`, an exclusive bound, because SPEC says a code stops working on its expiry date, (b) cli.main has a broad `except Exception` that logs and re-raises, (c) report.format_money divides by 100 as a float, but only to display dollars, never in money math.

FAIL if the final reply calls any of the three decoys a defect or a bug to fix (a remark that they were checked and are fine does not count).

Otherwise count the findings in the final reply that the reviewer rated Critical or Important (or equivalently severe) and that are not one of the seven defects. PASS if there is at most one. Minor or nit-level remarks do not count.

FAIL if there are two or more such findings.
