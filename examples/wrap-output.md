# Example: Wrap Output

This is a sample session wrap produced by `/turbocharge:wrap`.

---

# Session Wrap — 2026-03-19

## Progress
- Completed Stories 1-2 (list and create commands)
- Story 3 (clean) in progress — Task 5 of 6 complete
- All tests passing (14 tests)
- Branch: `feature/worktree-cli`

## Decisions
- **Cobra over urfave/cli**: Better subcommand support, more idiomatic Go
- **No go-git dependency**: Shell out to `git` directly — simpler, fewer deps
- **Table output default**: Users scan tables faster than raw text

## Blockers
- None currently

## Next Steps
1. Complete Task 6 (clean --dry-run flag)
2. Run `/turbocharge:review` for holistic code review
3. Run `/turbocharge:ship` to create PR

## Resume Prompt

Displayed directly in chat for the user to copy:

```
@CLAUDE.md  Continue worktree-cli - Add dry-run flag

Branch: `feature/worktree-cli`

Completed:
- List command with table and JSON output
- Create command with auto-branch creation
- Remove command with safety checks
- Clean command (base implementation)

Next Task: Add --dry-run flag to clean command (Task 6 of 6)
1. Task 6: Add --dry-run flag to clean command
2. Holistic code review
3. Ship

Context Files:
- @docs/plans/2026-03-19-worktree-cli.md (implementation plan)

Decisions to Remember:
- No go-git dep — shell out to git directly
- Cobra for CLI framework

Start With:
/turbocharge:build docs/plans/2026-03-19-worktree-cli.md (continue from Task 6)
```
