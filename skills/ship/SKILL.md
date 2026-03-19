---
name: ship
description: Use when implementation and review are complete and you need to integrate the work. Verifies tests, presents structured options for merge, PR, keep, or discard, and handles cleanup.
disable-model-invocation: true
---

# Ship

Complete development work by verifying tests and presenting integration options.

**Announce:** "Using ship to finalize this work."

## Step 1: Verify Tests

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Stop. Show failures. Cannot proceed.
**If tests pass:** Continue.

## Step 2: Determine Base Branch

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD develop 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

## Step 3: Present Options

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

## Step 4: Execute Choice

### Option 1: Merge Locally
```bash
git checkout <base-branch>
git pull
git merge <feature-branch>
# Verify tests on merged result
git branch -d <feature-branch>
```

### Option 2: Push and Create PR
```bash
git push -u origin <feature-branch>
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

### Option 3: Keep As-Is
Report: "Keeping branch. Worktree preserved at <path>."

### Option 4: Discard
Require typed "discard" confirmation. Then:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

## Step 5: Cleanup Worktree (Options 1, 2, 4)

```bash
git worktree list | grep $(git branch --show-current)
# If in worktree:
git worktree remove <path>
```

## Workflow Position

```
review → ship
```
