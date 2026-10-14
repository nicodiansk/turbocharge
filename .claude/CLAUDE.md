# CLAUDE.md

## Project Context

**Turbocharge: Claude Code Plugin Blueprint**

A Claude Code plugin that replaces ad-hoc agents, scattered skills, and custom commands with a single opinionated engineering pipeline. Also serves as a reference implementation for building Claude Code plugins.

### What This Project Is

This is a **plugin** for Claude Code — not a standalone app. It consists of:
- 10 skills (SKILL.md files that define slash commands)
- 6 agents (markdown agent definitions dispatched by skills)
- 1 workflow (`workflows/review-swarm.js`, launched by `/turbocharge:review` when the user opts in)
- 2 hooks (SessionStart bootstrap + ATLAS pre-load; builder exit gate on SubagentStop and PreToolUse/SubagentHandback)
- A marketplace manifest for distribution

### Architecture

```
Plugin Structure:
  skills/         → SKILL.md files (user-invocable slash commands)
  agents/         → Agent definitions (dispatched by skills, not invocable directly)
  hooks/          → hooks.json + content files (lifecycle automation)
  workflows/      → workflow scripts (launched by skills)
  .claude-plugin/ → plugin.json manifest + icon.png (plugin icon)
```

### The Pipeline

```
brainstorm → story → plan → build → review → ship
                                  |               |
                                debug            wrap
```

### Distribution

```
Source repo:  nicodiansk/turbocharge (this repo — single source of truth)
Install:      claude plugin marketplace add nicodiansk/turbocharge
              claude plugin install turbocharge@turbocharge
Update:       claude plugin update turbocharge@turbocharge
Local dev:    claude --plugin-dir /path/to/turbocharge
Directory:    claude.ai plugin directory listing "Turbocharge" (ours; submitted 2026-06-23,
              published 2026-09-24). Managed at claude.ai/directory/manage; tracks `master` until the
              switch to `release` (Publishing Flow step 5).
              Each new version is scanned, then needs "Publish update" (a reviewer makes it live).
              Install id: turbocharge-nicodiansk@anthropic-plugin-directory (Claude Code's
              built-in marketplace; check the live version with `claude plugin list --available --json`)
```

**Name history:** 3.0.0 renamed the plugin to `turboflow` because another author's plugin named
`turbocharge` is listed in the directory (`turbocharge-aguerlain-lr`). What 3.0.0 missed: our own listing
already existed, and the directory tells same-named plugins apart by appending the publisher
(`turbocharge-nicodiansk`). 3.2.0 restored `turbocharge` so the listing's users keep `/turbocharge:`. Never
start a new directory submission. Never rename the plugin `name`: it sets every user's command namespace.

### Domain Terms

| Term | Definition |
|------|------------|
| **Skill** | A SKILL.md file in `skills/<name>/` — becomes `/turbocharge:<name>` |
| **Agent** | A markdown file in `agents/` — dispatched by skills via the Agent tool |
| **Hook** | Shell command executed at lifecycle events: SessionStart (bootstrap), and SubagentStop plus PreToolUse on `SubagentHandback` (builder exit gate, one script on two events) |
| **Marketplace** | GitHub repo with `.claude-plugin/marketplace.json` that indexes plugins — lives at the root of this repo (`nicodiansk/turbocharge`) as of v2.3.0; previously a sibling `turbocharge-marketplace` repo (deleted 2026-04-13) |
| **Lane** | A group of plan tasks that owns a disjoint set of files (plan's `## Lanes` table). `/turbocharge:build` runs each lane inline in the main session or with one Sonnet builder, overlaps lanes with no `After` dependency, commits by pathspec, and runs the full suite once at the join |
| **Iron Law** | An enforced constraint (not a suggestion) baked into skill definitions |
| **Red Flag** | Anti-rationalization table that catches Claude skipping process steps |
| **Review Focus** | A plan section listing up to 5 inputs or failure modes the spec implies but never names, each pinned by a test in the task that owns the code (`(pinned: Task N)`). Reviewers check the pins |
| **Eval case** | A directory under `evals/<family>/<case>/` (`prompt.md`, `case.yaml` + `fixture.sh`, `graders/*.md`) run by `claude plugin eval` through `scripts/eval.sh`, with and without the plugin. WITH / W/OUT / Δ per family land in `evals/summary/<version>.md` and README **Measured** |
| **Verifier** | Read-only Sonnet agent (`agents/verifier.md`) that tries to refute one review finding or PR comment. In reviews an uncertain verdict counts as refuted |
| **Review swarm** | Review's workflow (`workflows/review-swarm.js`): five lens reviewers, dedupe, a verifier per finding, a 25-agent cap. It runs only on the user's opt-in (typed `/turbocharge:review` or an explicit ask), because the Workflow tool requires one; otherwise review dispatches the single `code-reviewer` |
| **PR triage** | `ship --watch <PR#>` (or comments in a file or pasted): verifies each comment through the verifier, fixes valid ones, replies in threads after one OK, at most 2 fix rounds, never merges or force-pushes, never edits a nit |
| **ATLAS.md** | Semantic domain map generated by `/turbocharge:atlas` in user projects (Where to Look, Entry Points, Module Map, Key Symbols, Integration Points, Conventions & Gotchas). **Where to Look table pre-loaded by SessionStart hook** (remaining sections available via Read on demand); **injected into dispatch prompts** for planner, researcher, and code-reviewer agents; nudged by SessionStart when absent; staleness detected via `<!-- atlas-hash:XXXX -->` footer. This plugin repo intentionally does NOT ship one — CLAUDE.md + README cover the same ground for a plugin blueprint. |

---

## Development Conventions

### File Types

| File | Format | Purpose |
|------|--------|---------|
| `skills/<name>/SKILL.md` | Markdown with YAML frontmatter | Skill definition (prompt template) |
| `agents/<name>.md` | Plain markdown | Agent system prompt |
| `hooks/hooks.json` | JSON | Hook registration (lifecycle → command mapping) |
| `hooks/*.md` | Markdown | Hook content (injected into context) |
| `hooks/*.sh` | Bash | Hook scripts: `session-start.sh`, `builder-exit-gate.sh` (read-only; disclosed in README "What the hooks do") |
| `workflows/<name>.js` | Plain JS for the Claude Code workflow runtime | `export const meta` literal first; launched by a skill through the Workflow tool; tested by `t_review_swarm.sh` |
| `evals/<family>/<case>/` | Eval case (prompt.md, case.yaml, fixture.sh, graders/*.md) | Behavioral evals run by `scripts/eval.sh` under WSL2, Linux or macOS (native Windows has no sandbox for Bash-granted runs; macOS needs the git wrapper in Testing Locally) |
| `.claude-plugin/plugin.json` | JSON | Plugin manifest (name, version, author) |
| `.claude-plugin/icon.png` | Square PNG, 512–2048 px, < 2 MB | Plugin icon, guarded by `t_plugin_icon.sh`. The directory fixed its listing icon at first submission, so changing this file doesn't change the listing; ask Anthropic via the portal's Get help |

### Skill Anatomy

Every skill MUST have:
1. YAML frontmatter with `name`, `description`
2. Clear instructions Claude can follow without ambiguity
3. A "Red Flags" section for anti-rationalization (build, review, debug at minimum)
4. Chain-forward: suggest the next skill in the pipeline

### Agent Models

**Sonnet minimum, never Haiku.** Every agent (builders, reviewers, researchers,
planners) runs Sonnet or higher. Turn count beats token price: a cheaper model
that loops on misunderstandings costs more than one that gets it right the first
time. Do not set `model: haiku` on any agent.

The planner is the one deliberate `model: inherit`: it rides the orchestrator's
session model so architectural planning gets your strongest available model
(Opus when you orchestrate on Opus, Sonnet otherwise) — never below the Sonnet
floor in normal use, and portable to setups without Opus access. Every other
agent hard-pins `model: sonnet`, the verifier included, and the review swarm's lens
agents set `model: 'sonnet'` in the script.

No agent file pins Opus. Apart from the planner inheriting an Opus session,
Opus appears in one place: build retries a **stuck** builder lane once with
`model: opus` on the Agent call. Design or destructive questions go to the user,
never to an Opus retry.

### Release Naming

Name releases by what they **do**, not after the source of inspiration. Never put
competitor/plugin codenames (e.g. another plugin's brand) in commit messages,
branch names, CHANGELOG entries, or PR titles/bodies. Continue the project's own
lineage instead (e.g. "Lean Builder v3" → "Lean review pipeline"). The one allowed
exception is the pre-existing `setup` skill's conflict-detection list, which names
competing plugins functionally to warn about conflicts.

### Versioning

- Version lives only in `.claude-plugin/plugin.json`; `marketplace.json` carries none (plugin.json wins over the marketplace entry, and the docs say to set it in one place). Guarded by `t_version_lockstep.sh`
- Bump it every release — the claude.ai directory expects a new version for each update
- Use semver: patch for fixes, minor for new skills/features, major for breaking changes

### Testing Locally

```bash
# Load plugin from local directory
claude --plugin-dir .

# Validate plugin structure
./scripts/validate.sh

# Behavioral evals (WSL2, Linux or macOS): WITH / W/OUT / Δ per family. Runs use the logged-in
# account: on a Max/Pro login they draw plan usage, not API billing. <max-cost-usd> caps the
# CLI's list-price estimate, i.e. how much usage a run may take
scripts/eval.sh <max-cost-usd> [--runs 1]
```

On macOS, cases that use git need a wrapper first on `PATH`: the eval sandbox denies `stat` on the real git
binaries, so bare `git` falls to the broken `/usr/bin/git` stub (dogfood D15). Exec by full path still works:

```bash
mkdir -p ~/.cache/tc-eval-git
printf '#!/bin/sh\nexec /opt/homebrew/bin/git "$@"\n' > ~/.cache/tc-eval-git/git && chmod +x ~/.cache/tc-eval-git/git
PATH="$HOME/.cache/tc-eval-git:$PATH" scripts/eval.sh <max-cost-usd>
```

### Publishing Flow

Single-repo as of v2.3.0. No cross-repo sync.

1. Run the evals: `TC_EVAL_LABEL=<version> scripts/eval.sh <cap>` (WSL2, Linux, or macOS with the git wrapper), commit `evals/summary/<version>.md`, and refresh README **Measured** from it
2. Bump `version` in `.claude-plugin/plugin.json` (the only place it lives)
3. Update `CHANGELOG.md` with the new entry
4. Commit + push to `nicodiansk/turbocharge`. Users pick it up via `claude plugin update turbocharge@turbocharge`.
5. Directory: the listing tracks a **`release`** branch, so merges to `master` don't create directory versions.
   - **Switch pending:** until 3.2.0 is live it still tracks `master`. Switch it on the portal's Settings tab only after that, because changing the tracked branch cancels a waiting publish request. Merges to `master` don't wait for the switch: each push is scanned as a new version, and none goes live until you click **Publish update** (user ruling, 2026-10-13).
   - To send a release to the directory: `bash scripts/release.sh vX.Y.Z --push` (repo scripts are mode 644; `core.filemode` is off). It builds a trimmed commit from the tag's plugin files (`.claude-plugin/`, `agents/`, `hooks/`, `skills/`, `templates/`, `workflows/`, README, LICENSE, CHANGELOG) and fast-forwards `release` to it; dev files (this CLAUDE.md, `.github/`, `scripts/`, `evals/`, `images/`, `examples/`) never reach the directory, whose scan flags them. A new top-level path must be added to `SHIPPED` in `scripts/release.sh` or to `DEV_ONLY` in `t_release_tree.sh`. The webhook scans `release`, and once it passes you click **Publish update**.
   - Merges to `master` reach repo-marketplace installs (`turbocharge@turbocharge`) right away.
   - The live directory version shows in `claude plugin list --available --json` under `turbocharge-nicodiansk`.
