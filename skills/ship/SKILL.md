---
name: ship
description: Use when implementation and review are complete and you need to integrate the work, or to triage a pull request's review comments, whether fetched with gh, saved to a file or pasted (verifies each, fixes the valid ones, drafts or posts replies), or to watch its checks. Verifies tests, presents options to merge, open a PR, or keep the branch; can watch the PR it opens (--watch <PR#> attaches to an existing one); discards only on explicit request, and handles cleanup.
argument-hint: "[--watch <PR#>]"
---

# Ship

Complete development work by verifying tests and presenting integration options.

**Announce:** "Using ship to finalize this work."

**Routing.** If the request is to triage review comments (`--watch <PR#>`, a PR number, or comments in a file or pasted into the conversation), run Step 1 (tests), then go straight to **Watch and triage** and skip the menu. Triage offline when the comments were handed over or `gh` can't reach the PR.

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

Offline still verifies each item through `turbocharge:verifier` before any edit, exactly as below.

**Verify.** Each item goes to `turbocharge:verifier` through the Agent tool. The prompt holds the comment, its path:line, the branch and its base, and asks "is this comment right about the current code?". Send independent items together and wait for every completion notification. Never verify an item yourself while the Agent tool can dispatch the verifier, even when the comment looks obviously right or wrong: a public reply or a fix needs a check that didn't come from the session making the fix. Only with no Agent tool, or with the verifier not registered, verify inline by the same rules (try to refute; quote the code) and say so in the report.

**Classify.** CONFIRMED + defect = valid. CONFIRMED + nit = nit. REFUTED = false positive. UNCERTAIN = the user's batch, because a public reply needs evidence.

**Conflict stop.** A comment that asks to change something the user decided earlier (this conversation, the plan's Rulings, a design doc, CLAUDE.md) makes triage stop. Bring it to the user, quoting the decision.

**Valid:** fix it inline, or through `turbocharge:builder` when it is larger. Run the tests, commit by pathspec, then `git push`. A rejected push stops triage: no rebase, no force.

**Reply**, naming the fix commit:
- inline comment: `gh api -X POST repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies -f body=…`
- issue comment: it has no thread, so post `gh pr comment <pr> --body …` linking its `html_url`; never use the `/replies` endpoint for it (it 404s).

**False positive:** reply by the same two routes with evidence (file:line, what the code or test shows).

**Nits and uncertain:** a nit is never edited, even when it touches a line you are changing for a valid comment. Nits and uncertain items go only in one batched list for the user; nothing changes.

**Rounds.** A round = fixes, push, replies. Then the checks run again and round 2 collects new comments. Stop after 2 fix rounds and report what is left.

**Report**, per item: its class, verified by (`turbocharge:verifier` or inline, with why), the action, the commit and the reply link. Add the red checks and the batch.

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
