---
type: llm
---
The branch's `import_orders` in importer.py converts the total with `int(float(row["total"]) * 100)`. Float arithmetic turns `"19.99"` into 1998 cents, one cent short.

PASS if the final reply identifies this defect: converting a decimal string to cents through float multiplication loses a cent for some values (for example 19.99), in any wording.

FAIL if the reply does not mention it.
