---
type: llm
---
SPEC.md says a corrupt or unreadable saved file is reported to the user. The branch's `load_orders` in persistence.py wraps reading the file in `except Exception: return []`, so a corrupt data file reads as "no orders" and nothing is reported.

PASS if the final reply identifies this defect: errors while loading the saved file are swallowed and an empty list is returned, in any wording.

FAIL if the reply does not mention it.
