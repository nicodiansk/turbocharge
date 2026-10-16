---
name: atlas
description: Generate or update a semantic domain map (ATLAS.md) for the project. Maps where to look, entry points, module purposes, key symbols, and integration points. Complements codemap's structural index with the domain knowledge layer.
---

# Atlas — Project Domain Map

Generate or update the semantic domain map for this project.

**Announce:** "Using atlas to map this project's domain."

## The Iron Law

```
NO ATLAS WITHOUT READING THE CODEBASE FIRST
```

Do not generate from assumptions or memory. Read the actual code, configs, and docs.

## Step 1: Detect Mode

- If ATLAS.md does NOT exist in the project root → **Generate mode**
- If ATLAS.md exists → **Update mode**

## Step 2: Read the Codebase

Regardless of mode:
1. Read project structure (directory listing, key config files)
2. Read CLAUDE.md if it exists — understand what's already documented (don't duplicate it)
3. Read entry points (main files, CLI entry, API routers, job schedulers)
4. Read domain models (data classes, schemas, database models)
5. Scan integration configs (env files, connection strings, external service clients)

### Step 2b: Read Codemap Index (if available)

If `.codemap/.codemap.json` exists in the project root:

1. Read `.codemap/.codemap.json` — it contains a manifest with `directories` (list of indexed paths) and `stats` (total files, total symbols).
2. For each directory in the manifest, read `.codemap/<dir>/.codemap.json` — each contains `files` with symbol entries (name, type, lines, language).
3. Use this data to pre-populate:
   - **Module Map** — each directory with its file count and key files
   - **Key Symbols** — pick the 20-30 most important symbols (classes, exported functions) with their `file:line-range`
4. You still need to fill in the semantic layer manually: **Where to Look** (intent→file mapping), **Entry Points** (which files boot the app), **Integration Points** (external services), **Conventions & Gotchas**.

This shortcut reduces atlas generation from ~20 tool calls to ~5. If `.codemap/` does not exist, skip this step entirely — fall through to the standard codebase scan in Step 2.

## Step 3: Generate or Update

### Generate Mode (no ATLAS.md)

Create `ATLAS.md` in the project root following the format in Step 4.

### Update Mode (ATLAS.md exists)

1. Read existing ATLAS.md
2. Compare each section against current codebase state
3. Update stale sections — preserve any manually-added notes (lines starting with `📌`)
4. Update the `Last updated` date
5. Report what changed: "Updated: Module Directory (2 new modules), Integration Points (added Redis)"

## Step 4: ATLAS.md Format

````markdown
# ATLAS — [Project Name]

Last updated: YYYY-MM-DD

## Where to Look

| I want to... | Open | Why |
|--------------|------|-----|
| [Intent phrased as user goal] | `path/to/file` | One-line why this is the right file |

## Entry Points

| File | Role | Starts |
|------|------|--------|
| `path/to/main` | CLI / API / Job / Hook | What it boots |

## Module Map

| Directory | One-line purpose | Key files |
|-----------|------------------|-----------|
| `src/module/` | What this module does | `important.ext`, `other.ext` |

## Key Symbols

(20-30 most-referenced; heuristic, not AST-exhaustive.)

| Symbol | File:line-range | Kind |
|--------|-----------------|------|
| `SymbolName` | `path/to/file:10-42` | class / function / const |

## Integration Points

| System | Config key | Path |
|--------|------------|------|
| ServiceName | `ENV_VAR` | `path/to/client` |

## Conventions & Gotchas

- [Non-obvious trap that burned someone]
- [Intentional-looking-wrong pattern]

<!-- 📌-prefixed lines are manual notes, preserved across atlas updates -->
<!-- atlas-hash:XXXXXXXXXXXX -->
````

**Constraint:** every section above is a table or bullet list. No prose paragraphs.

**Removed from prior format:** Data Flows (prose arrows), Domain Model (→ CLAUDE.md), Active Work & Known Issues.
**Added:** Where to Look (intent→file), Key Symbols (heuristic).

## Step 5: Write Staleness Hash

After writing ATLAS.md, compute a directory-listing hash and append it as an HTML comment on the very last line:

```bash
HASH=$(ls -1 | grep -v -e '^\.codemap$' -e '^node_modules$' -e '^\.git$' -e '^__pycache__$' -e '^\.venv$' -e '^venv$' -e '^dist$' -e '^build$' | sort | md5sum | cut -c1-12)
echo "<!-- atlas-hash:$HASH -->" >> ATLAS.md
```

This hash is checked by the SessionStart hook to detect structural changes. If the user adds or removes top-level files/directories, the hash will mismatch and the hook will nudge a re-run.

## What NOT to Include

ATLAS.md contains **facts about the project**. Do not include:
- Rules or instructions for Claude → CLAUDE.md
- Exhaustive symbol indexes (every class/function) → codemap; Key Symbols is a curated top-30 heuristic, not a full AST dump
- Full code snippets → reference by `file:line` path
- Git history → `git log`
- Dependency version lists → `package.json` / `requirements.txt`

## After Generation

1. Show the user a summary of what was mapped (section counts)
2. Commit ATLAS.md
3. If codemap is not installed, mention: "Consider installing codemap for structural indexing alongside this domain map"
4. Offer to continue: "Ready to work? What's next?"

## Red Flags — STOP

| Flag | Problem |
|------|---------|
| Generating from memory or assumptions | Read the actual codebase first |
| Duplicating CLAUDE.md content | ATLAS = facts about project, CLAUDE.md = rules for Claude |
| Including code snippets | Reference paths, don't inline code |
| Skipping modules or directories | Cover the ENTIRE project structure |
| Writing prose paragraphs | Use tables, lists, flow arrows — structured data only |
| Not checking for existing ATLAS.md | Always detect mode first |

## Workflow Position

```
setup → atlas (recommended after first setup)
[any point] → atlas → [resume work]
wrap → atlas (suggested if major changes were made)
```
