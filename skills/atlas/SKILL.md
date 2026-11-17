---
name: atlas
description: Generate or update a semantic domain map (ATLAS.md) for the project. Maps where to look, entry points, module purposes, key symbols, and integration points. Counts Key Symbols from the code and records the commit it maps.
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
2. Read CLAUDE.md (`./CLAUDE.md` or `./.claude/CLAUDE.md`) if it exists — understand what's already documented (don't duplicate it)
3. Read entry points (main files, CLI entry, API routers, job schedulers)
4. Read domain models (data classes, schemas, database models)
5. Scan integration configs (env files, connection strings, external service clients)

### Step 2b: Count Key Symbols

Find the definitions with `git grep -nE` (one pattern per language: `def`, `class`, `function`, `func`, `fn`, `struct`, `interface`), then rank them by `git grep -cw <name>`: the 20-30 most cited become Key Symbols, each with its count.
<!-- repo-only -->
`bash "${CLAUDE_PLUGIN_ROOT}/skills/atlas/atlas-symbols.sh" top 30` does this in one pass (Python through ast when python3 is there).
<!-- /repo-only -->

The semantic layer stays manual: **Where to Look** (intent→file), **Entry Points**, **Integration Points**, **Conventions & Gotchas**.

## Step 3: Generate or Update

### Generate Mode (no ATLAS.md)

Create `ATLAS.md` in the project root following the format in Step 4.

### Update Mode (ATLAS.md exists)

1. Read existing ATLAS.md
2. Compare each section against current codebase state
3. Update stale sections — preserve any manually-added notes (lines starting with `📌`)
4. Update the `Last updated` date
5. Run `` `git diff --name-only --no-renames <atlas-sha> HEAD` `` (the commit in the footer) and recheck the rows citing those files
6. Report what changed: "Updated: Module Directory (2 new modules), Integration Points (added Redis)"

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

## Key Flows

- [Flow name]: `entry` → `path/to/file` → `path/to/other`

## Module Map

| Directory | One-line purpose | Key files |
|-----------|------------------|-----------|
| `src/module/` | What this module does | `src/module/important.ext`, `src/module/other.ext` |

## Key Symbols

(20-30 most-cited, counted from the code. Name and file only: line numbers go stale.)

| Symbol | File | Kind | Refs |
|--------|------|------|------|
| `SymbolName` | `path/to/file` | class / function / const | 12 |

## Integration Points

| System | Config key | Path |
|--------|------------|------|
| ServiceName | `ENV_VAR` | `path/to/client` |

## Conventions & Gotchas

- [Non-obvious trap that burned someone]
- [Intentional-looking-wrong pattern]

<!-- 📌-prefixed lines are manual notes, preserved across atlas updates -->
<!-- atlas-sha:<commit> -->
````

**Constraint:** every section above is a table or bullet list. No prose paragraphs. Every path in backticks is repo-relative. Key Flows is optional: 3-5 bullets, `` - <flow>: `entry` → `file` → `file` ``.

**Removed from prior format:** Data Flows (prose arrows), Domain Model (→ CLAUDE.md), Active Work & Known Issues.
**Added:** Where to Look (intent→file), Key Symbols (counted).

## Step 5: Record the Commit

After writing ATLAS.md, make the last line `<!-- atlas-sha:<commit> -->` with `git rev-parse HEAD`, replacing any atlas-sha or atlas-hash line. Outside a git repository, write no footer.

Update mode and wrap diff from that commit to find what changed, so rerun `/turbocharge:atlas` when files the map cites change.
<!-- repo-only -->
SessionStart lists the lines at risk.
<!-- /repo-only -->

## What NOT to Include

ATLAS.md contains **facts about the project**. Do not include:
- Rules or instructions for Claude → CLAUDE.md
- Exhaustive symbol indexes (every class/function) → Key Symbols is a counted top-30, not a full index
- Full code snippets → reference by `file:line` path
- Who calls whom → ask at the time with `` `git grep -nw <name>` ``, or a code intelligence (LSP) plugin when one is installed
<!-- repo-only -->
  (`bash "${CLAUDE_PLUGIN_ROOT}/skills/atlas/atlas-symbols.sh" where <name>` lists the definition and its callers by file)
<!-- /repo-only -->
- Git history → `git log`
- Dependency version lists → `package.json` / `requirements.txt`

## After Generation

1. Show the user a summary of what was mapped (section counts)
2. Commit ATLAS.md only when every check passes: cited paths exist, each Key Symbol is still in its file, Key Flows has 5 or fewer, the footer commit exists.
<!-- repo-only -->
   `bash "${CLAUDE_PLUGIN_ROOT}/skills/atlas/validate-atlas.sh" ATLAS.md` runs the checks: commit on exit 0; on failure fix the lines it names and rerun, never commit a failing one.
<!-- /repo-only -->
3. Commit ATLAS.md by itself, so the next staleness check sees no unrelated change
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
| Line numbers in Key Symbols | They go stale: name and file only |

## Workflow Position

```
setup → atlas (recommended after first setup)
[any point] → atlas → [resume work]
wrap → atlas (suggested if major changes were made)
```
