---
name: atlas
description: Generate or update a semantic domain map (ATLAS.md) for the project. Maps entry points, data flows, domain model, module purposes, and integration points. Complements codemap's structural index with the domain knowledge layer.
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
````

**Constraint:** every section above is a table or bullet list. No prose paragraphs.

**Removed from prior format:** Data Flows (prose arrows), Domain Model (→ CLAUDE.md), Active Work & Known Issues.
**Added:** Where to Look (intent→file), Key Symbols (heuristic).

## What NOT to Include

ATLAS.md contains **facts about the project**. Do not include:
- Rules or instructions for Claude → CLAUDE.md
- Symbol-level indexes (classes, functions, line ranges) → codemap
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
