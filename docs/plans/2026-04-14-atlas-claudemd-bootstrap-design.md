# ATLAS + CLAUDE.md Bootstrap — Design Doc

**Date:** 2026-04-14
**Target version:** turbocharge v2.4.0
**Status:** Design locked, ready for `/turbocharge:plan`

---

## Goal

Turn `ATLAS.md` into turbocharge's **core navigation index** (a fast lookup layer that saves tokens by being pre-loaded into context) and repair the `CLAUDE.md` bootstrap chain so first-run setup is coherent instead of a manual copy-paste dump.

Secondary: fold in file-based memory discipline patterns from ruflo/claude-mem (confidence metadata, 200-line cap, session snapshot) that don't require infrastructure.

---

## Principle — One Sentence

> **CLAUDE.md is rules. ATLAS.md is navigation. `.codemap/` is an optional extra.**

Three non-overlapping jobs, three files:

| File | Answers | Shape | Who writes it |
|------|---------|-------|---------------|
| `CLAUDE.md` | "How should Claude behave on this project?" | Rules, conventions, domain vocabulary | User + `/init` + `/turbocharge:setup` + `/wrap` corrections |
| `ATLAS.md` | "Where do I look to do X?" | Lookup tables — intent→file, module map, key symbols, entry points, integrations | `/turbocharge:atlas` |
| `.codemap/` (optional) | "Where is symbol `Foo` exactly?" | Auto-generated JSON symbol index | External `codemap` CLI |

ATLAS is **core** to turbocharge. Not a sibling of codemap, not a dependency — it's the navigation layer turbocharge owns and pre-loads on every session.

---

## Audit of Current State (2026-04-14)

### ATLAS claim in `CLAUDE.md:56` is mostly aspirational

| Location | Actual behavior | Verdict |
|----------|-----------------|---------|
| `hooks/session-start.sh:18-21` | Nudges if missing | ✅ Works |
| `skills/atlas/SKILL.md` | Generates/updates | ✅ Owns |
| `skills/plan/SKILL.md:28` | 1-line "read it if exists" | ⚠️ Skill instruction — but dispatches to `agents/planner.md` which has **zero** ATLAS references. Context drops on handoff. |
| `skills/wrap/SKILL.md:68` | Refresh nudge only | ⚠️ Doesn't read it |
| `skills/setup/SKILL.md:97-99` | Existence check only | ⚠️ Doesn't read it |
| `agents/{planner,researcher,builder,code-reviewer,spec-reviewer,quality-reviewer}.md` | — | ❌ Ignore |
| `skills/{brainstorm,story,build,review,debug,ship}/SKILL.md` | — | ❌ Ignore |

### CLAUDE.md bootstrap is a manual copy-paste

- `hooks/missing-claudemd-nudge.md` nudges `/init` and prints a 5-section list for the user to add manually
- `skills/setup/SKILL.md` audits agents/commands/rules but does **not** touch CLAUDE.md
- No template, no interview, no idempotency

---

## Design

### 1. ATLAS reshape — lookup-first format

Rewrite `skills/atlas/SKILL.md` so generated ATLAS.md follows this shape:

````markdown
# ATLAS — [Project Name]

Last updated: YYYY-MM-DD

## Where to Look (intent → file)

| I want to... | Open | Why |
|--------------|------|-----|
| Add a new skill | `skills/<name>/SKILL.md` + `.claude-plugin/marketplace.json` | SKILL.md defines; marketplace lists |
| Change the review chain | `skills/build/SKILL.md` | Orchestrates builder→spec→quality |
| Fix a failing hook | `hooks/hooks.json` → `hooks/<name>.sh` | Registration vs content |

## Entry Points

| File | Role | Starts |
|------|------|--------|

## Module Map

| Directory | One-line purpose | Key files |
|-----------|------------------|-----------|

## Key Symbols (20-30 most-referenced)

| Symbol | File:line-range | Kind |
|--------|-----------------|------|

## Integration Points

| System | Config key | Path |
|--------|------------|------|

## Conventions & Gotchas

- [Non-obvious trap that burned someone]

<!-- 📌-prefixed lines are manual notes, preserved across atlas updates -->
````

**Removed:** Data Flows (prose arrows), Domain Model table (→ CLAUDE.md), Active Work & Known Issues.

**Added:** `Where to Look` table (intent→file), `Key Symbols` table (Claude-authored, heuristic — not AST-exhaustive).

**Constraint:** every section is a table or bullet list. No prose paragraphs.

### 2. Hooks — strengthen one, delete one, keep one

| Hook | Change |
|------|--------|
| `SessionStart` → `hooks/session-start.sh` | **Strengthen.** After bootstrap cat, if `ATLAS.md` exists, cat its full contents into stdout so it lands in context from turn 1. Also cat `_session.json` snapshot if present (see §4). |
| `PreToolUse` on Read → `hooks/pretool-read-codemap.sh` | **Delete.** Redundant once ATLAS is in context from SessionStart. Codemap nudges are no longer core. Users who want codemap can add their own hook. |
| `Stop` → `stop-wrap-reminder.md` | **Keep unchanged.** |

Rationale: fast lookup = zero tool calls. Pre-loading ATLAS pays the token cost once per session; every subsequent "where is X" resolves in-context without a Read. A PreToolUse nudge fires on every Read and bloats context per-turn while only sometimes being useful.

### 3. ATLAS → subagent propagation (gap fix)

**Problem (websearch confirmed):** subagents do not inherit parent conversation history. `@ATLAS.md` in an agent's system-prompt file does not auto-read — the `@` resolves in the **dispatch prompt** passed by the parent.

**Fix:** update both layers:

- `agents/planner.md`, `agents/researcher.md`, `agents/code-reviewer.md` get an explicit instruction: *"If ATLAS.md exists, read it first before exploring the codebase."*
- `skills/plan/SKILL.md`, `skills/build/SKILL.md`, `skills/review/SKILL.md` get `@ATLAS.md` injected into their dispatch-prompt templates so the subagent receives it in context.

Builder, spec-reviewer, quality-reviewer do **not** need ATLAS — they read the spec and the diff. Not all agents need the navigation index.

### 4. CLAUDE.md bootstrap — coherent chain

Replace the manual-copy-paste dump with this chain:

```
[fresh project, no CLAUDE.md, no ATLAS.md]
       │
       ▼
SessionStart hook: nudges "/init then /turbocharge:setup"
       │
       ▼
User runs /init  (Claude Code native)
  → baseline CLAUDE.md (identity, stack, structure)
       │
       ▼
User runs /turbocharge:setup
  • existing audit phase (~/.claude/agents/, commands/, rules/)
  • NEW: CLAUDE.md phase
    - auto-detect language, test framework, test command, package manager
    - ask ≤5 multiple-choice questions (TDD strictness, file-header style,
      naming style, debug strictness, domain terms)
    - append HTML-comment-delimited turbocharge blocks
    - show diff, confirm, write
    - size guard: warn if CLAUDE.md > 180 lines, suggest extracting
      personal rules to ~/.claude/CLAUDE.md
  • chains forward → /turbocharge:atlas
       │
       ▼
User runs /turbocharge:atlas
  → reads CLAUDE.md (avoid dup) + codebase → writes ATLAS.md
       │
       ▼
Next session: SessionStart cats ATLAS.md → zero-tool-call lookups
```

### 5. Setup interview — hybrid (auto-detect + ask)

**Auto-detect (no question):**
- Language + test framework from `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod`
- Test command from `package.json:scripts.test` or pytest config
- Package manager from lockfile
- Primary entry point

**Ask (hard cap 5, multiple choice, each skippable):**
1. Test discipline: Strict TDD / Tests-alongside / Tests-when-reasonable
2. File-header convention: ABOUTME / JSDoc-style / None
3. Naming style: camelCase / snake_case / mixed-by-language
4. Debug protocol strictness: Always 4-phase / Non-trivial only
5. Project-specific domain terms (free text)

**Write shape** — HTML-comment-delimited blocks for idempotent updates:

```markdown
<!-- turbocharge:tdd -->
## TDD Workflow
Strict TDD — every task starts on a failing test. Test command: `pnpm test`.
<!-- /turbocharge:tdd -->
```

Re-running `/turbocharge:setup` updates blocks in-place. User edits outside markers are never touched.

### 6. Memory discipline — option B from brainstorm

Fold ruflo-inspired file-and-markdown patterns into `/wrap`:

**#1 — Confidence + source metadata on bullets**
Format: `- Summary _(source, YYYY-MM-DD, conf: 0.8)_`
Applied to entries `/wrap` writes to `~/.claude/projects/<project>/memory/*.md`.

**#2 — 200-line cap on `MEMORY.md` + prune-before-build**
`/wrap` trims oldest + lowest-confidence entries first. Matches "CLAUDE.md under 200 lines" guidance from 2026 best practices.

**#3 — Session snapshot JSON**
`/wrap` persists `~/.claude/projects/<project>/memory/_session.json`:
```json
{
  "date": "2026-04-14",
  "branch": "master",
  "current_task": "ATLAS reshape design",
  "blockers": [],
  "next_steps": ["Chain to /turbocharge:plan", "Break into tasks"],
  "open_files": ["skills/atlas/SKILL.md"]
}
```
SessionStart hook cats this after ATLAS for zero-tool-call resume.

**Skipped:**
- Dedup via content hash (#4) — marginal at plugin scale, revisit v2.5
- Fixed topic categories (#5) — current semantic naming works
- Vector / HNSW / neural ranking — wrong scale for a solo-dev plugin

### 7. Validation script

Ship `scripts/validate-atlas.sh`:
```bash
# Checks ATLAS.md has required headers: Where to Look, Entry Points,
# Module Map, Key Symbols, Integration Points
```
Runs as part of `scripts/validate.sh` plugin-health check.

### 8. Demote the ATLAS claim in `CLAUDE.md`

Current `CLAUDE.md:56` claim: *"Read by setup, wrap, plan skills; nudged by SessionStart hook when absent."*

Replace with accurate post-v2.4 claim:
> *Pre-loaded into context by the SessionStart hook when present; injected into dispatch prompts for planner, researcher, and code-reviewer agents; nudged by SessionStart when absent.*

---

## File Impact

### New files
- `templates/CLAUDE-turbocharge.md` — default values for interview `[skip]` branches
- `scripts/validate-atlas.sh` — format validation

### Modified files
- `hooks/session-start.sh` — cat ATLAS.md + `_session.json` when present
- `hooks/missing-claudemd-nudge.md` — tighten to 2-line chain nudge
- `hooks/missing-atlasmd-nudge.md` — tighten; note pre-loading behavior
- `hooks/hooks.json` — remove PreToolUse entry
- `skills/atlas/SKILL.md` — new lookup-first format
- `skills/setup/SKILL.md` — add CLAUDE.md phase (detect + interview + append)
- `skills/wrap/SKILL.md` — bullet metadata, 200-line cap, snapshot JSON
- `skills/plan/SKILL.md` — inject `@ATLAS.md` in dispatch prompt
- `skills/build/SKILL.md` — inject `@ATLAS.md` in dispatch prompt
- `skills/review/SKILL.md` — inject `@ATLAS.md` in dispatch prompt
- `agents/planner.md` — explicit "read ATLAS first" instruction
- `agents/researcher.md` — explicit "read ATLAS first" instruction
- `agents/code-reviewer.md` — explicit "read ATLAS first" instruction
- `scripts/validate.sh` — call validate-atlas.sh
- `CLAUDE.md` — demote ATLAS claim at line 56 to accurate shape
- `CHANGELOG.md` — v2.4.0 entry

### Deleted files
- `hooks/pretool-read-codemap.sh` — redundant once ATLAS is pre-loaded

---

## Non-goals

- No auto-generation of `.codemap/`-style symbol JSON (that's codemap's job)
- No new skills
- No AgentDB / HNSW / vector-store / neural ranking
- No Tree-sitter AST integration (future: optional enrichment for Key Symbols, v2.5+)
- No 3-layer memory split (team vs personal) — scope creep, v2.5+
- No PreCompact hook — cross that bridge if lookups start failing after compaction in practice

---

## Open risks

1. **ATLAS token budget** — a well-formatted ATLAS is 500–2000 tokens. On small projects that's fine; on monorepos it may push past 5000. Mitigation: Key Symbols capped at 30, Module Map capped at top-level directories only. Revisit if users complain.
2. **Claude-authored Key Symbols drift** — heuristic, not AST-derived. Will miss symbols or include stale ones. Mitigation: `/wrap` nudges `/turbocharge:atlas` refresh when structural changes detected. Long term: optional Tree-sitter enrichment.
3. **Setup interview fatigue** — 5 questions might still be too many. Mitigation: each has `[skip / use default]`, full interview completable in <90 seconds.
4. **CLAUDE.md merge conflicts** — if user hand-edits inside turbocharge-delimited blocks, next setup run overwrites. Mitigation: document the marker contract; setup shows diff + confirms before write.

---

## Sources consulted (2026-04-14 websearch)

- [Best Practices for Claude Code](https://code.claude.com/docs/en/best-practices)
- [Claude Memory Guide — 3-Layer Architecture (2026)](https://www.shareuhack.com/en/posts/claude-memory-feature-guide-2026)
- [Writing a good CLAUDE.md — HumanLayer](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Claude Code Session Hooks — Auto-Load Context](https://claudefa.st/blog/tools/hooks/session-lifecycle-hooks)
- [Create custom subagents — Claude Code Docs](https://code.claude.com/docs/en/sub-agents)
- [Scoped Context Passing for Subagents — anthropics/claude-code#4908](https://github.com/anthropics/claude-code/issues/4908)
- [Aider — Repository map](https://aider.chat/docs/repomap.html)
- [Code Maps — Blueprint Your Codebase for LLMs](https://origo.prose.sh/code-maps)
- [LocAgent — Graph-Guided LLM Agents for Code Localization](https://arxiv.org/pdf/2503.09089)

Prior art from local clones: `ruflo/v3/@claude-flow/memory/` (AutoMemoryBridge pattern) — only file-and-markdown patterns adopted, all infrastructure (AgentDB, HNSW, neural ranking) explicitly skipped.

---

## Next step

Chain to `/turbocharge:plan docs/plans/2026-04-14-atlas-claudemd-bootstrap-design.md` for task breakdown.
