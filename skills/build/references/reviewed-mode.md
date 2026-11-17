# Build: Reviewed Mode (`--reviewed`)

Build Step 1 reads this file when `--reviewed` is set, before any lane starts. Step numbers below are build's (`SKILL.md`).

For security-sensitive code, unfamiliar codebases, or complex integrations. Reviews run **per lane**, not per task:

1. **Before the lane starts:** a builder lane's `BEFORE_SHA` is its `LANE_SHA` (Step 3); an inline lane records `BEFORE_SHA=$(git rev-parse HEAD)` before its first task.
2. **After the lane finishes** and its builder's completion notification has arrived, dispatch one task-reviewer (Sonnet, on Opus lanes too: it reviews a diff against a plan) with:
   - Plan file path + the lane's task line ranges (the reviewer reads the plan directly — do NOT paste requirements)
   - The lane's diff: `git diff $BEFORE_SHA..HEAD -- <lane paths>`. Lanes own disjoint files, so the pathspec isolates this lane even though other lanes' commits interleave in the range. Run it as the join checks say (Step 5): in `bash`, with the SHA and the paths written out.
   - Working directory. Do NOT send the builder's narrative report — the reviewer reads the diff, not claims.
3. Then wait for its completion notification and apply the disposition.

The reviewer returns two verdicts: `Spec: ✅ / ❌` and `Quality: Approved / Issues found / N/A` (N/A when Spec is ❌ — quality isn't assessed on code that will be rewritten), then its `Declined to judge:` lines.

If `turbocharge:task-reviewer` is not registered, or there is no Agent tool, review the lane diff yourself against the task-reviewer's checklist and give the same two verdicts plus Declined to judge lines.

**Declined to judge:** rule on every line. If it's in scope, it becomes a finding under the disposition below, graded by its effect on a reasonable user. If it's out of scope, carry it to Step 7 as `set aside: <line>`. A line you skip is a decision nobody saw.

**Disposition:**
- **Spec ❌, or Quality has any 🔴 Critical:** fix only those items — builder lane: `SendMessage` the lane's builder; inline lane: fix in the main session. Then `SendMessage` the same task-reviewer to re-review the new diff. **Max 2 cycles** — escalate to the user if still failing.
- **🟡 Important / 🟢 Minor only:** do NOT loop. Carry them into the completion report (Step 7) so the user decides.

A reviewed lane is complete only after Spec ✅ with no unresolved 🔴 Critical.
