---
type: llm
---
SPEC.md says customers are identified by their email address. The branch's `customer_summary` in invoice.py groups by the raw email string, so `Ann@x.com` and `ann@x.com ` (different letter case, stray whitespace) count as two customers.

PASS if the final reply identifies this defect: emails are not normalized (letter case or surrounding whitespace) before grouping or identifying customers, in any wording.

FAIL if the reply does not mention it.
