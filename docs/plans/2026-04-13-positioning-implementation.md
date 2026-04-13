# Positioning & README Rewrite v3 Implementation Plan

**Goal:** Replace the v2.3.0 README copy and ship the visual identity stack (logo, scene gifs, hero animation) so the pitch lands the (B) Discipline / (A) Calm / (C) Compounding register.

**Architecture:** Pure copy + asset pipeline, no plugin behavior changes. Three asset workstreams (VHS scene gifs, FLUX logo via mcp-hfspace, Remotion hero animation) run in parallel with three text workstreams (positioning copy, five scenes prose, with/without + what-you-get rewrite), then a final assembly pass stitches everything into `README.md`. All tooling is free and locked per the design doc.

**Tech Stack:** Charmbracelet VHS (scene gifs), `@llmindset/mcp-hfspace` + FLUX.1-Krea-dev (logo PNG), `vtracer` (PNG → SVG), Motion Canvas via `npm init @motion-canvas` (hero animation, MIT — swapped from Remotion 2026-04-13), GitHub-flavored Markdown (README).

---

## Source Doc

Full design: `docs/plans/2026-04-13-positioning-design.md`
Domain notes: `CLAUDE.md` (project conventions), `MEMORY.md` entry "positioning-unsettled".

## Conventions Applied

- README scaffold preserved from v2.3.0 — copy and asset slots only.
- All asset files under `images/` (existing dir) and `vhs/` (new dir).
- Remotion project under `motion/` (excluded from plugin distribution via `.gitignore` if heavy; keep source, ignore `node_modules`/`out/`).
- "Verification" for copy tasks = grep + visual diff in GitHub markdown preview. "Verification" for asset tasks = file exists + opens + size budget.
- Tasks are sequenced into 7 workstreams (W1–W7). W1–W3 are text-only and unblocked. W4–W6 are asset workstreams; can run in parallel. W7 stitches.
- TDD-equivalent for non-code work = a check (file existence, grep for forbidden tokens, image dimensions, size budget) that **fails before the work** and **passes after**. Every task has an explicit fail-then-pass gate.

---

## Workstream Index

| W# | Name | Tasks | Output |
|----|------|-------|--------|
| W1 | Positioning copy | T1.1 – T1.4 | Hero block fragment (markdown) |
| W2 | Five Scenes prose | T2.1 – T2.6 | Scenes section fragment |
| W3 | With/Without + What You Get rewrite | T3.1 – T3.3 | Two table fragments |
| W4 | VHS setup + 5 tapes + gifs | T4.1 – T4.7 | `vhs/*.tape` (5) + `images/scenes/*.gif` (5) |
| W5 | Logo via mcp-hfspace + FLUX | T5.1 – T5.6 | `images/logo.png`, `images/logo.svg`, `images/banner.png` |
| W6 | Hero animation via Motion Canvas | T6.1 – T6.6 | `motion/` project + `images/hero.gif` + `images/hero.mp4` |
| W7 | Final README assembly | T7.1 – T7.4 | `README.md` rewritten + verified |

---

## W1 — Positioning Copy Rewrite

### Task 1.1: Stage hero copy fragment file

**Files:**
- Create: `docs/plans/positioning-copy/hero.md`

**Step 1: Write the failing check**
Run: `test ! -f docs/plans/positioning-copy/hero.md && echo FAIL`
Expected: `FAIL` (file does not yet exist).

**Step 2: Create the fragment with tagline + subtitle**
Contents of `docs/plans/positioning-copy/hero.md`:
```markdown
# Turbocharge

**Claude Code with a spine.**

*An opinionated pipeline that refuses to let you skip review, skip tests, or pick the wrong agent.*
```

**Step 3: Verify it now exists and matches the design**
Run: `test -f docs/plans/positioning-copy/hero.md && grep -q "Claude Code with a spine." docs/plans/positioning-copy/hero.md && echo PASS`
Expected: `PASS`

**Step 4: Commit**
`git commit -m "docs: stage hero tagline + subtitle for v3 README"`

---

### Task 1.2: Add hero paragraph (two sentences, including memory beat)

**Files:**
- Modify: `docs/plans/positioning-copy/hero.md`

**Step 1: Write the failing check**
Run: `grep -q "remembers" docs/plans/positioning-copy/hero.md || echo FAIL`
Expected: `FAIL`

**Step 2: Append the hero paragraph**
Append to `docs/plans/positioning-copy/hero.md`:
```markdown

Turbocharge is the pipeline you'd build yourself if you had six months — and the discipline you'd enforce if you weren't tired at 11 PM. Ten skills, six agents, three hooks, one chain of command. Install it and stop maintaining your own orchestration.

It also remembers. Every session you close with `/wrap` teaches Claude something — your preferences, your conventions, the corrections you made today. Next Monday, Claude already knows.
```

**Step 3: Verify**
Run: `grep -q "Next Monday, Claude already knows." docs/plans/positioning-copy/hero.md && grep -q "ten skills, six agents" -i docs/plans/positioning-copy/hero.md && echo PASS`
Expected: `PASS`

**Step 4: Commit**
`git commit -m "docs: add hero paragraph with memory compounding beat"`

---

### Task 1.3: Banned-vocabulary lint of hero fragment

**Files:**
- Create: `scripts/lint-positioning.sh`

**Step 1: Write the failing check**
Run: `test ! -f scripts/lint-positioning.sh && echo FAIL`
Expected: `FAIL`

**Step 2: Create the lint script**
Contents of `scripts/lint-positioning.sh`:
```bash
#!/usr/bin/env bash
# Fails (exit 1) if any banned vocabulary appears in the staged copy fragments
# or in README.md once assembled.
set -euo pipefail

BANNED='powerful|comprehensive|advanced|platform|framework|orchestration|learns'
TARGETS="${*:-docs/plans/positioning-copy README.md}"

hits=$(grep -REin --include='*.md' "\b(${BANNED})\b" $TARGETS || true)
if [ -n "$hits" ]; then
  echo "BANNED VOCABULARY FOUND:"
  echo "$hits"
  exit 1
fi
echo "lint-positioning: clean"
```

**Step 3: Verify it runs and passes against the hero fragment**
Run: `bash scripts/lint-positioning.sh docs/plans/positioning-copy/hero.md`
Expected: `lint-positioning: clean` exit 0.
(If FAIL: rewrite the offending phrase before continuing.)

**Step 4: Commit**
`git commit -m "chore: add positioning vocabulary lint script"`

---

### Task 1.4: Self-review hero fragment against register table

**Files:**
- Read-only: `docs/plans/positioning-copy/hero.md`, `docs/plans/2026-04-13-positioning-design.md`

**Step 1: Verification check**
Run: `bash scripts/lint-positioning.sh docs/plans/positioning-copy/hero.md && wc -w docs/plans/positioning-copy/hero.md`
Expected: clean lint, word count between 70 and 130 (hero block tightness budget).

**Step 2: Read-aloud test (manual)**
Open `docs/plans/positioning-copy/hero.md` and confirm:
- Tagline is exactly `Claude Code with a spine.`
- (B) Discipline beat is dominant in the subtitle.
- (C) Compounding beat is present in paragraph 2.
- No capability brags, no enemy-name ("ruflo"), no numbered claims beyond `Ten skills, six agents, three hooks`.

**Step 3: Commit (no-op if no changes)**
`git status` — only commit if edits made.

---

## W2 — Five Scenes Prose

### Task 2.1: Stage scenes fragment skeleton

**Files:**
- Create: `docs/plans/positioning-copy/scenes.md`

**Step 1: Failing check**
Run: `test ! -f docs/plans/positioning-copy/scenes.md && echo FAIL`
Expected: `FAIL`

**Step 2: Create the skeleton (5 H3s + Before/After + gif slots)**
Contents:
```markdown
## Five Scenes

### The 11 PM Skip

_(Before)_ TODO

_(After)_ TODO

![scene: 11pm-skip](images/scenes/11pm-skip.gif)

### The Agent Graveyard

_(Before)_ TODO

_(After)_ TODO

![scene: agent-graveyard](images/scenes/agent-graveyard.gif)

### The Monday Re-explain

_(Before)_ TODO

_(After)_ TODO

![scene: monday-reexplain](images/scenes/monday-reexplain.gif)

### The Context Amnesia

_(Before)_ TODO

_(After)_ TODO

![scene: context-amnesia](images/scenes/context-amnesia.gif)

### The Guess-and-Check Debug

_(Before)_ TODO

_(After)_ TODO

![scene: guess-and-check](images/scenes/guess-and-check.gif)
```

**Step 3: Verify**
Run: `grep -c "^### " docs/plans/positioning-copy/scenes.md`
Expected: `5`

**Step 4: Commit**
`git commit -m "docs: scaffold five-scenes skeleton with gif slots"`

---

### Task 2.2: Write Scene 1 — The 11 PM Skip

**Files:** Modify `docs/plans/positioning-copy/scenes.md`

**Step 1: Failing check**
Run: `grep -A1 "The 11 PM Skip" docs/plans/positioning-copy/scenes.md | grep -q TODO && echo FAIL`
Expected: `FAIL`

**Step 2: Replace the two TODOs under "### The 11 PM Skip"**
Before:
> Feature works. You know you should review. You're tired. You don't. Two days later, your teammate finds the bug you'd have caught.

After:
> `/turbocharge:build` won't mark the task complete until the spec-reviewer and quality-reviewer have run. It isn't a button you remember to press — it's the only way the pipeline lets you exit.

**Step 3: Verify**
Run: `! grep -A1 "The 11 PM Skip" docs/plans/positioning-copy/scenes.md | grep -q TODO && echo PASS`
Expected: `PASS`

**Step 4: Lint**
Run: `bash scripts/lint-positioning.sh docs/plans/positioning-copy/scenes.md`
Expected: clean.

**Step 5: Commit**
`git commit -m "docs: write Scene 1 (11 PM Skip) Before/After"`

---

### Task 2.3: Write Scene 2 — The Agent Graveyard

**Files:** Modify `docs/plans/positioning-copy/scenes.md`

**Step 1: Failing check** — same shape as 2.2 against "Agent Graveyard".

**Step 2: Replace TODOs**
Before:
> `code-reviewer.md`, `code-reviewer-v2.md`, `tdd-guide.md`, `tdd-guide-strict.md`, `planner.md`, `planner-actually-good.md`. Claude picks one at random. You can't remember which one is current.

After:
> One plugin. Ten skills. Six agents. `/turbocharge:setup` audits `~/.claude/agents/` on first run and offers to delete the graveyard. The only orchestration you install is the one you stop maintaining.

**Step 3–5:** Verify (no TODO under heading), lint clean, commit `docs: write Scene 2 (Agent Graveyard) Before/After`.

---

### Task 2.4: Write Scene 3 — The Monday Re-explain

**Files:** Modify `docs/plans/positioning-copy/scenes.md`

**Step 1: Failing check** — TODO under "Monday Re-explain".

**Step 2: Replace TODOs**
Before:
> Monday morning. You explain it again — immutable patterns, tests live in `__tests__/`, files stay under 400 lines. The exact speech you gave Friday afternoon to a Claude that has since forgotten you exist.

After:
> `/wrap` wrote it all to memory Friday at 5 PM — preferences, conventions, the corrections you made that week. Monday's Claude read it before you sat down. You open the laptop and skip the speech.

**Step 3–5:** Verify, lint, commit `docs: write Scene 3 (Monday Re-explain) Before/After`.

---

### Task 2.5: Write Scene 4 — The Context Amnesia

**Files:** Modify `docs/plans/positioning-copy/scenes.md`

**Step 1: Failing check** — TODO under "Context Amnesia".

**Step 2: Replace TODOs**
Before:
> "Where was I?" Scroll terminal history. Re-read your own commits. Open three files to rebuild the mental model. Twenty minutes gone before you write a line.

After:
> `/wrap` captured the state — open question, current file, last decision, what's next. The fresh session reads the resume prompt and you're typing code in ninety seconds.

**Step 3–5:** Verify, lint, commit `docs: write Scene 4 (Context Amnesia) Before/After`.

---

### Task 2.6: Write Scene 5 — The Guess-and-Check Debug

**Files:** Modify `docs/plans/positioning-copy/scenes.md`

**Step 1: Failing check** — TODO under "Guess-and-Check".

**Step 2: Replace TODOs**
Before:
> Test fails. Try a thing. Still red. Try another thing. An hour in, the bar is green and you have no idea why. The bug will be back in three weeks.

After:
> `/turbocharge:debug` forces a four-phase root-cause investigation before any fix lands. You name the broken assumption, prove it, then change one thing. You unbreak it on purpose, not by coincidence.

**Step 3–5:** Verify (`! grep -q TODO docs/plans/positioning-copy/scenes.md`), lint, commit `docs: write Scene 5 (Guess-and-Check Debug) Before/After`.

---

## W3 — With/Without + What You Get Rewrite

### Task 3.1: Stage with/without fragment with new memory row

**Files:** Create `docs/plans/positioning-copy/with-without.md`

**Step 1: Failing check**
Run: `test ! -f docs/plans/positioning-copy/with-without.md && echo FAIL`
Expected: `FAIL`

**Step 2: Write the table (Before/After voice; 7 rows including new memory row)**
Contents:
```markdown
## With vs Without Turbocharge

| | Without | With Turbocharge |
|---|---------|------------------|
| Which agent for X? | Three overlapping ones — Claude rolls the dice. | One skill per step. The handoff is the design. |
| Code review | "I'll do it later." (You won't.) | The build skill won't exit until spec + quality review pass. |
| Bug fixes | Try things until green. Ship the coincidence. | Four-phase root-cause before any fix touches code. |
| Session continuity | Re-explain your project every Monday. | `/wrap` captures state Friday. Monday picks it up. |
| Claude gets smarter across sessions? | You re-teach the same lessons every week. | Memory populated by `/wrap`. Yesterday's correction is today's default. |
| TDD discipline | "Next time I'll write the test first." | Every task starts on a failing test. The pipeline gates on it. |
| Planning granularity | "Add auth." | 2–5 minute tasks with exact paths and verification commands. |
```

**Step 3: Verify row count + memory row**
Run: `grep -c "^|" docs/plans/positioning-copy/with-without.md` → expected ≥ 9 (header + separator + 7 rows). Then `grep -q "smarter across sessions" docs/plans/positioning-copy/with-without.md && echo PASS`
Expected: `PASS`

**Step 4: Lint + commit**
Run: `bash scripts/lint-positioning.sh docs/plans/positioning-copy/with-without.md`
Commit: `docs: rewrite with/without table with memory row`

---

### Task 3.2: Stage What You Get fragment (10 skills)

**Files:** Create `docs/plans/positioning-copy/what-you-get-skills.md`

**Step 1: Failing check** — file does not exist.

**Step 2: Write the skills table — each "Does" cell rewritten as constraint or relief**
Contents:
```markdown
## What You Get

**Ten skills** — each a slash command:

| Skill | What it refuses to let you skip |
|-------|---------------------------------|
| `setup` | Running with conflicting agents. Audits `~/.claude/agents/` on first run. |
| `atlas` | Coding without a domain map. Generates `ATLAS.md` from the actual codebase. |
| `brainstorm` | Implementing a half-formed idea. Socratic discovery, design doc out. |
| `story` | Vague work. Forces INVEST stories with testable acceptance criteria. |
| `plan` | "Add auth." Breaks stories into 2–5 minute TDD tasks with exact paths. |
| `build` | Marking a task done before spec + quality review pass. |
| `review` | Merging without a holistic pass against the original plan. |
| `debug` | Guess-and-check. Four-phase root-cause investigation before any fix. |
| `ship` | Shipping with red tests. Verifies, then merge / PR / discard. |
| `wrap` | Closing the laptop without saving what you taught Claude today. |
```

**Step 3:** Verify 10 skill rows: `grep -cE '^\| \`' docs/plans/positioning-copy/what-you-get-skills.md` → `10`.

**Step 4:** Lint + commit `docs: rewrite skills table as constraints not features`.

---

### Task 3.3: Stage What You Get fragments (6 agents + 3 hooks)

**Files:** Create `docs/plans/positioning-copy/what-you-get-agents-hooks.md`

**Step 1: Failing check** — file does not exist.

**Step 2: Write the agents table + hooks list**
Contents:
```markdown
**Six agents** — dispatched by skills, never invoked directly:

| Agent | Role |
|-------|------|
| `builder` | TDD implementation in an isolated worktree. |
| `planner` | Decomposes stories into tasks; verifies entity names against the codebase. |
| `researcher` | Fast codebase exploration on Haiku, runs in the background. |
| `spec-reviewer` | Reads the task spec and the diff. Doesn't take builder's word. |
| `quality-reviewer` | Categorized code quality issues. Blocks completion on CRITICAL. |
| `code-reviewer` | Holistic pre-merge pass against the original plan. |

**Three hooks** — fire on lifecycle events, not on request:

- `SessionStart` — bootstraps context, flags missing `CLAUDE.md` / `ATLAS.md`.
- `PreToolUse` on `Read` — nudges `.codemap/` usage when an index exists.
- `Stop` — reminds you to `/wrap` before the session ends.
```

**Step 3:** Verify 6 agent rows + 3 hook bullets: `grep -cE '^\| \`' docs/plans/positioning-copy/what-you-get-agents-hooks.md` → `6`; `grep -cE '^- \`' docs/plans/positioning-copy/what-you-get-agents-hooks.md` → `3`.

**Step 4:** Lint + commit `docs: rewrite agents + hooks tables for v3 README`.

---

## W4 — VHS Setup + 5 Tapes + GIF Generation

### Task 4.1: Install VHS and verify

**Files:** none (host-level install). Optionally append a one-liner to `scripts/validate.sh` later (deferred to T7.4).

**Step 1: Failing check**
Run: `command -v vhs >/dev/null 2>&1 || echo FAIL`
Expected: `FAIL` (assumes not installed).

**Step 2: Install**
- macOS: `brew install vhs`
- Linux/Windows-WSL: `go install github.com/charmbracelet/vhs@latest && export PATH="$PATH:$(go env GOPATH)/bin"`
- Windows native: `winget install charmbracelet.vhs`

**Step 3: Verify**
Run: `vhs --version`
Expected: a version string, exit 0.

**Step 4: Commit (no source changes)** — skip.

---

### Task 4.2: Create `vhs/` directory + shared theme/config tape

**Files:** Create `vhs/_common.tape` (re-usable settings included by every scene tape).

**Step 1: Failing check**
Run: `test ! -f vhs/_common.tape && echo FAIL`
Expected: `FAIL`

**Step 2: Write the common config**
Contents of `vhs/_common.tape`:
```
# Shared VHS settings — included by every scene tape via `Source vhs/_common.tape`
Set Shell "bash"
Set FontSize 18
Set Width 1200
Set Height 700
Set Theme "Dracula"
Set TypingSpeed 50ms
Set PlaybackSpeed 1.0
Set Padding 30
```

**Step 3: Verify**
Run: `test -f vhs/_common.tape && grep -q "FontSize" vhs/_common.tape && echo PASS`
Expected: `PASS`

**Step 4:** Commit `chore(vhs): add shared tape config`.

---

### Task 4.3: Author tape — `11pm-skip.tape`

**Files:** Create `vhs/11pm-skip.tape`

**Step 1: Failing check**
Run: `test ! -f images/scenes/11pm-skip.gif && echo FAIL`
Expected: `FAIL`

**Step 2: Write the tape (Before keystrokes, then After keystrokes; ~12s total)**
Contents:
```
Source vhs/_common.tape
Output images/scenes/11pm-skip.gif

# BEFORE — tired developer skipping review at 11 PM
Type "# 11:07 PM. Feature works. Ship it?"
Sleep 1s
Enter
Type "git commit -m 'feat: checkout flow' && git push"
Sleep 800ms
Enter
Sleep 1500ms
Type "# (two days later: bug found in review)"
Sleep 1500ms
Enter
Sleep 800ms

# AFTER — turbocharge gates completion on review chain
Type "/turbocharge:build"
Sleep 600ms
Enter
Sleep 1s
Type "# builder → spec-reviewer → quality-reviewer"
Sleep 1s
Enter
Type "# task cannot exit until both reviewers pass"
Sleep 1500ms
Enter
Sleep 1s
```

**Step 3: Render and verify**
Run: `vhs vhs/11pm-skip.tape && test -f images/scenes/11pm-skip.gif && echo PASS`
Expected: `PASS`. File size budget < 2 MB; check with `wc -c < images/scenes/11pm-skip.gif`.

**Step 4:** Commit `feat(vhs): scene 1 — 11 PM Skip tape + gif`.

---

### Task 4.4: Author tape — `agent-graveyard.tape`

**Files:** Create `vhs/agent-graveyard.tape`

**Step 1: Failing check** — `test ! -f images/scenes/agent-graveyard.gif && echo FAIL`.

**Step 2: Write tape**
```
Source vhs/_common.tape
Output images/scenes/agent-graveyard.gif

Type "ls ~/.claude/agents/"
Sleep 600ms
Enter
Sleep 1s
Type "# code-reviewer.md  code-reviewer-v2.md  code-reviewer-strict.md"
Enter
Type "# tdd-guide.md      tdd-guide-v2.md       planner.md  planner-actually-good.md"
Sleep 2s
Enter

Type "/turbocharge:setup"
Sleep 600ms
Enter
Sleep 1s
Type "# Found 7 conflicting agents. Remove? (y/n)"
Sleep 1s
Enter
Type "y"
Sleep 600ms
Enter
Sleep 800ms
Type "# Cleaned. Now: one plugin, ten skills, six agents."
Sleep 1500ms
Enter
Sleep 1s
```

**Step 3:** `vhs vhs/agent-graveyard.tape` → file exists, < 2 MB.

**Step 4:** Commit `feat(vhs): scene 2 — Agent Graveyard tape + gif`.

---

### Task 4.5: Author tapes — `monday-reexplain.tape` + `context-amnesia.tape`

**Files:** Create both tapes.

**Step 1: Failing checks** — neither gif exists.

**Step 2: Write `vhs/monday-reexplain.tape`**
```
Source vhs/_common.tape
Output images/scenes/monday-reexplain.gif

Type "# Monday 9:02 AM"
Enter
Sleep 600ms
Type "# 'Remember: immutable patterns. Tests in __tests__/. Files < 400 lines.'"
Sleep 1500ms
Enter
Type "# (You said this Friday. And the Friday before.)"
Sleep 1500ms
Enter
Sleep 1s

Type "# After /wrap on Friday:"
Enter
Sleep 600ms
Type "cat ~/.claude/projects/*/memory/MEMORY.md"
Sleep 600ms
Enter
Sleep 800ms
Type "# - immutable patterns are project-wide"
Enter
Type "# - tests live in __tests__/"
Enter
Type "# - 400-line file ceiling"
Sleep 1500ms
Enter
Type "# Monday's Claude read it before you sat down."
Sleep 1500ms
```

**Step 2b: Write `vhs/context-amnesia.tape`**
```
Source vhs/_common.tape
Output images/scenes/context-amnesia.gif

Type "# Monday. Where was I?"
Enter
Sleep 800ms
Type "history | tail -50"
Enter
Sleep 1500ms
Type "git log --oneline -20"
Enter
Sleep 1500ms
Type "# 20 minutes gone, still rebuilding the mental model"
Sleep 1500ms
Enter

Type "# With /wrap:"
Enter
Sleep 600ms
Type "claude --resume"
Enter
Sleep 1s
Type "# Resuming: 'Adding rate limiting to /api/login. Test red on burst case.'"
Sleep 2s
Enter
Type "# Coding in 90 seconds."
Sleep 1500ms
```

**Step 3: Render both**
Run: `vhs vhs/monday-reexplain.tape && vhs vhs/context-amnesia.tape && ls -la images/scenes/monday-reexplain.gif images/scenes/context-amnesia.gif`
Expected: both files exist, < 2 MB each.

**Step 4:** Commit `feat(vhs): scenes 3+4 — Monday Re-explain and Context Amnesia tapes`.

---

### Task 4.6: Author tape — `guess-and-check.tape`

**Files:** Create `vhs/guess-and-check.tape`

**Step 1: Failing check** — gif missing.

**Step 2: Write tape**
```
Source vhs/_common.tape
Output images/scenes/guess-and-check.gif

Type "pytest tests/test_checkout.py::test_total_with_discount"
Enter
Sleep 1s
Type "# FAILED — try changing the rounding"
Enter
Sleep 800ms
Type "pytest ..."
Enter
Sleep 800ms
Type "# still red — try the discount order"
Enter
Sleep 800ms
Type "pytest ..."
Enter
Sleep 800ms
Type "# green! ...but why?"
Sleep 1500ms
Enter

Type "/turbocharge:debug"
Sleep 600ms
Enter
Sleep 1s
Type "# Phase 1: reproduce  Phase 2: hypothesize  Phase 3: prove  Phase 4: fix"
Sleep 1500ms
Enter
Type "# You unbreak it on purpose, not by coincidence."
Sleep 1500ms
```

**Step 3:** Render: `vhs vhs/guess-and-check.tape && test -f images/scenes/guess-and-check.gif && echo PASS`.

**Step 4:** Commit `feat(vhs): scene 5 — Guess-and-Check Debug tape + gif`.

---

### Task 4.7: Verify all 5 gifs exist and meet size budget

**Step 1: Failing check (only meaningful if any are missing)**
Run:
```
for s in 11pm-skip agent-graveyard monday-reexplain context-amnesia guess-and-check; do
  f="images/scenes/${s}.gif"
  test -f "$f" || { echo "MISSING $f"; exit 1; }
  size=$(wc -c < "$f")
  [ "$size" -lt 2097152 ] || { echo "OVER BUDGET $f ($size bytes)"; exit 1; }
done
echo PASS
```
Expected: `PASS`. If OVER BUDGET → reduce `Width`/`Height` or `Sleep` durations and re-render.

**Step 2:** Commit only if any tape was edited: `chore(vhs): trim tapes to fit 2 MB budget`.

---

## W5 — Logo Generation via mcp-hfspace + FLUX.1-Krea-dev

### Task 5.1: Install mcp-hfspace MCP server

**Files:** none (Claude Code MCP config).

**Step 1: Failing check**
Run: `claude mcp list | grep -q mcp-hfspace || echo FAIL`
Expected: `FAIL`

**Step 2: Install**
Run:
```
claude mcp add-json "mcp-hfspace" '{"command":"npx","args":["-y","@llmindset/mcp-hfspace"]}'
```
Then in browser at `https://huggingface.co/mcp/settings`, add `mcp-tools/FLUX.1-Krea-dev` to Spaces Tools.

**Step 3: Verify**
Run: `claude mcp list | grep mcp-hfspace`
Expected: entry present. Then in a Claude session: list available tools, confirm `FLUX.1-Krea-dev` text-to-image tool surface.

**Step 4:** No commit (config-only).

---

### Task 5.2: Stage logo prompt file

**Files:** Create `docs/plans/positioning-copy/logo-prompt.md`

**Step 1: Failing check** — file missing.

**Step 2: Write the prompt + negative prompt**
Contents:
```markdown
# FLUX.1-Krea-dev Prompt — Turbocharge Logo

## Prompt
A minimalist logo of an abstract vertical spine composed of ten distinct rectangular segments, each segment slightly different but precisely aligned along a single axis. Two-tone palette: deep ink-blue (#0B1E3F) on warm off-white (#F5F1E8). Clean geometric forms, faintly tactile paper texture, soft natural lighting from upper-left, no shadows. Honest, structural, restrained. Centered composition on a square canvas, generous negative space.

## Negative prompt
glossy, chrome, metallic, futuristic, swirling energy, neural network, glowing, holographic, rainbow gradient, lens flare, 3D render, cinematic, dramatic lighting, sci-fi, cyberpunk

## Iteration parameters
- Aspect: 1:1 for logo, 16:9 for banner
- Steps: 28
- Guidance: 4.5
- Output: 1024×1024 (logo), 1920×1080 (banner)
```

**Step 3:** Verify file exists with both prompt and negative prompt sections. Commit `docs: lock FLUX prompt for turbocharge logo`.

---

### Task 5.3: Generate logo PNG (3 iterations, pick best)

**Files:** Output `images/logo-iter-1.png`, `images/logo-iter-2.png`, `images/logo-iter-3.png`.

**Step 1: Failing check** — `test ! -f images/logo-iter-1.png && echo FAIL`.

**Step 2:** In a Claude Code session with `mcp-hfspace` available, dispatch FLUX.1-Krea-dev with the prompt from `logo-prompt.md`, aspect 1:1, three different seeds (e.g., 1, 17, 42). Save outputs to `images/logo-iter-{1,2,3}.png`.

**Step 3: Verify**
Run: `ls -la images/logo-iter-*.png` → 3 files, each ≈1024×1024.

**Step 4:** Commit `chore(images): add 3 FLUX iterations for logo selection`.

---

### Task 5.4: Pick winner, finalize as `images/logo.png`

**Files:** Copy chosen iteration → `images/logo.png`. Delete the other two.

**Step 1: Failing check** — `test ! -f images/logo.png && echo FAIL`.

**Step 2:** Visually compare the three. Pick the one with cleanest segment alignment and least "AI texture artifacts". Copy it: `cp images/logo-iter-N.png images/logo.png`. Remove iterations: `rm images/logo-iter-{1,2,3}.png`.

**Step 3: Verify**
Run: `test -f images/logo.png && file images/logo.png | grep -q PNG && echo PASS`
Expected: `PASS`.

**Step 4:** Commit `feat(images): finalize turbocharge logo (raster)`.

---

### Task 5.5: Vectorize logo to SVG via vtracer

**Files:** Output `images/logo.svg`. Tool: `vtracer` (Rust binary, free, OSS).

**Step 1: Failing check** — `test ! -f images/logo.svg && echo FAIL`.

**Step 2: Install + run**
- Install: `cargo install vtracer` (or download binary from `https://github.com/visioncortex/vtracer/releases`).
- Run: `vtracer --input images/logo.png --output images/logo.svg --mode polygon --color_precision 4 --filter_speckle 6`

**Step 3: Verify**
Run: `test -f images/logo.svg && head -1 images/logo.svg | grep -q "<svg" && echo PASS`
Expected: `PASS`. File size budget < 50 KB.

**Step 4:** Commit `feat(images): vectorize logo to SVG via vtracer`.

---

### Task 5.6: Generate banner (16:9 wide hero)

**Files:** Output `images/banner.png`.

**Step 1: Failing check** — `test ! -f images/banner.png && echo FAIL`.

**Step 2:** Re-dispatch FLUX.1-Krea-dev with banner aspect (16:9, 1920×1080), prompt augmented with `, wide horizontal composition, logo centered with breathing room left and right`. Save to `images/banner.png`.

**Step 3: Verify**
Run: `test -f images/banner.png && file images/banner.png | grep -q PNG && echo PASS`. Size budget < 500 KB; if larger, run `pngquant --quality=70-85 --output images/banner.png --force images/banner.png`.

**Step 4:** Commit `feat(images): add wide banner for README hero`.

---

## W6 — Hero Animation via Motion Canvas

### Task 6.1: Scaffold Motion Canvas project in `motion/`

**Files:** Create `motion/` (full Motion Canvas scaffold).

**Step 1: Failing check** — `test ! -d motion && echo FAIL`.

**Step 2:** Run from repo root:
```
npm init @motion-canvas@latest motion
```
Accept defaults (TypeScript template). Then add `motion/node_modules` and `motion/output` to `.gitignore`.

**Step 3: Verify**
Run: `test -f motion/package.json && test -f motion/src/project.ts && echo PASS`
Expected: `PASS`.

**Step 4:** Commit `chore(motion): scaffold Motion Canvas project for hero animation`.

---

### Task 6.2: Replace template scene with `spineCollapse`

**Files:** Create `motion/src/scenes/spineCollapse.tsx`. Modify `motion/src/project.ts`.

**Step 1: Failing check**
Run: `test ! -f motion/src/scenes/spineCollapse.tsx && echo FAIL`
Expected: `FAIL`.

**Step 2: Write `motion/src/scenes/spineCollapse.tsx`**
```tsx
import {makeScene2D, Rect, Txt} from '@motion-canvas/2d';
import {all, createRef, easeInOutCubic, waitFor} from '@motion-canvas/core';

const SKILLS = [
  'setup', 'atlas', 'brainstorm', 'story', 'plan',
  'build', 'review', 'debug', 'ship', 'wrap',
];

// 6s total = 2s jumble hold + 2s collapse + 2s aligned hold.
export default makeScene2D(function* (view) {
  view.fill('#F5F1E8');

  // Deterministic jumble positions (seeded, stable across renders).
  const jumble = SKILLS.map((_, i) => ({
    x: ((i * 73) % 900) - 450,
    y: ((i * 131) % 500) - 250,
    rot: ((i * 47) % 60) - 30,
  }));

  const refs = SKILLS.map(() => createRef<Rect>());

  // Phase 1 — render jumble
  view.add(
    SKILLS.map((name, i) => (
      <Rect
        ref={refs[i]}
        x={jumble[i].x}
        y={jumble[i].y}
        rotation={jumble[i].rot}
        fill={'#0B1E3F'}
        radius={4}
        padding={[10, 22]}
        layout
      >
        <Txt fontFamily={'monospace'} fontSize={22} fill={'#F5F1E8'}>
          /{name}
        </Txt>
      </Rect>
    )),
  );

  yield* waitFor(2);

  // Phase 2 — collapse to vertical spine
  yield* all(
    ...SKILLS.map((_, i) =>
      all(
        refs[i]().position([0, (i - SKILLS.length / 2) * 56 + 28], 2, easeInOutCubic),
        refs[i]().rotation(0, 2, easeInOutCubic),
      ),
    ),
  );

  // Phase 3 — hold aligned spine
  yield* waitFor(2);
});
```

**Step 2b: Edit `motion/src/project.ts`** — register the scene (replace template content):
```ts
import {makeProject} from '@motion-canvas/core';
import spineCollapse from './scenes/spineCollapse?scene';

export default makeProject({
  scenes: [spineCollapse],
  experimentalFeatures: true,
});
```

**Step 3: Verify it loads in the editor (smoke test)**
Run: `cd motion && npm start` (open `http://localhost:9000`, confirm scene plays end-to-end, then Ctrl+C).

**Step 4:** Commit `feat(motion): spineCollapse scene (jumble → spine alignment)`.

---

### Task 6.3: Render hero MP4

**Files:** Output `images/hero.mp4`. Configure render output dir.

**Step 1: Failing check** — `test ! -f images/hero.mp4 && echo FAIL`.

**Step 2: Render**
The Motion Canvas CLI renders to `motion/output/` by default. Render then move:
```
cd motion
npm run render -- --output ../images/hero.mp4
```
(If the project's `package.json` `render` script doesn't accept `--output`, render to default location and `mv motion/output/*.mp4 images/hero.mp4`.)

Render uses ffmpeg under the hood — must be on PATH (already installed for VHS).

**Step 3: Verify**
Run: `test -f images/hero.mp4 && file images/hero.mp4 | grep -qi 'mp4\|MPEG' && echo PASS`. Size budget < 4 MB.

**Step 4:** Commit `feat(motion): render hero.mp4 (spineCollapse, 6s)`.

---

### Task 6.4: Convert hero MP4 → GIF (web-optimized fallback)

**Files:** Output `images/hero.gif`. Tool: `ffmpeg` + optional `gifsicle` for compression.

**Step 1: Failing check** — `test ! -f images/hero.gif && echo FAIL`.

**Step 2: Two-pass GIF conversion (palette-aware, much smaller files than naive ffmpeg)**
```
ffmpeg -y -i images/hero.mp4 -vf "fps=15,scale=800:-1:flags=lanczos,palettegen" /tmp/hero-palette.png
ffmpeg -y -i images/hero.mp4 -i /tmp/hero-palette.png -filter_complex "fps=15,scale=800:-1:flags=lanczos[x];[x][1:v]paletteuse" images/hero.gif
```

**Step 3: Verify size budget < 2 MB**
Run: `test -f images/hero.gif && [ "$(wc -c < images/hero.gif)" -lt 2097152 ] && echo PASS`
If over budget: drop scale to `640:-1` and re-run both ffmpeg commands, or post-process with `gifsicle -O3 --colors 64 images/hero.gif -o images/hero.gif`.

**Step 4:** Commit `feat(motion): convert hero.mp4 to web-optimized hero.gif (<2 MB)`.

---

### Task 6.5: Add `motion/` artifacts to `.gitignore`

**Files:** Modify `.gitignore` (create if absent).

**Step 1: Failing check**
Run: `grep -q "motion/node_modules" .gitignore 2>/dev/null || echo FAIL`
Expected: `FAIL`.

**Step 2: Append to `.gitignore`**
```
motion/node_modules/
motion/output/
motion/dist/
```

**Step 3: Verify**
Run: `grep -q "motion/node_modules" .gitignore && grep -q "motion/output" .gitignore && echo PASS`.

**Step 4:** Commit `chore: ignore Motion Canvas build artifacts`.

---

### Task 6.6: Document hero re-render in `motion/README.md`

**Files:** Create `motion/README.md` (required only because re-render commands are non-obvious for future contributors).

**Step 1: Failing check** — file missing.

**Step 2: Write minimal doc**
````markdown
# Hero animation (Motion Canvas)

`spineCollapse` scene — 6s, 60fps, 1920×1080. Jumbled `~/.claude/agents/` files collapse into a vertical spine of ten labeled skills.

## Re-render

```
cd motion
npm install
npm run render -- --output ../images/hero.mp4

# Then convert MP4 → web-optimized GIF
ffmpeg -y -i ../images/hero.mp4 -vf "fps=15,scale=800:-1:flags=lanczos,palettegen" /tmp/hero-palette.png
ffmpeg -y -i ../images/hero.mp4 -i /tmp/hero-palette.png \
  -filter_complex "fps=15,scale=800:-1:flags=lanczos[x];[x][1:v]paletteuse" \
  ../images/hero.gif
```

## Licensing

Motion Canvas is MIT — free forever, no engineer-count strings. Fork it, re-render, ship — no license check.
````

**Step 3:** Verify file exists and contains `Re-render`. Commit `docs(motion): document hero re-render workflow`.

---

## W7 — Final README Assembly

### Task 7.1: Assemble new `README.md` from fragments

**Files:** Modify `README.md` (full rewrite of the pitch surface; preserves install block, pipeline diagram, Iron Laws, deep-dives, license).

**Step 1: Failing check**
Run: `grep -q "Claude Code with a spine." README.md || echo FAIL`
Expected: `FAIL`.

**Step 2: Rewrite `README.md`** — replace lines 1–88 (hero through "Why" through With/Without through "What You Get") with the assembled fragments. Preserve the Pipeline diagram (current lines ~50–73), Iron Laws (current ~127–146), and all `<details>` blocks + license footer.

Final ordering (top to bottom):
1. `<p align="center"><img src="images/hero.gif" alt="Turbocharge — pipeline animation" width="800"/></p>`
2. Contents of `docs/plans/positioning-copy/hero.md` (logo block + tagline + subtitle + hero paragraph)
3. `<p align="center"><img src="images/banner.png" alt="" width="100%"/></p>` (optional, only if banner ≠ duplicative of hero)
4. `---`
5. Contents of `docs/plans/positioning-copy/scenes.md`
6. `---`
7. **Install** section (kept verbatim from current README lines 21–46) + the reassurance line: *"`setup` cleans up any conflicting agents or skills before you start. Run it once."*
8. `---`
9. **The Pipeline** ASCII block (kept) with caption rewritten: *"Enter at any step. Each skill gates the next — review before ship, root-cause before fix, wrap before you forget."*
10. `---`
11. Contents of `docs/plans/positioning-copy/with-without.md`
12. `---`
13. Contents of `docs/plans/positioning-copy/what-you-get-skills.md`
14. Contents of `docs/plans/positioning-copy/what-you-get-agents-hooks.md`
15. `---`
16. **Iron Laws** (kept verbatim from current README lines 127–146)
17. `---`
18. All four `<details>` blocks (kept verbatim)
19. `---`
20. **License** footer (kept).

**Step 3: Verify**
Run:
```
grep -q "Claude Code with a spine." README.md \
&& grep -q "The 11 PM Skip" README.md \
&& grep -q "Iron Laws" README.md \
&& grep -q "MIT" README.md \
&& echo PASS
```
Expected: `PASS`.

**Step 4:** Commit `feat: rewrite README pitch surface (v3 positioning)`.

---

### Task 7.2: Run banned-vocabulary lint against full README

**Step 1: Run the lint**
Run: `bash scripts/lint-positioning.sh README.md`
Expected: `lint-positioning: clean`.

**Step 2: If FAIL** — for each hit, rewrite the offending phrase. The Iron Laws section uses none of the banned words (verified) so flagged hits will all be in newly-written copy.

**Step 3: Commit only if edits made** — `docs: scrub banned vocabulary from README`.

---

### Task 7.3: Verify all images and gifs render on GitHub

**Step 1: Failing check (asset-existence pre-flight)**
Run:
```
for f in images/hero.gif images/hero.mp4 images/logo.png images/logo.svg images/banner.png \
         images/scenes/11pm-skip.gif images/scenes/agent-graveyard.gif \
         images/scenes/monday-reexplain.gif images/scenes/context-amnesia.gif \
         images/scenes/guess-and-check.gif; do
  test -f "$f" || { echo "MISSING $f"; exit 1; }
done
echo PASS
```
Expected: `PASS`.

**Step 2:** Push to a throwaway branch `git checkout -b readme-v3-preview && git push -u origin readme-v3-preview`. Open the branch on GitHub. Verify each image/gif renders inline. Verify pipeline ASCII renders in a code fence (no markdown reflow).

**Step 3:** Manually re-read the rendered README top-to-bottom. Confirm:
- Hero animation plays.
- Tagline reads `Claude Code with a spine.`
- Five scenes section reads as Before/After pairs with gif under each.
- Memory beat appears in both the hero paragraph and the with/without table.
- Iron Laws section unchanged from v2.3.0.

**Step 4:** Merge preview branch back to master via PR (commit message: `docs: ship v3 README positioning rewrite`). Delete the preview branch after merge.

---

### Task 7.4: Update `scripts/validate.sh` to assert positioning assets exist

**Files:** Modify `scripts/validate.sh`.

**Step 1: Failing check**
Run: `grep -q "images/scenes/11pm-skip.gif" scripts/validate.sh || echo FAIL`
Expected: `FAIL`.

**Step 2: Append to `scripts/validate.sh`**
```bash

# Positioning assets (added v3 README)
for f in images/hero.gif images/logo.svg images/banner.png \
         images/scenes/11pm-skip.gif images/scenes/agent-graveyard.gif \
         images/scenes/monday-reexplain.gif images/scenes/context-amnesia.gif \
         images/scenes/guess-and-check.gif; do
  [ -f "$f" ] || { echo "validate: missing positioning asset: $f"; exit 1; }
done
echo "validate: positioning assets OK"
```

**Step 3: Verify**
Run: `bash scripts/validate.sh`
Expected: exits 0 with `validate: positioning assets OK` printed.

**Step 4:** Commit `chore(validate): assert v3 positioning assets present`.

---

## Done Definition

- All 30 tasks above are committed.
- `README.md` opens on GitHub with: hero animation → tagline → hero paragraph → five scenes (each with gif) → install → pipeline → with/without → what you get → iron laws → deep-dives → license.
- `bash scripts/lint-positioning.sh README.md` exits 0.
- `bash scripts/validate.sh` exits 0.
- `images/` contains: `hero.gif`, `hero.mp4`, `logo.png`, `logo.svg`, `banner.png`, and `scenes/{11pm-skip,agent-graveyard,monday-reexplain,context-amnesia,guess-and-check}.gif`.
- `vhs/` contains: `_common.tape` + 5 scene tapes.
- `motion/` contains a working Remotion project + `motion/README.md`.

## Assumptions

1. **VHS install method varies by host OS** — task 4.1 lists three alternatives; the operator picks one. No CI required (gifs are checked in).
2. **mcp-hfspace + FLUX.1-Krea-dev availability** — assumed working on HuggingFace ZeroGPU at execution time. If quota-blocked, retry per design doc §Visual Identity Workstream caveat. No fallback tool wired in (per "tools locked" instruction).
3. **vtracer install** — assumed available via `cargo install` or prebuilt binary. Listed inside task 5.5; not preinstalled.
4. **Motion Canvas licensing** — MIT, no licensing caveat. Swapped from Remotion 2026-04-13 after web-search re-check.
5. **Asset size budgets** — hero gif < 2 MB, scene gifs < 2 MB each, banner < 500 KB, logo SVG < 50 KB. If exceeded, the task notes the mitigation (gifsicle, pngquant, lower width).
6. **No version bump** — design doc explicitly states this is copy + assets only. If the user wants a 2.3.1 patch tag, that is a separate one-task follow-up (not included).
7. **Banner is optional** — the assembly task notes the banner can be omitted if it duplicates the hero animation visually. Decision deferred to T7.1 visual diff.
8. **No 6th scene** — design doc §Open Decisions lands on shipping with 5. Honored.
9. **VHS theme** — defaulted to Dracula (matches dark terminal). Design doc §Open Decisions defers theme-vs-logo coherence; revisit only if visually jarring after T5.4.
10. **Parallel execution** — W4, W5, W6 are independent and may run concurrently across multiple sessions or builders. W1–W3 are also independent. W7 is the only ordering gate (depends on W1–W6).
