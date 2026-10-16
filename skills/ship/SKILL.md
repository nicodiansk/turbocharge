---
name: ship
description: Use when implementation and review are complete and you need to integrate the work, or to triage a pull request's review comments saved to a file or pasted (verifies each, fixes the valid ones, drafts the replies). Verifies tests, presents options to merge, open a PR, or keep the branch; discards only on explicit request, and handles cleanup.
---

# Ship

Complete development work by verifying tests and presenting integration options.

**Announce:** "Using ship to finalize this work."

**Routing.** If the request is to triage review comments (in a file or pasted into the conversation), run Step 1 (tests), then go straight to **Triage review comments** and skip the menu. If it names only a PR, ask the user to save its comments to a file or paste them. To watch a PR's checks and comments instead, Claude Code has `/autofix-pr`.

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

Which option?
```

Present the menu exactly as written. Discarding the work is not an option on it: it happens only when the user explicitly asks (see below).

The menu waits for the user's pick, even when Claude invoked ship on its own. Never merge (Option 1) or discard unless the user picked it or asked for it in this conversation.

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

### Discard (only on explicit request)
Only when the user explicitly asks to throw the work away. Require typed "discard" confirmation: list the branch and its commits that will be deleted, and wait for the exact word `discard`. "Yeah, get rid of it" is not the confirmation. Then:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

## Triage review comments

Reached from routing: a pull request's review comments, handed over in a file or pasted. Triage changes the branch locally and nothing else: it never pushes and never posts. The user posts the drafted replies.

Each comment becomes an item: id, kind (inline or issue), author, path:line (inline), body, url. Skip a comment the file shows already answered.

**Verify.** Each item goes to `turbocharge:verifier` through the Agent tool. The prompt holds the comment, its path:line, the branch and its base, and asks "is this comment right about the current code?". Send independent items together and wait for every completion notification. Never verify an item yourself while the Agent tool can dispatch the verifier, even when the comment looks obviously right or wrong: a reply or a fix needs a check that didn't come from the session making the fix. Only with no Agent tool, or with the verifier not registered, verify inline by the same rules (try to refute; quote the code) and say so in the report.

**Classify.** CONFIRMED + defect = valid. CONFIRMED + nit = nit. REFUTED = false positive. UNCERTAIN = the user's batch, because a reply needs evidence.

**Conflict stop.** A comment that asks to change something the user decided earlier (this conversation, the plan's Rulings, a design doc, CLAUDE.md) makes triage stop. Bring it to the user, quoting the decision.

**Valid:** fix it inline, or through `turbocharge:builder` when it is larger. Run the tests, then commit by pathspec. Draft a reply naming the fix commit.

**False positive:** draft a reply with evidence (file:line, what the code or test shows).

**Nits and uncertain:** a nit is never edited, even when it touches a line you are changing for a valid comment. Nits and uncertain items go only in one batched list for the user; nothing changes.

**Report**, per item: its class, verified by (`turbocharge:verifier` or inline, with why), the action, the commit and the drafted reply. Add the batch.

## Step 5: Cleanup Worktree (Options 1 and 2, or after a discard)

```bash
git worktree list | grep $(git branch --show-current)
# If in worktree:
git worktree remove <path>
```

## Workflow Position

```
review → ship
```
