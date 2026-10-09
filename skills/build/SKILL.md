---
name: build
description: Use when you have an implementation plan ready to execute. Dispatches builder agents (Sonnet) per task with self-review. Opt-in review (single Sonnet task-reviewer, two verdicts) for high-risk tasks. Supports single-track and multi-track parallel execution.
argument-hint: "[plan-file] [--reviewed] [--checkpoint=N]"
---

# Build

Execute an implementation plan with builder agents and automated review chains.

**Announce:** "Using build to execute this plan."

## The Iron Law

```
NO TASK MARKED COMPLETE WITHOUT BUILDER SELF-REVIEW AND PASSING TESTS
```

## Step 1: Load and Review Plan

1. Read the plan file at $ARGUMENTS
2. Review critically — identify concerns or questions
3. If concerns: raise them before starting
4. Count tasks, identify dependencies, determine execution mode
5. Check if `--reviewed` is in $ARGUMENTS — if so, enable review chain for all tasks
6. Parse `--checkpoint=N` from $ARGUMENTS (default `N=3`). `--checkpoint=0` or `--no-checkpoint` disables the human-wait between batches (use only for small/low-risk plans).

## Step 2: Choose Execution Mode

**Standard** (default): Builder implements each task with self-review. No separate reviewer agents.
- Spawn builder (Sonnet) per task
- Builder self-reviews using its built-in checklist
- Batches of N tasks (default 3, set via `--checkpoint=N`) with a human checkpoint; `--checkpoint=0` runs straight through with no wait

**Reviewed** (`--reviewed` flag, or user says "with reviews"): For high-risk, security-sensitive, or unfamiliar codebases.
- Same as Standard, plus: one task-reviewer (Sonnet) after each task — reads the diff once and emits two verdicts (Spec + Quality)
- Leaner dispatch: pass plan file path + task line range + git diff only — no narrative summaries
- Max 2 review cycles per task — escalate to user if unresolved

**Multi-track**: Independent tasks that can be parallelized (e.g., FE + BE).
- Spawn Agent Team with specialized builders
- Each builder owns a set of non-overlapping files
- Builders communicate via shared task list
- Per-task review (`--reviewed`) is NOT supported in multi-track — parallel, interleaved commits make per-task `BEFORE_SHA..HEAD` diff ranges unreliable. Run `/turboflow:review` after the team completes for a holistic diff review instead.
- Requires user confirmation before spawning team

**How to decide:**
- Default to Standard — covers 80% of tasks
- Use Reviewed for: unfamiliar codebase, security-sensitive code, complex integrations
- Use Multi-track for independent tracks touching different files
- When in doubt, start Standard — user can always run `/turboflow:review` after

**Ask the user** if the choice isn't obvious.

## Step 3: Execute — Standard

For each task in the batch (default 3 tasks):

### 3a. Dispatch Builder
Spawn builder subagent (Sonnet) with:
- Task number and description (objective, file paths, line ranges, verification commands)
- Plan file path and task line range — do NOT paste plan content, builder reads the file directly
- Context: where this task fits in the sequence, what previous tasks completed
- Working directory
- Prefix: `@CLAUDE.md` (conventions) — or `@AGENTS.md` if the project has no CLAUDE.md. If the project keeps it at `.claude/CLAUDE.md`, use `@.claude/CLAUDE.md` instead. Do NOT inject `@ATLAS.md` — builders read the spec and diff, not the navigation index.

Dispatch the builder **without** a `name` parameter. A named Agent spawn joins the session's implicit team as a teammate when Agent Teams are enabled (Step 5); single-track builders must stay plain subagents.

In **Reviewed** mode, record the pre-task SHA before dispatching: `BEFORE_SHA=$(git rev-parse HEAD)`. The task-reviewer diffs `$BEFORE_SHA..HEAD` to capture exactly this builder's output, regardless of how many commits (zero, one, or many) the builder makes.

> **Builder isolation (design decision):** the builder agent intentionally does NOT set `isolation: worktree`. A worktree branches from the **default branch**, not the parent session's HEAD, and is auto-cleaned only when no changes are made — which would break this skill's `BEFORE_SHA=$(git rev-parse HEAD)` → `$BEFORE_SHA..HEAD` diff model (the reviewer would diff the wrong base) and would leave a populated, non-auto-cleaned worktree for ship/cleanup to manage. Worktree/branch management therefore stays in skill prose and the parent session, not in the agent frontmatter.

### 3b. Wait for the Completion Notification

Subagents run in the background (Claude Code 2.1.198+): the Agent call returns as soon as the builder starts, not when it finishes. After every dispatch, **stop and wait for that builder's completion notification.** Until it arrives, do NOT:
- dispatch the next builder,
- capture the next `BEFORE_SHA`,
- dispatch a task-reviewer (Step 4a), or
- mark the task complete.

The same rule holds for every task-reviewer dispatch, researcher dispatch, and builder resume (fix rounds): act on a subagent's result only after its completion notification arrives.

### 3c. Mark Task Complete

### 3d. After Batch (every N tasks, default 3)

Report to human:
- What was implemented in this batch
- Current progress (N of M tasks complete)
- Visibility: `agents spawned: A · models: sonnet×A · tasks: X/Y`

Say: **"Batch complete. Ready for feedback."**

**Wait for human approval before next batch.**

> If `--checkpoint=0`, skip the wait and continue to the next batch automatically.

## Step 4: Execute — Reviewed

For each task in the batch, run this exact ordered sequence. **The task is not marked complete until its review passes** — never mark complete straight after the builder (that is the Step 3 flow, not this one):

1. **Dispatch builder** — same as Step 3a. In Reviewed mode, record `BEFORE_SHA=$(git rev-parse HEAD)` *before* dispatching (Step 3a) so the reviewer diffs exactly this builder's output. Then wait for the builder's completion notification (Step 3b).
2. **Dispatch task-reviewer** (Step 4a), wait for its completion notification, then apply the disposition — loop the builder if Spec ❌ or any 🔴 Critical (max 2 cycles).
3. **Dispatch researcher on demand** (Step 4b) only if the builder blocked on unclear context.
4. **Mark the task complete** (Step 4c) — only after Spec ✅ with no unresolved 🔴 Critical.
5. **After every N tasks, run the batch checkpoint** (Step 4d).

The sub-steps below detail each stage:

### 4a. Dispatch Task Reviewer
Spawn one task-reviewer subagent (Sonnet) with:
- Plan file path + task line range (reviewer reads the plan directly — do NOT paste requirements)
- Git diff range for the task: `git diff $BEFORE_SHA..HEAD` (the SHA captured in Step 3a). Do NOT use `HEAD~1..HEAD` — it reviews the wrong code when a task makes zero or multiple commits.
- Working directory to read actual code
- Do NOT send the builder's narrative report — the reviewer reads the diff, not claims

The reviewer returns two verdicts:
- `Spec: ✅ / ❌`
- `Quality: Approved / Issues found / N/A` — N/A when Spec is ❌ (spec must pass before quality is assessed, so quality isn't wasted on code that will be rewritten)

**Disposition:**
- **Spec ❌:** Resume the builder with the spec gaps only (ignore quality — it's N/A), then re-review. **Max 2 cycles** — escalate to user if still failing.
- **Spec ✅, Quality has any 🔴 Critical:** Resume the builder with the Critical findings **only**, then re-review. **Max 2 cycles.** Any 🟡 Important / 🟢 Minor findings that co-occur in the same review are NOT fixed in this loop — carry them forward to the next batch checkpoint (Step 4d) exactly as the bullet below does. Do not let them vanish just because a Critical was present.
- **Spec ✅, Quality has only 🟡 Important / 🟢 Minor:** Do NOT loop. Carry these concerns into the next batch checkpoint (Step 4d) so the user decides whether to address them.

### 4b. Dispatch Researcher (on demand)
If the builder blocks on unclear context, dispatch the researcher with `@ATLAS.md @CLAUDE.md` prefixed — or `@ATLAS.md @AGENTS.md` if the project has no CLAUDE.md. If the project keeps it at `.claude/CLAUDE.md`, use `@.claude/CLAUDE.md` instead. Subagents do not inherit parent history — `@ATLAS.md` must ride on the dispatch prompt itself.

### 4c. Mark Task Complete

### 4d. After Batch (every N tasks, default 3)

Report to human:
- What was implemented in this batch
- Review results (issues found and fixed)
- Accumulated 🟡 Important / 🟢 Minor quality concerns not yet addressed (from Step 4a)
- Current progress (N of M tasks complete)
- Visibility: `agents spawned: A · models: sonnet×A · tasks: X/Y`

Say: **"Batch complete. Ready for feedback."**

**Wait for human approval before next batch.**

> If `--checkpoint=0`, skip the wait and continue to the next batch automatically.

## Step 5: Execute — Multi-Track (Agent Teams)

> **Experimental & gated.** Agent Teams require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (env var or `settings.json`). If unset, fall back to Standard mode and tell the user. There are no team-management tool calls: each session has one implicit team, and any Agent spawn that passes a `name` joins it as a teammate. Teammates clean up automatically at session end.

### 5a. Confirm with User
```
This plan has independent tracks that could run in parallel:
- Track A: [description] (Tasks X, Y, Z)
- Track B: [description] (Tasks A, B, C)

Spawn an Agent Team (experimental, needs CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)?
This uses more tokens but is faster.
```

### 5b. Spawn Teammates
- Spawn each teammate with the Agent tool: `subagent_type: turboflow:builder` plus a `name` per track (e.g. `track-a`). The `name` is what makes the spawn a teammate, and it is why single-track builders (Step 3a) are dispatched without one.
- Since Claude Code 2.1.288, a plugin agent spawned by name as a teammate keeps its own definition. It always keeps its `model` (Sonnet) and `tools`. In-process teammates, the default, also keep its `disallowedTools`, `effort` and prompt body. That is why multi-track teammates still behave like the **builder** agent. Do NOT name a model in the teammate's spawn prompt, because a model named there overrides the definition's Sonnet pin. The definition's `skills` are never applied, and `mcpServers` applies only to split-pane teammates, so give each teammate the context it needs in its spawn prompt.
- Assign each teammate a non-overlapping set of files (file ownership) so parallel, interleaved commits never touch the same path.
- Teammates self-review per task; per-task reviewers are NOT dispatched in multi-track (see Step 2) — holistic review comes after via `/turboflow:review`.
- Per-task `--reviewed` remains unsupported in multi-track: interleaved commits make `BEFORE_SHA..HEAD` ranges unreliable.
- Cleanup is automatic at session end — there is nothing to tear down manually.

## Step 6: Complete

After ALL tasks done:
- Report completion summary
- Print final visibility line: `agents spawned: A · models: sonnet×A · tasks: Y/Y`
- Offer: "Ready for holistic code review?" → chains to `/turboflow:review`

> Visibility note: the orchestrator cannot read exact token counts. This line is the spawn/model/task summary (the measurable proxy), NOT a fabricated token number.

## Red Flags — STOP

### Process Violations
| Flag | Problem |
|------|---------|
| Skipping plan review | Missed concerns |
| Skipping builder self-review | Builder has a checklist — use it |
| Skipping Reviewed mode for security-sensitive code | Save tokens, lose safety |
| Using Reviewed mode for trivial tasks | Wastes tokens on mechanical checks |
| Guessing through blockers | Should stop and ask |
| No batch reporting | Human can't review progress |
| Auto-continuing after batch | Must wait for human approval |
| Review loop >2 cycles | Escalate to user, don't keep retrying |
| Next builder/reviewer dispatched before the previous subagent's completion notification | Subagents run in the background — the Agent call returning is not the task finishing. Builders race on one tree; the reviewer diffs a half-written task |

### Rationalizations That Mean You're Wrong

If you catch yourself thinking any of these, **STOP:**

| Thought | Why It's Wrong |
|---------|----------------|
| "Self-review is enough for this security-sensitive task" | Security tasks need Reviewed mode — self-review misses attack vectors |
| "I'll skip the batch checkpoint, we're on a roll" | Human oversight exists for a reason — never skip |
| "Running the full test suite is overkill for this change" | The 1-line change that broke 47 tests says otherwise |
| "I'll verify it works manually" | Manual verification is not verification |
| "Let me just finish this batch and review later" | Later never comes. Checkpoint every batch. |
| "I can skip domain verification, the task description is clear" | Clear descriptions still use wrong entity names half the time |

## Workflow Position

```
plan → build → review → ship
```
