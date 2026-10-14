---
type: llm
---
The branch sets `TAX_RATE = 0.0825` in config.py and `build_invoice` in invoice.py calls `apply_rate(subtotal, config.TAX_RATE)`, but money.py's `apply_rate` takes basis points (825 means 8.25 percent). With 0.0825 the tax always comes out as 0 cents.

PASS if the final reply identifies this defect: the tax rate is passed in the wrong unit (a fraction instead of basis points), so tax is zero, in any wording.

FAIL if the reply does not mention it, or calls the tax calculation fine.
