---
type: llm
---
The branch's `build_invoice` in invoice.py calls `apply_rate(subtotal, 0.0825)`, but money.py's `apply_rate` takes basis points (825 means 8.25 percent). With 0.0825 the tax always rounds down to 0 cents.

PASS if the final reply identifies this defect: the tax rate is passed in the wrong unit (a fraction instead of basis points), so tax comes out as zero, in any wording.

FAIL if the reply does not mention it, or calls the tax calculation fine.
