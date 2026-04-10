# Atlas Skill Implementation Plan

**Goal:** Add `/turbocharge:atlas` skill that generates semantic domain maps (ATLAS.md) complementing codemap's structural index.
**Architecture:** Single SKILL.md prompt template (no new agents). Pipeline integration via minimal edits to 4 existing files. Standard plugin release process.
**Tech Stack:** Markdown (SKILL.md), Bash (validate.sh)

**Stories:** [2026-04-09-atlas-skill-stories.md](2026-04-09-atlas-skill-stories.md)
**Tasks:** 4 tasks, ~15 minutes total

---

### Task 1: Update validate.sh to expect atlas skill

**Files:**
- Modify: `scripts/validate.sh`

**Step 1: Write the failing test**

In `scripts/validate.sh`, change the expected skills list (line 49):

```bash
# Before:
EXPECTED_SKILLS="brainstorm build debug plan review setup ship story wrap"

# After:
EXPECTED_SKILLS="atlas brainstorm build debug plan review setup ship story wrap"
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/validate.sh`
Expected: FAIL with `skills/atlas/SKILL.md — not found`

**Step 3: Proceed to Task 2 (skill creation makes this pass)**

---

### Task 2: Create atlas skill definition

**Files:**
- Create: `skills/atlas/SKILL.md`

**Step 1: Create the skill file**

Create `skills/atlas/SKILL.md` with the following content:

```markdown
---
name: atlas
description: Generate or update a semantic domain map (ATLAS.md) for the project. Maps entry points, data flows, domain model, module purposes, and integration points. Complements codemap's structural index with the domain knowledge layer.
---

# Atlas — Project Domain Map

Generate or update the semantic domain map for this project.

**Announce:** "Using atlas to map this project's domain."

## The Iron Law

` ` `
NO ATLAS WITHOUT READING THE CODEBASE FIRST
` ` `

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

` ` `markdown
# ATLAS — [Project Name]

Last updated: YYYY-MM-DD

## Project Identity

| Attribute | Value |
|-----------|-------|
| Description | One-line what this project does |
| Language | Primary language(s) |
| Framework | Primary framework(s) |
| Repo | Monorepo / single-service / library |

## Entry Points

| Entry | File | Type | Purpose |
|-------|------|------|---------|
| Main | `path/to/main.py` | CLI / API / Job | What it starts |

## Domain Model

| Entity | Definition | Key Relationships |
|--------|-----------|-------------------|
| EntityName | What it represents | → Related, → Other |

## Data Flows

### [Flow Name]
` ` `
source → step1 (what happens) → step2 (what happens) → destination
` ` `

### [Another Flow]
` ` `
trigger → process → output
` ` `

## Module Directory

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| `src/module/` | What this module does | `important.py`, `other.py` |

## Integration Points

| System | Type | Config | Purpose |
|--------|------|--------|---------|
| ServiceName | API / DB / Queue / Blob | `ENV_VAR` or config path | What it's used for |

## Conventions & Gotchas

- [Non-obvious pattern, naming convention, or trap that isn't in CLAUDE.md]
- [Things that look wrong but are intentional]
- [Gotcha that has burned people before]

## Active Work & Known Issues

- [Current pain point or in-progress migration]
- [Tech debt item with context on why it exists]
` ` `

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

` ` `
setup → atlas (recommended after first setup)
[any point] → atlas → [resume work]
wrap → atlas (suggested if major changes were made)
` ` `
```

**Step 2: Run validate.sh to verify it passes**
Run: `bash scripts/validate.sh`
Expected: PASS — 0 errors (atlas skill found with name and description)

**Step 3: Commit**
`git commit -m "feat: add atlas skill for semantic domain mapping"`

---

### Task 3: Pipeline integration

**Files:**
- Modify: `hooks/session-bootstrap.md`
- Modify: `skills/plan/SKILL.md`
- Modify: `skills/wrap/SKILL.md`
- Modify: `skills/setup/SKILL.md`

**Step 1: Update session-bootstrap.md**

Add one row to the skill table (after the setup row):

```markdown
| Generate or update the project domain map | `/turbocharge:atlas` |
```

**Step 2: Update plan skill**

In `skills/plan/SKILL.md`, add after the "Plan Document Header" section and before "Task Structure":

```markdown
## Context Gathering

Before planning, check for domain context:
- If `ATLAS.md` exists in the project root, read it for domain model, entry points, and module purposes
- If `CLAUDE.md` exists, read it for conventions and rules
- These inform task design — use correct entity names, file paths, and architectural patterns
```

**Step 3: Update wrap skill**

In `skills/wrap/SKILL.md`, add to the "What to Capture" section after "### 5. Resume Prompt" and before "### 6. Encode Session Learnings":

```markdown
### 5.5. Atlas Freshness
If ATLAS.md exists and significant structural changes were made this session (new modules, changed entry points, new integrations), note in the resume prompt:
- "Consider running `/turbocharge:atlas` to update the domain map"
```

**Step 4: Update setup skill**

In `skills/setup/SKILL.md`, add a new section after "### 6. Check Global Rules Alignment" and before "## Report Format":

```markdown
### 7. Check for Project Atlas

Check if `ATLAS.md` exists in the project root:
- **Exists:** pass "ATLAS.md found — domain map available"
- **Missing:** suggest "No ATLAS.md found — run `/turbocharge:atlas` to generate a domain map for faster context gathering"
```

**Step 5: Verify**
Run: `bash scripts/validate.sh`
Expected: PASS — 0 errors

**Step 6: Commit**
`git commit -m "feat: integrate atlas into pipeline (bootstrap, plan, wrap, setup)"`

---

### Task 4: Plugin release housekeeping

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Step 1: Bump version in plugin.json**

```json
{
  "name": "turbocharge",
  "description": "Engineering team orchestration for Claude Code. 10 skills, 6 agents — single pipeline from brainstorm to shipped code.",
  "version": "2.2.0",
  ...
}
```

Changes: version `2.1.0` → `2.2.0`, description `9 skills` → `10 skills`

**Step 2: Update README.md**

Add atlas entry in the Skills section (after "### setup", before "### brainstorm"):

```markdown
### atlas
Generates a semantic domain map (ATLAS.md) of the project — entry points, data flows, domain model, module purposes, integration points. Complements codemap for structural indexing. Run after setup or whenever the codebase evolves significantly.
```

Update the pipeline diagram to show atlas as a utility:

```
brainstorm → story → plan → build → review → ship
                                  ↑               |
                                debug            wrap
                                  ↑
                                atlas (any point)
```

Update skill count: "## Skills (10)"

Update the Directory Structure section: note that atlas creates `ATLAS.md` in consumer projects.

**Step 3: Update CHANGELOG.md**

Add before the `[2.1.0]` entry:

```markdown
## [2.2.0] - 2026-04-09

New skill: semantic domain mapping.

### Added
- `atlas` skill — generates and maintains ATLAS.md, a semantic domain map covering entry points, data flows, domain model, module purposes, integration points, and conventions
- Pipeline integration: session-bootstrap lists atlas, plan skill reads ATLAS.md for context, wrap skill nudges atlas refresh, setup skill checks for ATLAS.md

### Changed
- Plugin description updated to "10 skills, 6 agents"
- README updated with atlas documentation and revised pipeline diagram
```

**Step 4: Final validation**
Run: `bash scripts/validate.sh`
Expected: PASS — 0 errors, 0 warnings (or existing warnings only)

**Step 5: Commit**
`git commit -m "chore: bump to v2.2.0, update README and CHANGELOG for atlas skill"`
