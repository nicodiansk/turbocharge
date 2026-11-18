---
name: setup
description: Run once after installing turbocharge. Audits global config for conflicts — duplicate agents, competing skills, stale rules — and offers to fix them. Also validates turbocharge plugin health.
disable-model-invocation: true
---

# Setup Turbocharge

One-time audit and cleanup to make turbocharge your single orchestration system.

**Announce:** "Running turbocharge setup — auditing your config for conflicts."

## The Goal

Turbocharge replaces ad-hoc agents, scattered skills, and custom commands with one pipeline. This setup finds and removes the overlap so Claude doesn't get confused about which system to use.

## Audit Steps

### 1. Check for Competing Agents

Scan `~/.claude/agents/` for agent definitions that overlap with turbocharge agents:

| Turbocharge Agent | Conflicts With |
|-------------------|----------------|
| builder | tdd-guide, implementer |
| planner | planner, architect |
| code-reviewer | code-reviewer |
| researcher | explorer, investigator |
| task-reviewer | spec-reviewer, quality-reviewer |

Also check for: session-wrapper, session-wrap, build-error-resolver (covered by turbocharge:debug)

**Action:** List conflicts and offer to delete them. Explain what turbocharge agent replaces each one.

### 2. Check for Duplicate Skills/Commands

Scan `.claude/commands/` (project level) for commands that overlap with turbocharge skills:

| Turbocharge Skill | Conflicts With |
|-------------------|----------------|
| wrap | session-wrap, wrap-up, session-wrapper |
| story | story-author, user-story, story-writer |
| plan | task-breakdown, plan-tasks, task-planner |
| review | code-review |
| build | implement, implement-story |
| brainstorm | brainstorm (if non-turbocharge) |
| debug | debug, troubleshoot |

**Action:** List conflicts with file paths. Offer to delete duplicates. Flag any that have unique functionality turbocharge doesn't cover (recommend keeping those).

### 3. Check agents.md Rule

Read `~/.claude/rules/common/agents.md` (if exists):
- Does it reference turbocharge as the primary system? **Good.**
- Does it list phantom agents? An agent is phantom only when no source provides it: `~/.claude/agents/`, the project's `.claude/agents/`, or an enabled plugin's `agents/` (from `claude plugin list --json`). A plugin's agents, turbocharge's own included, are not phantom. **Phantom is bad — offer to rewrite.**
- Does it reference both turbocharge AND other agent systems? **Bad — offer to consolidate.**

**Action:** If agents.md doesn't point to turbocharge, offer to replace it with the turbocharge-aware version:
```markdown
# Agent Orchestration
## Primary System: Turbocharge Plugin
All orchestration goes through the turbocharge plugin...
```

When agents.md holds a table of turbocharge's agents, rebuild it with one row per `${CLAUDE_PLUGIN_ROOT}/agents/*.md`:
- its `name`, from the frontmatter, read with `\r` stripped;
- under "Dispatched by", the skills whose SKILL.md names `turbocharge:<name>`;
- its role, from the description's first sentence.
<!-- repo-only -->
- Also add one row per file in `${CLAUDE_PLUGIN_ROOT}/workflows/` (the review swarm, which review launches on the user's opt-in).
<!-- /repo-only -->

Show the diff and write only on a yes. Keep the file's line endings: a CRLF file stays CRLF.

### 4. Check for Plugin Conflicts

Run `claude plugin list --json` to enumerate installed plugins and their enable state:
- Are there disabled plugins cluttering the config? Offer to remove.
- Scan the installed-plugins list for competing **orchestration plugins** (e.g. superpowers, everything-claude-code) enabled alongside turbocharge — not just duplicate definitions in `~/.claude/agents/`. Warn about conflicts and explain the overlap.
- When no code intelligence (LSP) plugin is enabled in that list, say once that one gives exact callers and safe renames for refactoring while atlas finds them by name. It is optional and never required, and setup doesn't install it.

### 5. Validate Turbocharge Plugin Health

Run `claude plugin details turbocharge` to confirm the plugin is installed, enabled, and to see its standing context cost. Then check the installed copy under `${CLAUDE_PLUGIN_ROOT}`:
- All 10 skills have SKILL.md files
- All 6 agents have .md files
- .claude-plugin/plugin.json exists and its version matches `claude plugin details`
<!-- repo-only -->
- hooks/hooks.json exists
- workflows/review-swarm.js exists
<!-- /repo-only -->

### 6. Check Global Rules Alignment

Scan `~/.claude/rules/common/` for rules that conflict with turbocharge's iron laws:
- Testing rules should include "never ask permission to run tests"
- Development workflow should include "verify understanding before coding"
- Coding style should include a completion gate
- Reviews should require comprehensive scope by default

**Action:** List missing rules and offer to add them.

### 7. Check for Global Rules / Turbocharge Overlap

Scan `~/.claude/rules/common/` for files that duplicate what turbocharge skills already enforce:

| Global Rule File | Overlaps With | Recommendation |
|------------------|---------------|----------------|
| `agents.md` | turbocharge pipeline | Keep only the "Primary System: Turbocharge Plugin" header + pipeline table. Remove agent dispatch details — turbocharge skills handle dispatch. |
| `development-workflow.md` | turbocharge:plan, turbocharge:build | Remove TDD steps and plan-first sections — builder.md and planner.md enforce these. Keep only git workflow and research steps. |
| `testing.md` | builder.md TDD mandate | Remove TDD workflow section — builder.md is the single source. Keep coverage targets and test types. |

**Action:** For each overlap found, show the user what's duplicated and offer to trim. Don't delete files — trim the overlapping sections and keep unique content.

**Why this matters:** A rule file without `paths:` frontmatter loads at every session start, with the same priority as CLAUDE.md, and loads again after compaction; one with `paths:` loads when Claude reads a matching file. Instructions duplicated between rules and turbocharge skills cost context in every session and can give conflicting guidance.

### 8. Check Rule and Skill Files for Stale Lines

Scan every `~/.claude/rules/**/*.md` and every `~/.claude/skills/*/SKILL.md`, not only agents.md. Report each hit as `file:line`, a quote and the proposed fix, and edit only what the user picks.

1. **Not installed:** a name used as a skill (`/name`, `name skill`, `plugin:name`) or as an agent (`name agent`, `subagent_type`) that is none of these: a built-in command (`/init`, `/doctor`, `/config`), a skill in `~/.claude/skills/` or `.claude/skills/`, a command in `.claude/commands/`, an agent in `~/.claude/agents/` or `.claude/agents/`, or anything an enabled plugin ships. Examples: `python-testing`, `security-reviewer`, `build-error-resolver`.
2. **Retired model advice:** a model name with a version number (an older Opus, Sonnet or Haiku release) → suggest the alias (`opus`, `sonnet`, `haiku`) or no model at all. A thinking budget (`MAX_THINKING_TOKENS`, or a token count such as `31,999`) → current models always think, and depth follows the effort setting.
3. **Tools a session may lack:** `TodoWrite` (off by default since v2.1.268, and the Task tools that replace it aren't on by default on the newest models) and the Grep or Glob tools (absent by default on macOS, Linux and WSL) → reword to "the task tools, where the session has them" and "grep or find through Bash".
4. **Language rules without `paths:`:** a rule outside `common/` (for example `~/.claude/rules/python/`, `typescript/`) whose frontmatter has no `paths:` loads in every project. Propose `paths: ["**/*.py"]` for python, `paths: ["**/*.{ts,tsx,js,jsx}"]` for typescript, and the language's extensions for others. Before the user picks, state the trade-off: a `paths:` rule loads only when Claude reads, writes or edits a matching file, and after `/compact` it's gone until one is touched again.
5. **Conflicts with this project:** a user rule that contradicts the project's CLAUDE.md (for example "80% coverage, TDD always" against "no new unit tests") → suggest the rule add "unless the project's CLAUDE.md says otherwise".

Every check strips `\r` before it reads frontmatter or lines, because many rule files are CRLF and a naive read of `---\r` reports a `paths:` missing that is there. Every edit keeps the file's line endings: a CRLF file stays CRLF.

## CLAUDE.md Phase

Run this phase after the conflict audit completes and before the final report.

### 1. Auto-Detect (no questions)

Probe the project root for these files and extract values:

| Signal | Inspect | Extract |
|--------|---------|---------|
| `package.json` | `scripts.test`, `scripts.lint`, top-level `name` | test command, lint command, project name |
| `pyproject.toml` | `[tool.poetry]`, `[project]`, `[tool.pytest.ini_options]` | language (Python), test framework |
| `Cargo.toml` | `[package].name`, `[dev-dependencies]` | language (Rust), test runner |
| `go.mod` | `module` line | language (Go), module path |
| `pnpm-lock.yaml` / `yarn.lock` / `package-lock.json` | presence | package manager |
| Primary entry | `src/index.*`, `main.*`, `cmd/*/main.go` | entry-point file |

Do not ask the user about anything detectable.

### 2. Interview (≤5 questions, each skippable)

Ask at most these five, each with `[skip]` producing the template default:

1. **Test discipline** — Strict TDD / Tests-alongside / Tests-when-reasonable
2. **File-header convention** — ABOUTME / JSDoc-style / None
3. **Naming style** — camelCase / snake_case / mixed-by-language
4. **Debug protocol strictness** — Always 4-phase / Non-trivial only
5. **Project-specific domain terms** — free text; empty skips the block

The interview must be completable in under 90 seconds.

### 3. Render and Append

Read `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE-turbocharge.md`. Substitute answers (test command, naming style, file-header convention, domain terms). Each block is delimited by `<!-- turbocharge:NAME -->` and `<!-- /turbocharge:NAME -->`. Versions 3.0–3.1 wrote the same blocks under `<!-- turboflow:NAME -->` / `<!-- /turboflow:NAME -->`: treat those as the same block — replace it in place and rewrite its markers to `turbocharge`; never append a duplicate. If both a `turbocharge:NAME` and a `turboflow:NAME` block exist (3.x setup appended a copy), update the turbocharge block and remove the turboflow duplicate.

CLAUDE.md here means `./CLAUDE.md`, or `./.claude/CLAUDE.md` when the project keeps it there — edit the one that exists, never create a second. Imports resolve relative to the file that contains them, so inside `.claude/CLAUDE.md` the import is `@../AGENTS.md`: write that form wherever the bullets below say `@AGENTS.md`, and treat either form as the import already being present.

- If CLAUDE.md exists, `AGENTS.md` also exists, and CLAUDE.md has no `@AGENTS.md` line → offer to add `@AGENTS.md` as its first line. By default (the Project instructions setting in `/config`), Claude Code reads AGENTS.md only when no CLAUDE.md or CLAUDE.local.md exists, and before v2.1.277 it never reads AGENTS.md on its own, so without the import its instructions don't load; a user who set that option to `claude-md-and-agents-md` already loads both. Leave the file unchanged if the user declines.
- If CLAUDE.md exists and contains a block with the same marker → replace between markers, leave surrounding content untouched.
- If CLAUDE.md exists and does not contain that block → append to end of file.
- If CLAUDE.md does not exist but `AGENTS.md` does → create CLAUDE.md with `@AGENTS.md` as its first line, then append the rendered blocks below it. Under the default setting AGENTS.md stops loading once a CLAUDE.md exists, so this import is what keeps it loading.
- If neither CLAUDE.md nor AGENTS.md exists → suggest `/init` first, do not create a bare CLAUDE.md from the template alone.

### 4. Show Diff, Confirm, Write

Always show the diff and ask for confirmation before writing. Never modify CLAUDE.md silently.

### 5. Size Guard

After writing, if CLAUDE.md exceeds 180 lines, warn the user and suggest extracting personal rules to `~/.claude/CLAUDE.md`.

### 6. Chain Forward

If ATLAS.md does not exist, offer: `/turbocharge:atlas` to generate the navigation index. This closes the bootstrap loop: `/init → /turbocharge:setup → /turbocharge:atlas`.

## Report Format

```
TURBOCHARGE SETUP AUDIT
=======================

Plugin Health: ✅ OK (10 skills, 6 agents)

Conflicts Found:
  🔴 ~/.claude/agents/session-wrapper-agent.md → covered by turbocharge:wrap
  🔴 .claude/commands/story-author.md → covered by turbocharge:story
  🟡 agents.md references phantom agents, not turbocharge

Recommendations:
  1. Delete ~/.claude/agents/session-wrapper-agent.md
  2. Delete .claude/commands/story-author.md
  3. Rewrite agents.md to reference turbocharge

No Conflicts:
  ✅ .claude/commands/epic-author.md — unique, keep
  ✅ .claude/commands/consistency-review.md — unique, keep

Apply fixes? [list specific changes, ask for confirmation]
```

## After Setup

Offer to chain:
- `/turbocharge:brainstorm` if user has an idea to explore
- `/turbocharge:plan` if user has requirements ready
- `/doctor prompt-audit` (Claude Code v2.1.283 or later) checks instruction files for lines written for older models, references to things that don't exist, and contradictions. Worth rerunning after a model upgrade.
- Nothing if user just wanted the audit

## Red Flags

Do NOT:
- Delete files without listing them first and getting confirmation
- Modify CLAUDE.md without showing the diff
- Assume any file is "safe to delete" — always explain what replaces it
- Skip the audit steps to "save time"
