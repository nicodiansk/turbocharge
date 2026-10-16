# Example: Brainstorm Output

This is a sample design document produced by `/turbocharge:brainstorm`.

---

# CLI Worktree Manager — Design

## Problem
Developers managing multiple git worktrees lose track of which worktrees exist, what branch they're on, and which ones are stale. Manual `git worktree` commands are verbose and error-prone.

## Users
- Developers working on multiple features simultaneously
- Teams using worktree-based CI/CD workflows

## Constraints
- Must work with existing git repositories (no config changes)
- CLI-first (no GUI dependency)
- Cross-platform (macOS, Linux, Windows via Git Bash)

## Approach 1: Thin wrapper around git worktree (Recommended)
Simple CLI that adds listing, status, and cleanup on top of native `git worktree` commands. No custom state — reads directly from git.

**Trade-offs:** Fast to build, no sync issues. Limited to what git exposes.

## Approach 2: Stateful manager with database
Track worktrees in a local SQLite database with metadata (purpose, creation date, last accessed).

**Trade-offs:** Richer features, but state can drift from git reality. More complex.

## Approach 3: Git hooks integration
Auto-track worktrees via post-checkout and post-worktree hooks.

**Trade-offs:** Zero manual tracking, but hooks are fragile and platform-dependent.

## Decision
Approach 1 — thin wrapper. YAGNI on the database. We can add metadata later if needed.

## Architecture
- Single binary (Go or Rust)
- Subcommands: `list`, `create`, `remove`, `clean`
- Output: table format by default, JSON with `--json`
- No config file needed

## Next Step
Ready for story breakdown? → `/turbocharge:story`
