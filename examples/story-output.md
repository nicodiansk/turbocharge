# Example: Story Output

This is a sample stories document produced by `/turbocharge:story`.

---

# Epic: CLI Worktree Manager

## Problem Statement
Developers managing multiple git worktrees need a simple CLI to list, create, remove, and clean up worktrees without memorizing verbose git commands.

## Success Metrics
- Reduces worktree management commands from 3-5 to 1
- Zero stale worktrees left behind after cleanup

## Scope
### In Scope
- List worktrees with branch and status
- Create worktrees with sensible defaults
- Remove worktrees safely
- Clean stale worktrees

### Out of Scope
- GUI interface
- Worktree metadata/tagging
- CI/CD integration

## Stories

### Story 1: List worktrees with status

**As a** developer,
**I want** to see all my worktrees with their branch and clean/dirty status,
**So that** I know what I'm working on across branches.

#### Acceptance Criteria

**Criterion 1: Basic listing**
**Given** a repository with 3 worktrees
**When** I run `wt list`
**Then** I see a table with path, branch, and status for each worktree

**Criterion 2: JSON output**
**Given** a repository with worktrees
**When** I run `wt list --json`
**Then** I get valid JSON with the same information

**Story Points: 3**

---

### Story 2: Create worktree with defaults

**As a** developer,
**I want** to create a worktree by just specifying a branch name,
**So that** I don't need to remember the full git worktree command syntax.

#### Acceptance Criteria

**Criterion 1: Simple creation**
**Given** I'm in a git repository
**When** I run `wt create feature/auth`
**Then** a worktree is created at `../repo-feature-auth/` on branch `feature/auth`

**Criterion 2: Branch doesn't exist**
**Given** the branch `feature/new` doesn't exist
**When** I run `wt create feature/new`
**Then** the branch is created from HEAD and a worktree is set up

**Story Points: 2**

---

### Story 3: Clean stale worktrees

**As a** developer,
**I want** to remove worktrees whose branches have been merged,
**So that** I don't accumulate stale directories.

#### Acceptance Criteria

**Criterion 1: Detect stale**
**Given** worktrees exist for branches already merged to main
**When** I run `wt clean --dry-run`
**Then** I see which worktrees would be removed

**Criterion 2: Confirm before delete**
**Given** stale worktrees are detected
**When** I run `wt clean`
**Then** I'm asked to confirm before each removal

**Story Points: 3**

## Next Step
Ready for implementation planning? → `/turbocharge:plan`
