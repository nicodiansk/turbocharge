---
name: build
description: "Use when a written implementation plan is ready to execute: the docs/plans/ file /turbocharge:plan just saved, or a plan path the user names ('build the plan', 'implement docs/plans/x.md', a go-ahead right after a plan). Runs each lane inline or with one builder, overlaps independent lanes and runs the full suite once; --reviewed adds a per-lane review. Without a plan file, plan first."
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

1. Parse flags from $ARGUMENTS: `--inline` / `--delegate` (Step 2), `--reviewed` (Step 6: read `references/reviewed-mode.md` in this skill's directory now, before any lane starts), `--checkpoint` (human wait after each lane; off by default). Legacy forms: `--checkpoint=N` means `--checkpoint`; `--checkpoint=0` and `--no-checkpoint` mean no pauses, the default. What remains is the plan path. With no path, take the one in this session's plan `Next:` line; failing that, ask the user which plan, offering the newest `docs/plans/*.md`.
2. Read the plan file. Line 1 is `<!-- plan: in progress -->` → the planner stopped before finishing: don't build it; offer `/turbocharge:plan <path>`, which resumes it.
3. Review critically — identify concerns or questions
4. If concerns: raise them before starting
5. Read the plan's **Lanes table** (`| Lane | Owns files | Tasks | After | Executor | Effort | Model |`), columns by header name. A valid Model cell is `sonnet`, `opus · <reason>` with one of the four words (`concurrency`, `security`, `irreversible`, `edge-cases`), or `—`. A six-column table (no Model column) → every builder lane is `sonnet`. Any other value, or an `opus` cell whose reason isn't one of the four → a plan concern (item 4), and the lane reads as `sonnet` unless the user says otherwise. `opus` on a lane whose Executor is `inline` → a plan concern too; the lane runs inline, on the session's model. **No Lanes table** (a legacy plan) → treat the whole plan as one sequential lane and route it in Step 2 like any other.

## Step 2: Route Lanes

Each lane runs one of two ways:

| Executor | Who runs it | Use for |
|----------|-------------|---------|
| `inline` | The main session, task by task | Mechanical lanes: content edits, exact text given, ≤3 tasks |
| `builder` | One builder for the whole lane, on the lane's model: Sonnet, or Opus on lanes the plan marks | Real logic, unfamiliar code, judgment calls |

Start from the plan's Executor hint, then override:
- → `builder` when the lane holds real application logic (functions, classes, control flow) or a design question the plan left open.
- → `inline` when the lane is only a few exact-text edits. A builder spawn costs ~25k tokens and 30–90 s before it writes a line.
- `--inline` runs every lane inline; `--delegate` gives every lane a builder.
- If a lane's route isn't obvious, ask the user.

**Model** is a hint, like Executor. Build may raise or lower a lane's model only with the reason in the routing announcement. An `opus` lane that is only exact-text edits goes inline and loses its model. `--inline` ignores the Model column. `--delegate` keeps each lane's value; a lane that was inline (`—`) gets `sonnet`, as does a lane Step 2 promotes to a builder, with no plan concern: `—` is a valid cell, not an unknown value.

**No agents here:** if the Agent tool is missing, or a dispatch fails because `turbocharge:builder` is not registered (some surfaces load skills without agents), run every builder lane inline (Step 4), one lane at a time, and say once: `agents unavailable — running lanes inline`.

**Overlap:** lanes with no `After` path between them run at the same time — builder lanes in the background while the main session works the inline lanes. A lane with `After` starts only when every lane it names has finished (Step 5). At most 3 builder lanes run at once: a fourth that is ready waits for a slot (Step 5). The cap covers plans written before 3.7.0 or by hand, and `--delegate`, which makes every lane a builder lane. Inline lanes don't count. Opus lanes count toward the cap.

**No overlap with stashing commit hooks:** if the project's commit hooks stash unstaged changes, run lanes one at a time. Check for the `pre-commit` framework (`.pre-commit-config.yaml`) and lint-staged — `.lintstagedrc*`, `lint-staged.config.*`, a `lint-staged` key in `package.json`, or a `.husky/` hook that runs it. A pathspec commit leaves every other lane's in-flight edits unstaged, and the hook would stash them out from under that lane.

Announce the routing before executing:
```
lanes: 3 (inline 1 · builder 2)
  plan-format   inline                             tasks 1–2
  hook-cleanup  builder (medium · sonnet)          tasks 6–8   ← background
  git-guard     builder (high · opus · security)   tasks 9–12  ← background
```

## Step 3: Spawn Builder Lanes

For each builder lane that is ready (its `After` lanes are done) and has a slot (Step 2), spawn one builder — subagent type `turbocharge:builder` — with:
- **`effort`** set on the Agent call from the lane's Effort column (default `medium`). The per-spawn value overrides the agent definition.
- **`model`**: an `opus` lane spawns with `model: opus` on the Agent call; a `sonnet` lane passes no `model`, so the builder file's `model: sonnet` applies. If that spawn fails because Opus isn't available (account or provider), spawn the same lane with no `model` and say `opus unavailable — lane <name> on sonnet`. Build remembers it for the rest of the run: later `opus` lanes spawn on Sonnet directly, each named once by the same line. An `opus` alias that resolves to an older Opus on another provider spawns fine and is not a failure.
- Plan file path, lane name, and its task line ranges — do NOT paste plan content; the builder reads the file directly
- Working directory
- Prefix: `@CLAUDE.md` (conventions) — or `@AGENTS.md` if the project has no CLAUDE.md. `.claude/CLAUDE.md` counts as a CLAUDE.md: if the project keeps it there, use `@.claude/CLAUDE.md`. Do NOT inject `@ATLAS.md` — builders read the spec and diff, not the navigation index.
- **Lane rules**, stated in the prompt:
  - Touch only the lane's files. Never stage, stash, reset, or check out anything else.
  - Per task: RED → GREEN on that task's own test. Do NOT run the full suite — other lanes are mid-edit, so it would see their half-written files.
  - Commit per task, scoped to the task: `git add <new files>` (a pathspec commit can't take untracked files), then `git commit -m "<message>" -- <this task's files>` — the paths the task created, changed, deleted, or renamed. Don't pass the whole lane: a lane path that doesn't exist yet makes the commit fail. Never `git commit -a` or `git add -A`.
  - If git reports `index.lock`, wait a moment and retry once.
  - Report per task: commit SHA and test result; then `Not done:` and `Mutation:`; then Rulings; then the Status line (builder.md's Report Format).
- **One `Mutation:` line**, from the plan's Review Focus:
  - `Mutation: Task N — <Review Focus line>` when the lane owns a task a Review Focus line pins `(pinned: Task N)`. With several, the first: Review Focus lists the most likely input first.
  - `Mutation: lane` with `--reviewed` and no pin in the lane: the builder picks the lane's main behavior.
  - `Mutation: no` otherwise, a legacy plan with no Review Focus included.

  The builder reads only this line, never build's flags.

Dispatch each builder **without** a `name` parameter. A named Agent spawn joins the session's implicit team as a teammate when Agent Teams are enabled; lane builders must stay plain subagents. Note each builder's agent ID against its lane — with no `name`, `SendMessage` fix rounds (Steps 5c and 6) address it by agent ID.

Before a lane's first builder spawns, record `LANE_SHA=$(git rev-parse HEAD)` for that lane, with or without `--reviewed`. The join checks (Step 5) and Step 6 diff from it. Shell variables don't survive between Bash calls, so note the SHA in your reply and write the SHA itself into each later command (`LANE_SHA=<sha>` at its top).

Builders run in the background (Claude Code 2.1.198+): the Agent call returns as soon as the builder starts. Do not wait here — go to Step 4.

> **Builder isolation (design decision):** the builder agent intentionally does NOT set `isolation: worktree`. A worktree branches from the **default branch**, not the parent session's HEAD, and is auto-cleaned only when no changes are made — which would break the `$BEFORE_SHA..HEAD` diff model in Step 6 (the reviewer would diff the wrong base) and leave a populated worktree for ship/cleanup to manage. Lanes share one tree and stay apart by owning disjoint files and committing by pathspec.

If a builder reports `Blocked on: context` (Step 5), dispatch the researcher with `@ATLAS.md @CLAUDE.md` prefixed — or `@ATLAS.md @AGENTS.md` if the project has no CLAUDE.md. `.claude/CLAUDE.md` counts as a CLAUDE.md: if the project keeps it there, use `@.claude/CLAUDE.md`. Subagents do not inherit parent history — `@ATLAS.md` must ride on the dispatch prompt itself.

## Step 4: Run Inline Lanes

While builder lanes run, the main session works through the inline lanes, task by task. With `--reviewed`, record the lane's `BEFORE_SHA` first (Step 6), before its first task.
1. Read the task's Decision and Test assertions from the plan. Its line ranges are plan-time hints: if an earlier task in the lane shifted the code, find it by content. When the task has `Like:`, read the target and its tests first and follow its shape (names, error handling, test layout). Where the new code has to differ, list `Like <target> · differs: <how> · <why>` in Step 7's Rulings. A target that no longer resolves: find it by content; if it's gone, build from the Decision and list `Like <target> · not found · built from the Decision`.
2. Write the test from the assertions and run it — it must fail on an assertion about the result, for the reason the task names (RED). An import error, a missing name or a syntax error is not RED: add a stub that returns a neutral value (empty, zero, `None`), rerun, and the test now fails on its assertion. A test that expects an error is RED when the error doesn't come.
3. Implement the Decision. Run the test — GREEN.
4. Commit by pathspec: `git add <new files>`, then `git commit -m "<message>" -- <this task's files>`.

Inline lanes follow the same lane rules: only the lane's files, no full suite while builder lanes are in flight.

Never, in an inline lane:
- skip, mark xfail, delete or weaken a test (a looser assertion, fewer cases);
- write the expected value into the code;
- special-case the test's input;
- change a test to match the code.

Two exceptions. **The plan's Decision changes the behavior an existing test checks** → update that test and list it in Step 7's Rulings: the test · the old expectation → the new one · the task. **A test can't pass within the lane's files** → take it to the user, and never weaken the test.

Inline lanes run no mutation and no join checks: they are exact-text edits, and the main session saw their test output itself. Builder lanes run inline because agents are unavailable skip both too: the main session saw their output, and the fallback stays as light as an inline lane.

## Step 5: Join

**When a builder's completion notification arrives,** read the last line of its report, `Status: DONE | DONE_WITH_CONCERNS | BLOCKED`, and its `Blocked on:` kind:
- **DONE** → run the join checks (below); the lane is finished when they pass.
- **DONE_WITH_CONCERNS** → run the join checks; the lane is finished when they pass, and it still carries its concerns to Step 7.
- **DONE or DONE_WITH_CONCERNS with no `Not done:` line** → DONE_WITH_CONCERNS, with `Not done: not reported`. A BLOCKED report follows its `Blocked on:` kind below, with or without the line.
- **`DONE` with a `Not done:` other than `none`** → DONE_WITH_CONCERNS, the line carried to Step 7.
- **BLOCKED on destructive, security, outside or design** → take the question to the user. Don't decide it for them. The lane frees its slot, so start the next waiting builder lane (point 3, below).
- **BLOCKED on context** → dispatch the researcher (Step 3), then resume the same builder with `SendMessage`, carrying its findings. Adding context is a change, so the same model is fine, whatever its model, and the builder's context is warm.
- **BLOCKED on stuck**, or `Status: BLOCKED` again after a context resume, splits by the model the lane actually ran on. A lane that started on Opus (the plan's `opus`, or raised in Step 2) goes to the user with its BLOCKED report, with no retry, like the other BLOCKED kinds; it frees its slot. When Opus is unavailable this run (Step 3), a stuck Sonnet lane goes to the user too: never the same model with nothing changed. Otherwise a lane that ran on Sonnet → retry the lane once with a new Agent call: `subagent_type: turbocharge:builder`, `model: opus`, the same lane, naming the tasks already committed and quoting the BLOCKED report. The retry keeps the lane's `LANE_SHA` and carries the same `Mutation:` line: a new `LANE_SHA` would leave the first builder's commits out of check 2's count. `SendMessage` can't change the model. Never retry the same model with nothing changed. A BLOCKED Opus retry goes to the user.
- **No Status line** → treat it as DONE_WITH_CONCERNS and run the join checks. They replace any look through `git log` of your own.

**Join checks, builder lanes only.** On a builder lane's DONE or DONE_WITH_CONCERNS, before `lane ✓`, run four checks on the lane's paths (its Owns files):

| # | Check | Command | When it fails |
|---|-------|---------|---------------|
| 1 | Nothing left uncommitted | `git status --porcelain -- <lane paths>` prints nothing | Fix round: "commit these, or say why" |
| 2 | At least one commit per task | `git rev-list --count $LANE_SHA..HEAD -- <lane paths>` ≥ the lane's task count | A concern, carried to Step 7 |
| 3 | No test shortcuts | Check 3's grep, below | Build rules on each hit (below) |
| 4 | The lane's tests are green | Rerun every task's `Verify`, each distinct command once | Fix round with the failing output |

- With no Lanes table (a legacy plan), the lane paths are every path the plan's tasks name, and check 2 counts all its tasks.
- Check 2 counts at least, not equal: the mutation's `test: …` commit or a task split in two is extra; a missing commit is the hole.
- Run the checks in `bash`, with the lane paths written out or in a bash array (`"${P[@]}"`). zsh doesn't split an unquoted variable: a `$P` holding several paths reaches git as one path that doesn't exist, and checks 1 and 3 then pass on nothing. A check 2 count of 0 for a lane that reported commits means the paths are wrong or `$LANE_SHA` is empty (`..HEAD` is an empty range, so check 3 finds nothing too): fix them before trusting checks 1 and 3.
- Fix rounds count toward Step 5c's max 2 per lane. After a round, rerun all four checks. Lanes that name this one in `After` wait until the checks pass.
- Cost: three git commands and one `Verify` per task, touching only the lane's tests, so it is safe during overlap.

**Check 3: no test shortcuts.** Grep the lane's added lines, and list any file it deleted:
```bash
SHORTCUT_RE='skip\(|skipIf|skipUnless|mark\.skip|xfail|expectedFailure|\.only\(|[^[:alnum:]_]xit\(|xdescribe\(|fdescribe\(|\.Skipf?\(|#\[ignore\]|@Disabled|@Ignore|sys\.exit\(0\)|process\.exit\(0\)|os\.Exit\(0\)'
git diff $LANE_SHA..HEAD -- <lane paths> | grep -E '^[+]' | grep -vE '^[+]{3} ' | grep -E "$SHORTCUT_RE"
git diff --diff-filter=D --name-only $LANE_SHA..HEAD -- <lane paths>
```
Three stages, not one pattern: added lines, minus the `+++ ` file headers, then the keywords, so a keyword right after the `+` still hits. A shell test's `exit 0` ends every shell test, and a focused `fit(` would hit every `model.fit(`, so both are left to the reviewers. Read each hit. A real shortcut, or a deleted file the plan doesn't name, gets a fix round. A legitimate line (a skip when a tool is missing, a deletion the plan names) gets a Step 7 note: `shortcut check: <line> — <why it's legitimate>`.

**After every lane finishes** — an inline lane's last commit, or a builder lane whose join checks pass:
1. Report one line: `lane <name> ✓ · tasks a–b · commits N · files checked` for a builder lane, and `lane <name> ✓ · tasks a–b · commits N` for an inline lane, where no checks ran.
2. With `--checkpoint`, stop and wait for human approval before starting anything new.
3. Start every lane whose `After` lanes have all finished: an inline lane at once (Step 4), a builder lane while fewer than 3 builder lanes are running (Step 3). The rest wait, in plan order, for the next builder lane whose join checks pass. A builder lane holds its slot from its spawn until its join checks pass. One that stops BLOCKED with its question at the user frees its slot, and takes the next free slot once the user answers, before lanes still waiting; a context resume and the Opus retry keep theirs.

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
- **A file no lane owns** (usually a cross-lane regression: a lane changed code that an untouched test exercises): route it to the lane whose change the failure points to, as above. Every lane has finished, so that lane may edit the file for this fix: say so when you resume it, and list the file under its Rulings in Step 7. If no lane's change explains the failure, fix it in the main session, or ask the user when the fix would change what a lane built.

Then rerun the full gate. **Max 2 rounds per lane** — then stop and escalate, or switch to `/turbocharge:debug` when the cause isn't obvious.

## Step 6: Reviewed Mode (`--reviewed`)

For security-sensitive code, unfamiliar codebases, or complex integrations: one task-reviewer per lane, after the lane finishes. Its procedure (dispatch, verdicts, Declined to judge, disposition) is in `references/reviewed-mode.md` in this skill's directory, which Step 1 reads when `--reviewed` is set. Two facts the other steps rely on: a builder lane's `BEFORE_SHA` is its `LANE_SHA` (Step 3), and an inline lane records `BEFORE_SHA=$(git rev-parse HEAD)` before its first task. A reviewed lane is complete only after Spec ✅ with no unresolved 🔴 Critical.

## Step 7: Complete

After the full gate is green:
- Report a completion summary, including any carried 🟡/🟢 review findings, and every lane's **Rulings**, concerns and `Not done:` line, each `shortcut check:` note and each check 2 concern (inline lanes too, where the main session lists its calls and states its own `Not done:`) so the user can check the decisions taken on their behalf
- Print the final visibility line: `lanes: L (inline I · builder B, opus O) · spawns: S · tasks: Y/Y`; O counts builder lanes that ran on Opus at any point (marked, raised, or the stuck retry), always printed, `opus 0` included
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
| Opus on a lane the plan doesn't mark, with no reason in the routing announcement | Opus is for the four kinds the plan names; anything else needs its reason shown |
| Retrying a lane that already ran on Opus | A stuck Opus lane goes to the user; a second attempt repeats the first |
| With `--checkpoint`, continuing past a lane without approval | The user asked to steer between lanes |
| Fix or review loop >2 cycles | Escalate to user, don't keep retrying |
| Marking a builder lane ✓ from its report | A return is a claim: run the four checks on its files first |
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
