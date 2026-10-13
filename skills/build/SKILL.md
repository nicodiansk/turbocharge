---
name: build
description: Use when you have an implementation plan ready to execute. Routes each plan lane inline (main session) or to one Sonnet builder, overlaps independent lanes, and joins with one full-suite gate. Opt-in per-lane review (single Sonnet task-reviewer, two verdicts) for high-risk work.
argument-hint: "[plan-file] [--inline | --delegate] [--reviewed] [--checkpoint]"
---

# Build

Execute an implementation plan lane by lane: mechanical lanes inline, real logic with one builder per lane, independent lanes side by side.

**Announce:** "Using build to execute this plan."

## The Iron Law

```
NO TASK COMPLETE WITHOUT ITS TEST PASSING
NO BUILD COMPLETE WITHOUT THE FULL SUITE GREEN AT THE JOIN
```

## Step 1: Load and Review Plan

1. Read the plan file at $ARGUMENTS
2. Review critically — identify concerns or questions
3. If concerns: raise them before starting
4. Read the plan's **Lanes table** (`| Lane | Owns files | Tasks | After | Executor | Effort |`). **No Lanes table** (a legacy plan) → treat the whole plan as one sequential lane and route it in Step 2 like any other.
5. Parse flags from $ARGUMENTS: `--inline` / `--delegate` (Step 2), `--reviewed` (Step 6), `--checkpoint` (human wait after each lane; off by default). Legacy forms: `--checkpoint=N` means `--checkpoint`; `--checkpoint=0` and `--no-checkpoint` mean no pauses, the default.

## Step 2: Route Lanes

Each lane runs one of two ways:

| Executor | Who runs it | Use for |
|----------|-------------|---------|
| `inline` | The main session, task by task | Mechanical lanes: content edits, exact text given, ≤3 tasks |
| `builder` | One Sonnet builder for the whole lane | Real logic, unfamiliar code, judgment calls |

Start from the plan's Executor hint, then override:
- → `builder` when the lane holds real application logic (functions, classes, control flow) or a design question the plan left open.
- → `inline` when the lane is only a few exact-text edits. A builder spawn costs ~25k tokens and 30–90 s before it writes a line.
- `--inline` runs every lane inline; `--delegate` gives every lane a builder.
- If a lane's route isn't obvious, ask the user.

**No agents here:** if the Agent tool is missing, or a dispatch fails because `turbocharge:builder` is not registered (some surfaces load skills without agents), run every builder lane inline (Step 4), one lane at a time, and say once: `agents unavailable — running lanes inline`.

**Overlap:** lanes with no `After` path between them run at the same time — builder lanes in the background while the main session works the inline lanes. A lane with `After` starts only when every lane it names has finished (Step 5).

**No overlap with stashing commit hooks:** if the project's commit hooks stash unstaged changes, run lanes one at a time. Check for the `pre-commit` framework (`.pre-commit-config.yaml`) and lint-staged — `.lintstagedrc*`, `lint-staged.config.*`, a `lint-staged` key in `package.json`, or a `.husky/` hook that runs it. A pathspec commit leaves every other lane's in-flight edits unstaged, and the hook would stash them out from under that lane.

Announce the routing before executing:
```
lanes: 4 (inline 3 · builder 1)
  plan-format   inline            tasks 1–2
  hook-cleanup  builder (medium)  tasks 6–8   ← background
  ...
```

## Step 3: Spawn Builder Lanes

For each builder lane that is ready (its `After` lanes are done), spawn one builder — subagent type `turbocharge:builder` — with:
- **`effort`** set on the Agent call from the lane's Effort column (default `medium`). The per-spawn value overrides the agent definition.
- Plan file path, lane name, and its task line ranges — do NOT paste plan content; the builder reads the file directly
- Working directory
- Prefix: `@CLAUDE.md` (conventions) — or `@AGENTS.md` if the project has no CLAUDE.md. `.claude/CLAUDE.md` counts as a CLAUDE.md: if the project keeps it there, use `@.claude/CLAUDE.md`. Do NOT inject `@ATLAS.md` — builders read the spec and diff, not the navigation index.
- **Lane rules**, stated in the prompt:
  - Touch only the lane's files. Never stage, stash, reset, or check out anything else.
  - Per task: RED → GREEN on that task's own test. Do NOT run the full suite — other lanes are mid-edit, so it would see their half-written files.
  - Commit per task, scoped to the task: `git add <new files>` (a pathspec commit can't take untracked files), then `git commit -m "<message>" -- <this task's files>` — the paths the task created, changed, deleted, or renamed. Don't pass the whole lane: a lane path that doesn't exist yet makes the commit fail. Never `git commit -a` or `git add -A`.
  - If git reports `index.lock`, wait a moment and retry once.
  - Report per task: commit SHA and test result; then Rulings; then the Status line (builder.md's Report Format).

Dispatch each builder **without** a `name` parameter. A named Agent spawn joins the session's implicit team as a teammate when Agent Teams are enabled; lane builders must stay plain subagents. Note each builder's agent ID against its lane — with no `name`, `SendMessage` fix rounds (Steps 5c and 6) address it by agent ID.

With `--reviewed`, record the lane's `BEFORE_SHA` first (Step 6), before spawning its builder.

Builders run in the background (Claude Code 2.1.198+): the Agent call returns as soon as the builder starts. Do not wait here — go to Step 4.

> **Builder isolation (design decision):** the builder agent intentionally does NOT set `isolation: worktree`. A worktree branches from the **default branch**, not the parent session's HEAD, and is auto-cleaned only when no changes are made — which would break the `$BEFORE_SHA..HEAD` diff model in Step 6 (the reviewer would diff the wrong base) and leave a populated worktree for ship/cleanup to manage. Lanes share one tree and stay apart by owning disjoint files and committing by pathspec.

If a builder reports `Blocked on: context` (Step 5), dispatch the researcher with `@ATLAS.md @CLAUDE.md` prefixed — or `@ATLAS.md @AGENTS.md` if the project has no CLAUDE.md. `.claude/CLAUDE.md` counts as a CLAUDE.md: if the project keeps it there, use `@.claude/CLAUDE.md`. Subagents do not inherit parent history — `@ATLAS.md` must ride on the dispatch prompt itself.

## Step 4: Run Inline Lanes

While builder lanes run, the main session works through the inline lanes, task by task. With `--reviewed`, record the lane's `BEFORE_SHA` first (Step 6), before its first task.
1. Read the task's Decision and Test assertions from the plan. Its line ranges are plan-time hints: if an earlier task in the lane shifted the code, find it by content.
2. Write the test from the assertions and run it — it must fail for the reason the task names (RED).
3. Implement the Decision. Run the test — GREEN.
4. Commit by pathspec: `git add <new files>`, then `git commit -m "<message>" -- <this task's files>`.

Inline lanes follow the same lane rules: only the lane's files, no full suite while builder lanes are in flight.

## Step 5: Join

**When a builder's completion notification arrives,** read the last line of its report, `Status: DONE | DONE_WITH_CONCERNS | BLOCKED`, and its `Blocked on:` kind:
- **DONE** → the lane is finished.
- **DONE_WITH_CONCERNS** → the lane is finished; carry the concerns to Step 7.
- **BLOCKED on destructive, security, outside or design** → take the question to the user. Don't decide it for them.
- **BLOCKED on context** → dispatch the researcher (Step 3), then resume the same builder with `SendMessage`, carrying its findings. Adding context is a change, so the same model is fine, and the builder's context is warm.
- **BLOCKED on stuck**, or `Status: BLOCKED` again after a context resume → retry the lane once with a new Agent call: `subagent_type: turbocharge:builder`, `model: opus`, the same lane, naming the tasks already committed and quoting the BLOCKED report. `SendMessage` can't change the model. Never retry the same model with nothing changed. A BLOCKED Opus retry goes to the user.
- **No Status line** → treat it as DONE_WITH_CONCERNS and check the lane's commits yourself (`git log`, `git status --porcelain -- <lane paths>`).

**After every lane finishes** — an inline lane's last commit, or a builder lane's DONE / DONE_WITH_CONCERNS:
1. Report one line: `lane <name> ✓ · tasks a–b · commits N`.
2. With `--checkpoint`, stop and wait for human approval before starting anything new.
3. Start every lane whose `After` lanes have all finished — Step 3 for a builder lane, Step 4 for an inline lane.

### 5a. Wait for the Completion Notifications

Every builder lane ends with a completion notification — the Agent call returning only meant the builder started. Until a lane's notification arrives, do NOT:
- run the full gate,
- start a lane that lists it in `After`,
- dispatch a task-reviewer for it (Step 6), or
- mark the build complete.

The same holds for every researcher, task-reviewer, and `SendMessage` resume: act on a subagent's result only after its completion notification arrives.

### 5b. Full Gate, once

When every lane has finished — with `--reviewed`, once every lane's review has passed (Step 6) — run the project's full test suite plus its validators (lint, type-check, project validation scripts) once, on the joined tree.

### 5c. Fix Rounds

Route each failure to the lane that owns the failing file:
- **Inline lane:** fix it in the main session, commit by pathspec.
- **Builder lane:** resume that lane's builder with `SendMessage` — send only the failing output. Its context and prompt cache are intact, so it skips the cold start a new spawn would pay. Wait for its completion notification.

Then rerun the full gate. **Max 2 rounds per lane** — then stop and escalate, or switch to `/turbocharge:debug` when the cause isn't obvious.

## Step 6: Reviewed Mode (`--reviewed`)

For security-sensitive code, unfamiliar codebases, or complex integrations. Reviews run **per lane**, not per task:

1. **Before the lane starts** — before spawning its builder or starting its first inline task — record `BEFORE_SHA=$(git rev-parse HEAD)` for that lane.
2. **After the lane finishes** and its builder's completion notification has arrived, dispatch one task-reviewer (Sonnet) with:
   - Plan file path + the lane's task line ranges (the reviewer reads the plan directly — do NOT paste requirements)
   - The lane's diff: `git diff $BEFORE_SHA..HEAD -- <lane paths>`. Lanes own disjoint files, so the pathspec isolates this lane even though other lanes' commits interleave in the range.
   - Working directory. Do NOT send the builder's narrative report — the reviewer reads the diff, not claims.
3. Then wait for its completion notification and apply the disposition.

The reviewer returns two verdicts: `Spec: ✅ / ❌` and `Quality: Approved / Issues found / N/A` (N/A when Spec is ❌ — quality isn't assessed on code that will be rewritten), then its `Declined to judge:` lines.

If `turbocharge:task-reviewer` is not registered, or there is no Agent tool, review the lane diff yourself against the task-reviewer's checklist and give the same two verdicts plus Declined to judge lines.

**Declined to judge:** rule on every line. If it's in scope, it becomes a finding under the disposition below, graded by its effect on a reasonable user. If it's out of scope, carry it to Step 7 as `set aside: <line>`. A line you skip is a decision nobody saw.

**Disposition:**
- **Spec ❌, or Quality has any 🔴 Critical:** fix only those items — builder lane: `SendMessage` the lane's builder; inline lane: fix in the main session. Then `SendMessage` the same task-reviewer to re-review the new diff. **Max 2 cycles** — escalate to the user if still failing.
- **🟡 Important / 🟢 Minor only:** do NOT loop. Carry them into the completion report (Step 7) so the user decides.

A reviewed lane is complete only after Spec ✅ with no unresolved 🔴 Critical.

## Step 7: Complete

After the full gate is green:
- Report a completion summary, including any carried 🟡/🟢 review findings, and every lane's **Rulings** and concerns (inline lanes too: list the calls you made) so the user can check the decisions taken on their behalf
- Print the final visibility line: `lanes: L (inline I · builder B) · spawns: S · tasks: Y/Y`
- Offer: "Ready for holistic code review?" → chains to `/turbocharge:review`

> Visibility note: the orchestrator cannot read exact token counts. This line is the lane/spawn/task summary (the measurable proxy), NOT a fabricated token number.

## Red Flags — STOP

### Process Violations
| Flag | Problem |
|------|---------|
| Skipping plan review | Missed concerns |
| Skipping builder self-review | Builder has a checklist — use it |
| Spawning a builder for a tiny exact-text lane | ~25k tokens and 30–90 s of cold start to type what the plan already decided — run it inline |
| Running the full suite while builder lanes are in flight | It sees other lanes' half-written files and fails for nothing — run it once at the join |
| Unscoped `git commit`, `git commit -a`, or `git add -A` during overlap | Sweeps another lane's files into your commit — always `git commit -m … -- <this task's files>` |
| Overlapping lanes that share a file or an `After` dependency | Two writers on one file, or a lane built on unfinished work |
| Overlapping lanes in a repo whose commit hooks stash (`.pre-commit-config.yaml`; lint-staged via `.lintstagedrc*`, `package.json`, `.husky/`) | The hook stashes other lanes' in-flight edits mid-write — run lanes one at a time |
| Spawning a new builder for a fix round | The lane's builder still has its context and a warm cache — resume it with `SendMessage` |
| Skipping Reviewed mode for security-sensitive code | Save tokens, lose safety |
| Using Reviewed mode for trivial lanes | Wastes tokens on mechanical checks |
| Retrying a BLOCKED lane twice, or sending a design question to Opus | One Opus retry for a stuck lane; design and destructive questions go to the user |
| With `--checkpoint`, continuing past a lane without approval | The user asked to steer between lanes |
| Fix or review loop >2 cycles | Escalate to user, don't keep retrying |
| Full gate, dependent lane, or reviewer started before a builder's completion notification | Subagents run in the background — the Agent call returning is not the lane finishing. The gate tests a half-written tree; the reviewer diffs a half-written lane |

### Rationalizations That Mean You're Wrong

If you catch yourself thinking any of these, **STOP:**

| Thought | Why It's Wrong |
|---------|----------------|
| "Self-review is enough for this security-sensitive task" | Security tasks need Reviewed mode — self-review misses attack vectors |
| "A builder is safer for this two-line edit" | The plan already made the decision; inline is the same discipline without the spawn |
| "I'll run the full suite now, just to be safe" | Mid-overlap it tests a half-written tree. Targeted tests now, the full gate once at the join |
| "The full gate is overkill for this change" | The 1-line change that broke 47 tests says otherwise |
| "`git commit -a` is quicker" | It commits another lane's half-done work under your message |
| "I'll verify it works manually" | Manual verification is not verification |
| "I can skip domain verification, the task description is clear" | Clear descriptions still use wrong entity names half the time |

## Workflow Position

```
plan → build → review → ship
```
