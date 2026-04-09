# Claude Code Power User Guide

A practical guide to getting maximum value from Claude Code, based on real usage data from 91 sessions, 1,414 messages, and 179 commits.

## The Core Problem

Claude Code has too many overlapping systems: custom agents, project commands, global rules, plugins, skills. Without a single source of truth, Claude doesn't know which system to follow, and you spend time correcting misunderstandings instead of shipping code.

**The fix:** Use turbocharge as your single orchestration system, backed by focused global rules and practical hooks.

---

## 1. Setup Checklist

### Install turbocharge
```bash
claude plugin marketplace add nicodiansk/turbocharge-marketplace
claude plugin install turbocharge
```

### Run the setup audit
```
/turbocharge:setup
```

This scans your global config and removes conflicts: phantom agents, duplicate commands, competing rules.

### Clean your global config
After setup, you should have:
- `~/.claude/agents/` — empty or minimal (turbocharge agents handle orchestration)
- `~/.claude/rules/common/agents.md` — points to turbocharge, not phantom agents
- No disabled plugins cluttering `settings.json`

---

## 2. The Turbocharge Pipeline

```
brainstorm → story → plan → build → review → ship
                                  ↑               |
                                debug            wrap
```

### When to Enter Where

| Situation | Start Here |
|-----------|-----------|
| Vague idea, need to explore | `/turbocharge:brainstorm` |
| Requirements clear, need stories | `/turbocharge:story` |
| Stories approved, need tasks | `/turbocharge:plan` |
| Plan exists, time to code | `/turbocharge:build` |
| Code done, pre-merge check | `/turbocharge:review` |
| Something's broken | `/turbocharge:debug` |
| Ready to merge or PR | `/turbocharge:ship` |
| Session ending | `/turbocharge:wrap` |

### Iron Laws (Enforced, Not Suggested)

- `NO IMPLEMENTATION WITHOUT UNDERSTANDING REQUIREMENTS FIRST`
- `NO STORY WITHOUT ACCEPTANCE CRITERIA`
- `NO TASK MARKED COMPLETE WITHOUT REVIEW CHAIN VERIFICATION`
- `NO MERGE WITHOUT CODE REVIEW`
- `NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST`
- `NO SESSION END WITHOUT WRAP OFFER`

---

## 3. Global Rules That Matter

These live in `~/.claude/rules/common/` and apply to ALL projects.

### testing.md — Test Autonomy
Claude must run tests without asking permission. After every task, after every refactor, when debugging. Full suite, not just new tests. Regressions are Claude's problem.

### development-workflow.md — Verify Understanding
Before writing any code, Claude must:
1. Read domain models and service classes
2. Confirm entity names, relationships, class names from the codebase
3. Confirm sync vs async, proactive vs reactive
4. Summarize understanding before coding

This prevents the #1 friction: Claude building the wrong thing because it assumed instead of reading.

### coding-style.md — Completion Gate
Before presenting work as "done":
1. Run the FULL test suite (zero regressions)
2. Self-review every changed file
3. Verify naming matches existing conventions
4. Check for wrong entity references, missing imports

### reviews.md — Comprehensive by Default
When asked to review or audit: cover the ENTIRE scope. State total items found, work through ALL of them. No shallow sampling passes presented as full reviews.

---

## 4. Hooks

Hooks are deterministic automation that runs real code at lifecycle events. Unlike rules (which Claude might ignore), hooks enforce behavior.

### Plugin Hooks (in turbocharge)

**SessionStart** — Bootstraps turbocharge awareness at every session start. Reminds Claude which skills exist and includes anti-rationalization Red Flags.

**Stop** — Reminds Claude to offer `/turbocharge:wrap` when sessions end.

### Project Hooks (in `.claude/settings.local.json`)

**PreToolUse guard-git.py** — Blocks dangerous git commands:
- `--no-verify` (never skip pre-commit hooks)
- `--force` push (use normal push)
- `git add -A` or `git add .` (add specific files)
- `git reset --hard` (use stash or soft reset)
- `git clean -f` (be specific about deletions)

### How to Add Your Own

In `.claude/settings.local.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "if": "Bash(git *)",
          "command": "python .claude/hooks/guard-git.py"
        }]
      }
    ]
  }
}
```

Hook scripts receive JSON on stdin, return JSON on stdout. Exit code 0 = allow, exit code 2 = block.

---

## 5. Anti-Rationalization: Why Rules Aren't Enough

Claude will find reasons to skip the process. The most dangerous aren't errors — they're rationalizations that sound reasonable:

| What Claude Thinks | Why It's Wrong |
|-------------------|----------------|
| "This task is simple, skip the review chain" | Simple tasks have the highest rate of missed edge cases |
| "I already know the codebase well enough" | You confused CampaignScript with Prompt last time |
| "Running the full test suite is overkill" | The 1-line change that broke 47 tests says otherwise |
| "The spec review is redundant, I followed the plan" | The spec reviewer exists because builders always think this |
| "Quick fix, investigate later" | Later never comes. Root cause first. |
| "The code looks reasonable, I'll summarize" | Summarizing is not reviewing. Read every line. |

Turbocharge's build, debug, and review skills include Red Flags tables that catch these rationalizations.

---

## 6. Session Workflow

### Starting a Session

1. State what you're working on
2. Claude reads CLAUDE.md + turbocharge bootstrap automatically
3. If implementing: `/turbocharge:plan` or `/turbocharge:build`
4. If exploring: `/turbocharge:brainstorm`
5. If debugging: `/turbocharge:debug`

### During a Session

- Claude runs tests autonomously after each task
- Build runs in 3-task batches with human checkpoints
- Every task goes through builder → spec-reviewer → quality-reviewer
- Correct misunderstandings in real-time (then encode them so they stick)

### Encoding Corrections

**This is the #1 habit that separates power users from everyone else.**

Every time you correct Claude, ask: "Will this come up again?" If yes:
- Domain term → add to CLAUDE.md domain terms
- Convention → add to global rules
- Preference → save as memory file
- Wrong approach → add to relevant Red Flags

30 seconds encoding a correction saves 5-10 minutes next session.

### Ending a Session

1. `/turbocharge:wrap` — captures state, decisions, next steps
2. Wrap encodes session learnings into memory/CLAUDE.md
3. Copy the resume prompt for next session
4. Commit any outstanding changes

---

## 7. Prompting Patterns That Work

These patterns directly address the top friction sources from real usage data.

### Starting a Task — Front-Load Context

**Instead of:** "Implement the autotuning feature"

**Say:** "Implement the autotuning feature. Key context: autotuning = PROACTIVE calibration, not reactive correction. It runs async. Relevant entities: CampaignPrompt and ScoringConfig in src/models/. Check exact class names before starting."

**Template:**
> [Task]. Key context: [the one thing Claude will get wrong]. Relevant files: [2-3 paths]. Constraint: [sync/async, proactive/reactive, which entity owns what].

### After a Correction — Encode Immediately

**Instead of:** Correcting and moving on

**Say:** "Remember that for future sessions" or "Save that to CLAUDE.md domain terms"

Don't wait for wrap. Corrections mid-session should be saved immediately so the current session benefits too.

### Requesting a Review — State Scope and Count

**Instead of:** "Review the code"

**Say:** "Review ALL changed files in this branch against the plan at docs/plans/US-06.md. I expect every file in the diff examined. State the count: 'Reviewed X of Y files.' Flag anything that works but is wrong."

The phrase **"state the count"** forces accountability for completeness.

### Requesting Debugging — Force Investigation First

**Instead of:** "The scoring is wrong"

**Say:** "The scoring endpoint returns 3.2 but expected 7.0 for campaign ID 42. Don't propose fixes yet. Trace the data flow: API endpoint → service → scoring logic → DB query. Tell me where the value diverges from expected."

The phrase **"don't propose fixes yet"** forces investigation before guessing.

### Verifying Completion — Don't Accept Claims

**Instead of:** "Ok sounds good" (when Claude says "that should work")

**Say:** "Actually verify it. Run the test/query/command and show me the output."

### The 5 Sentences to Memorize

1. **Starting a task:** "Before coding, read [files] and tell me your understanding of [entities/relationships]"
2. **After a correction:** "Remember that for future sessions"
3. **Requesting a review:** "Review ALL [N items]. State the count. Don't sample."
4. **Requesting debugging:** "Don't propose fixes yet. Trace the data flow first."
5. **Before accepting 'done':** "Run the full test suite and show me the results"

---

## 8. Using Parallel Agents Effectively

You can run multiple Claude Code sessions simultaneously, but unstructured parallelism causes more problems than it solves.

### Good Parallel Patterns

| Pattern | When to Use |
|---------|-------------|
| Story A in session 1, Story B in session 2 | Stories touch different files/modules |
| Research in session 1, implementation in session 2 | Different phases, no file conflicts |
| `/turbocharge:build` multi-track mode | Independent tasks within same plan |
| Review in session 1, next story planning in session 2 | No file overlap, different pipeline stages |

### Bad Parallel Patterns (Avoid)

| Pattern | Why It Fails |
|---------|-------------|
| Two sessions modifying same files | Merge conflicts, one session's work gets lost |
| Two sessions running pytest simultaneously | Resource contention, flaky results |
| Two sessions without defined scope boundaries | Claude in session 2 reads stale state from session 1 |
| Parallel sessions with vague tasks | Both sessions assume they own the same code |

### How to Prompt for Parallel Work

**Be explicit about file ownership:**
> "Implement US-06, US-07, and US-08 in parallel. US-06 touches ONLY src/scoring/. US-07 touches ONLY src/prompts/. US-08 touches ONLY src/translation/. They share NO files. Use multi-track build."

**For worktree-based parallelism:**
> "Create isolated worktrees for each story. Each builder works in its own worktree. Run the full test suite in each worktree independently. Only surface to me when all tests pass."

**Key rule:** If you can't clearly state which files each parallel track owns, don't parallelize. Run sequentially instead.

---

## 9. Session Scoping

### Define Exit Criteria Before Starting

**First message of every session:**
> "This session: complete tasks 1-4 of the plan. If we finish early, we move to task 5. If we're behind, we wrap at task 4 and carry forward."

### The Math

From real data: 32% of sessions ended as "Mostly Achieved" — meaning ~1 in 3 sessions didn't finish what was planned. Each carryover task loses context between sessions, which feeds back into the misunderstanding problem.

**Cap at 4 tasks.** Finishing 4 cleanly is worth more than starting 7 and carrying 3 forward.

### When to Stop and Wrap

- You've completed your defined scope → wrap
- Context is getting long (Claude starts forgetting earlier decisions) → wrap
- You've hit a blocker that needs research → wrap, do research separately
- You've been correcting Claude repeatedly on the same concept → encode the correction, then wrap

---

## 10. What NOT to Do

### Don't run multiple orchestration systems
Pick turbocharge. Remove competing agents and commands. One system, clear handoffs.

### Don't scope sessions too ambitiously
4 fully completed tasks beats 7 partially completed ones. Carryover creates context loss.

### Don't accept shallow reviews
If Claude audited 78 of 1,488 tests and called it done, that's not a review. Call it out. The reviews.md rule helps, but you're the last line of defense.

### Don't skip the pipeline
"Just write the code" is how you get buggy first passes that need 2-3 fix rounds. The plan → build → review chain exists because building without it is slower, not faster.

### Don't carry corrections in your head
If you told Claude something important, write it down somewhere Claude will read it next time. Your memory is not persistent storage.

---

## 11. Configuration Reference

### Global Settings (`~/.claude/settings.json`)
- `model`: Your preferred model
- `enabledPlugins`: turbocharge + utility plugins (Context7, Notion, etc.)
- `permissions.allow`: Pre-approved tool patterns (pytest, etc.)
- `alwaysThinkingEnabled`: Extended thinking for deep reasoning

### Global Rules (`~/.claude/rules/common/`)
| File | Purpose |
|------|---------|
| `agents.md` | Points to turbocharge as the primary system |
| `testing.md` | TDD workflow + test autonomy |
| `development-workflow.md` | Feature pipeline + verify understanding |
| `coding-style.md` | Immutability + completion gate |
| `reviews.md` | Comprehensive reviews by default |
| `git-workflow.md` | Commit format + PR process |
| `security.md` | Mandatory security checks |
| `patterns.md` | Repository pattern, API response format |
| `performance.md` | Model selection strategy |
| `hooks.md` | Hook type documentation |

### Project Settings (`.claude/settings.local.json`)
- Project-specific permissions
- Project-specific hooks
- MCP server configuration

### Turbocharge Plugin
- 9 skills (setup, brainstorm, story, plan, build, review, debug, ship, wrap)
- 6 agents (builder, planner, researcher, spec-reviewer, quality-reviewer, code-reviewer)
- SessionStart + Stop hooks
- Anti-rationalization Red Flags

---

## 12. Metrics to Watch

From the Insights report, track these to measure improvement:

| Metric | Target | Why |
|--------|--------|-----|
| Fully Achieved sessions | >75% (was 64%) | Tighter scoping + better understanding |
| Buggy Code friction | <10/month (was 23) | Completion gate + review chains |
| Misunderstood Request | <5/month (was 19) | Domain verification + persistent corrections |
| Wrong Approach | <5/month (was 20) | Front-loading understanding + Red Flags |
| Command Failed errors | <100/month (was 195) | Hooks blocking bad commands + better env config |
