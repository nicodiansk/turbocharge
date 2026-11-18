# CLAUDE.md

## Project Context

**Turbocharge: Claude Code Plugin Blueprint**

A Claude Code plugin that replaces ad-hoc agents, scattered skills, and custom commands with a single opinionated engineering pipeline. Also serves as a reference implementation for building Claude Code plugins.

### What This Project Is

This is a **plugin** for Claude Code — not a standalone app. It consists of:
- 10 skills (SKILL.md files that define slash commands)
- 6 agents (markdown agent definitions dispatched by skills)
- 1 workflow (`workflows/review-swarm.js`, launched by `/turbocharge:review` when the user opts in). The directory copy leaves it out (Publishing Flow step 5)
- 3 hooks (SessionStart bootstrap + ATLAS pre-load; builder exit gate on SubagentStop and PreToolUse/SubagentHandback; git-guard on PreToolUse/Bash). Repo installs only: the directory copy ships no hooks since 3.5.8 (Publishing Flow step 5)
- A marketplace manifest for distribution

### Architecture

```
Plugin Structure:
  skills/         → SKILL.md files (user-invocable slash commands)
  agents/         → Agent definitions (dispatched by skills, not invocable directly)
  hooks/          → hooks.json + content files (lifecycle automation)
  workflows/      → workflow scripts (launched by skills)
  templates/      → CLAUDE-turbocharge.md, the blocks setup writes into user projects
  .claude-plugin/ → plugin.json manifest + icon.png (plugin icon)

Dev only (never shipped): scripts/ (validate, release, eval, tests/), evals/, examples/, images/.
docs/ is gitignored: it's the private repo nicodiansk/turbocharge-notes cloned in place
(plans in docs/plans/, handoff, Keep Up AI). Plans and notes are committed there, not here.
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
              published 2026-09-24). Managed at claude.ai/directory/manage; tracks the trimmed `release`
              branch since 3.4.1 (Publishing Flow step 5).
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
| **Hook** | Shell command executed at lifecycle events: SessionStart (bootstrap), and SubagentStop plus PreToolUse on `SubagentHandback` (builder exit gate, one script on two events), and PreToolUse on `Bash` (git-guard: refuses bulk staging, skipped git hooks, and a recursive delete through a symlink, plus on Windows shells one of a folder holding links; lets the rest through). The count is hook scripts, not hooks.json entries. Repo installs only: the directory copy ships no hooks since 3.5.8 |
| **Marketplace** | GitHub repo with `.claude-plugin/marketplace.json` that indexes plugins — lives at the root of this repo (`nicodiansk/turbocharge`) as of v2.3.0; previously a sibling `turbocharge-marketplace` repo (deleted 2026-04-13) |
| **Lane** | A group of plan tasks that owns a disjoint set of files (plan's `## Lanes` table, which merges chained builder lanes). `/turbocharge:build` runs each lane inline in the main session or with one builder (Sonnet, or Opus on lanes the plan marks), overlaps lanes with no `After` dependency, at most 3 builder lanes at once, commits by pathspec, checks each builder lane's files before marking it done, and runs the full suite once at the join |
| **Iron Law** | A rule a skill states up front, with its reason (build, review, debug, story, brainstorm, atlas). Only a hook enforces anything |
| **Red Flag** | Anti-rationalization table that catches Claude skipping process steps |
| **Review Focus** | A plan section listing up to 5 inputs or failure modes the spec implies but never names, each pinned by a test in the task that owns the code (`(pinned: Task N)`). Reviewers check the pins |
| **Eval case** | A directory under `evals/<family>/<case>/` (`prompt.md`, `case.yaml` + `fixture.sh`, `graders/*.md`) run by `claude plugin eval` through `scripts/eval.sh`, with and without the plugin. WITH / W/OUT / Δ per family land in `evals/summary/<version>.md` and README **Measured** |
| **Verifier** | Read-only Sonnet agent (`agents/verifier.md`) that tries to refute one review finding or PR comment. In reviews an uncertain verdict counts as refuted |
| **Review swarm** | Review's workflow (`workflows/review-swarm.js`): five lens reviewers, dedupe, a verifier per finding, a 25-agent cap. It runs only on the user's opt-in (typed `/turbocharge:review` or an explicit ask), because the Workflow tool requires one; otherwise review dispatches the single `code-reviewer`. Left out of the directory copy since 3.5.3, where review always runs one `code-reviewer` |
| **PR triage** | `ship` given a PR's review comments in a file or pasted: verifies each comment through the verifier, fixes valid ones and commits locally, drafts replies, never pushes or posts, never edits a nit. 3.5.0 removed `--watch` on a wrong guess about the directory's credential hold (the cause was a line in the debug skill, fixed in 3.5.7); watching a PR is Claude Code's `/autofix-pr` |
| **ATLAS.md** | Semantic domain map generated by `/turbocharge:atlas` in user projects (Where to Look, Entry Points, Module Map, Key Symbols, Integration Points, Conventions & Gotchas). **Where to Look table pre-loaded by SessionStart hook** (remaining sections available via Read on demand); **named in dispatch prompts** for planner, researcher, and code-reviewer agents (an `@` path there is not expanded, so each agent reads the files unless they are already in its context); nudged by SessionStart when absent; staleness from the commit in its `<!-- atlas-sha:<sha> -->` footer: SessionStart lists the lines whose cited files changed since (`git diff --name-only --no-renames`), and wrap reruns atlas only when files changed. Key Symbols are counted by `skills/atlas/atlas-symbols.sh` with no line numbers; `skills/atlas/validate-atlas.sh` gates an ATLAS.md commit and warns past 25 Where to Look rows of ~140 characters or 20 KB. The directory copy runs the same checks as git commands. No CodeMap since 3.8.0: it needed Python 3.10 and tree-sitter. The pre-load, the nudge and the staleness check are repo installs only: the directory copy has no hooks. This plugin repo intentionally does NOT ship one — CLAUDE.md + README cover the same ground for a plugin blueprint. |

---

## Development Conventions

### File Types

| File | Format | Purpose |
|------|--------|---------|
| `skills/<name>/SKILL.md` | Markdown with YAML frontmatter | Skill definition (prompt template) |
| `agents/<name>.md` | Plain markdown | Agent system prompt |
| `hooks/hooks.json` | JSON | Hook registration (lifecycle → command mapping) |
| `hooks/*.md` | Markdown | Hook content (injected into context) |
| `hooks/*.sh` | Bash | Hook scripts: `session-start.sh`, `builder-exit-gate.sh`, `git-guard.sh` (read-only; disclosed in README "What the hooks do"). Repo installs only: the directory copy ships no hooks since 3.5.8 |
| `skills/<name>/*.sh` | Bash | Skill scripts (`atlas-symbols.sh`, `validate-atlas.sh`, `write-snapshot.sh`), run as `bash "${CLAUDE_PLUGIN_ROOT}/skills/<name>/<script>"`. Repo installs only (`DIRECTORY_DROP`): skill text names them only inside repo-only blocks |
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
Opus appears in two places, both as `model: opus` on build's Agent call: a builder
lane the plan marks `opus · <reason>` (`concurrency`, `security`, `irreversible`
or `edge-cases`), and the one retry of a stuck Sonnet lane. A stuck Opus lane goes
to the user, with no retry. Design or destructive questions go to the user, never
to an Opus retry.

### Release Naming

Name releases by what they **do**, not after the source of inspiration. Never put
competitor/plugin codenames (e.g. another plugin's brand) in commit messages,
branch names, CHANGELOG entries, or PR titles/bodies. Continue the project's own
lineage instead (e.g. "Lean Builder v3" → "Lean review pipeline"). Two exceptions:
the pre-existing `setup` skill's conflict-detection list, which names competing
plugins functionally to warn about conflicts, and `NOTICE`, which must name the
project whose license it carries.

### Third-Party Material

Text or code copied or adapted from another project keeps that project's license
notice. `NOTICE` (shipped in both copies) holds the MIT notice for the parts of
`debug`, `ship` and `plan` adapted from another plugin, and lists each file; add a
file there when you copy or adapt more. Guarded by `t_notice.sh`.

### Versioning

- Version lives only in `.claude-plugin/plugin.json`; `marketplace.json` carries none (plugin.json wins over the marketplace entry, and the docs say to set it in one place). Guarded by `t_version_lockstep.sh`
- Bump it every release — the claude.ai directory expects a new version for each update
- Use semver: patch for fixes, minor for new skills/features, major for breaking changes

### Testing Locally

```bash
# Load plugin from local directory
claude --plugin-dir .

# Full gate, what CI runs: structure, `claude plugin validate --strict`, every scripts/tests/t_*.sh
bash scripts/validate.sh

# Content-shape tests only, or a single one (it needs PLUGIN_DIR)
bash scripts/tests/run.sh
PLUGIN_DIR=$PWD bash scripts/tests/t_release_flow_docs.sh

# Behavioral evals (WSL2, Linux or macOS): WITH / W/OUT / Δ per family. Runs use the logged-in
# account: on a Max/Pro login they draw plan usage, not API billing. <max-cost-usd> caps the
# CLI's list-price estimate, i.e. how much usage a run may take
scripts/eval.sh <max-cost-usd> [--runs 1]
```

- Run repo scripts with `bash`: they're mode 644 (`core.filemode` is off), so `./scripts/…` exits 126.
- Tests grep exact phrases in this file, the README, skills and agents (`t_claudemd_*.sh`, `t_release_flow_docs.sh`, …): run the suite after any doc edit; when a pinned phrase is outdated, change the test with the doc.
- Tests use bash, grep, awk, sed and jq only (no python3: the Windows host has none) and must pass on macOS's BSD tools and bash 3.2 (CI matrix). node only for the review workflow's logic, skipped when missing. `assert_jq` skips silently without jq.
- A check that reads frontmatter or rule lines (in tests, skills or scripts) strips `\r` first: many user rule files are CRLF, and a naive check reads `---\r` and reports a `paths:` missing that is there. An edit keeps the file's line endings (ruled 2026-11-17 by user)

On macOS, cases that use git need a wrapper first on `PATH`: the eval sandbox denies `stat` on the real git
binaries, so bare `git` falls to the broken `/usr/bin/git` stub (dogfood D15). Exec by full path still works:

```bash
mkdir -p ~/.cache/tc-eval-git
printf '#!/bin/sh\nexec /opt/homebrew/bin/git "$@"\n' > ~/.cache/tc-eval-git/git && chmod +x ~/.cache/tc-eval-git/git
PATH="$HOME/.cache/tc-eval-git:$PATH" scripts/eval.sh <max-cost-usd>
```

### Publishing Flow

Single-repo as of v2.3.0. No cross-repo sync.

1. Evals are off since 2026-11-06 (the user's ruling: too heavy); run them only when the user asks. Then: `TC_EVAL_LABEL=<version> scripts/eval.sh <cap>` (WSL2, Linux, or macOS with the git wrapper), commit `evals/summary/<version>.md`, and refresh README **Measured** from it. Otherwise the CHANGELOG entry says they weren't rerun and README **Measured** keeps naming the version it measured (3.4.0)
2. Bump `version` in `.claude-plugin/plugin.json` (the only place it lives)
3. Update `CHANGELOG.md` with the new entry
4. Commit + push to `nicodiansk/turbocharge`. Users pick it up via `claude plugin update turbocharge@turbocharge`.
5. Directory: the listing tracks a **`release`** branch, so merges to `master` don't create directory versions. The rest of this step (`release.sh`, what the directory copy leaves out, the scan rules met so far, the frontmatter it accepts) is in `.claude/rules/directory-release.md`, which loads when Claude reads `scripts/release.sh`, `scripts/directory-filter.sh`, their tests, `CHANGELOG.md` or `.claude-plugin/plugin.json`. It drops out after `/compact` until one of them is read again.
   - Claude can't push `release`: auto mode blocks it as a production deploy. Run `release.sh` without `--push` and hand the user `! git -C <absolute repo path> push origin <sha>:refs/heads/release` (the session's cwd may be `docs/`, the notes repo).
   - Don't push `release` while a publish request waits, unless shipped files changed that the directory must get: each push holds the waiting version's request and restarts the reviewer wait (3.5.11's at 3.6.0, 3.6.0's at 3.7.0) (ruled 2026-11-17 by user)
