---
type: llm
---
SPEC.md says `invoices_between` returns orders dated from `start` through `end`. The branch's invoice.py uses `start <= date < end`, so orders dated exactly on `end` are left out.

PASS if the final reply identifies this defect: the end date is excluded (an exclusive upper bound where the spec says through `end`), in any wording.

FAIL if the reply does not mention it, or calls the date range fine.
