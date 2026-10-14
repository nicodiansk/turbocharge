---
type: llm
---
SPEC.md says exports are written inside the export directory. The branch's exporter.py builds the path with `os.path.join(config.EXPORT_DIR, name)` from a caller-supplied name and never checks that the result stays inside `EXPORT_DIR`, so a name like `../x.csv` (or an absolute path) escapes it.

PASS if the final reply identifies this defect: a path traversal in the exporter, where the file name is not confined to the export directory, in any wording.

FAIL if the reply does not mention it.
