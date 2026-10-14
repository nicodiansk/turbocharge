---
name: ship
description: Use when implementation and review are complete and you need to integrate the work, or to watch a pull request's checks and triage its review comments. Verifies tests, presents options to merge, open a PR, or keep the branch; can watch the PR it opens (--watch <PR#> attaches to an existing one); discards only on explicit request, and handles cleanup.
argument-hint: "[--watch <PR#>]"
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

Which option?
```

Present the menu exactly as written. Discarding the work is not an option on it: it happens only when the user explicitly asks (see below).

The menu waits for the user's pick, even when Claude invoked ship on its own. Never merge (Option 1) or discard unless the user picked it or asked for it in this conversation.

If `$ARGUMENTS` holds `--watch <PR#>`, run Step 1 (tests), then go straight to **Watch and triage** for that PR and skip this menu.

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

After the PR is created, offer once: `Watch PR #<n>? I'd wait for its checks, fix valid review comments, and reply in their threads, after one OK for the outward actions.` A yes goes to **Watch and triage**.

### Option 3: Keep As-Is
Report: "Keeping branch. Worktree preserved at <path>."

### Discard (only on explicit request)
Only when the user explicitly asks to throw the work away. Require typed "discard" confirmation: list the branch and its commits that will be deleted, and wait for the exact word `discard`. "Yeah, get rid of it" is not the confirmation. Then:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

## Watch and triage

Reached from Option 2's watch offer, or from `--watch <PR#>`. Waits for the PR's checks, then triages its review comments.

**One OK up front.** In one message, before any outward action, ask once to: push fix commits to `<branch>` (never force-push), reply in comment threads, post issue comments, run at most 2 fix rounds, and never merge. A no gives read-only triage: classify and report, nothing outward.

**Resolve:**
```bash
gh pr view <n> --json number,url,headRefName,isDraft
gh repo view --json nameWithOwner   # {owner}/{repo}
gh api user --jq .login             # me
```

**Checks:** run `gh pr checks <n> --watch` with `run_in_background` and wait for its completion notification. Red checks go in the report with the failing job; they are not auto-fixed.

**Don't wait for a new automated review.** Once the checks finish, collect what exists. After `gh pr ready` or a push, a new automated review may never come.

**Collect**, bots included (the automated reviewer posts issue comments):
```bash
gh api --paginate repos/{owner}/{repo}/pulls/{pr}/comments    # inline
gh api --paginate repos/{owner}/{repo}/issues/{pr}/comments   # issue
```

**Skip what is already answered**, so a rerun or round 2 answers nothing twice:
- comments written by `me`;
- inline comments whose thread (the same `in_reply_to_id` root) has a later reply by `me`;
- issue comments whose `html_url` appears in a later comment by `me`.

Each remaining comment becomes an item: id, kind (inline or issue), author, path:line (inline), body, url.

**Offline:** comments handed over as a file or pasted become the same items, with no checks, no push and no replies; draft the replies instead.

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
