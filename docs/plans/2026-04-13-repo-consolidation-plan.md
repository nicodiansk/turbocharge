# Repo Consolidation (Phase 1) Implementation Plan

**Goal:** Consolidate `nicodiansk/turbocharge` + `nicodiansk/turbocharge-marketplace` into a single repo, bump to 2.3.0, and delete the sibling marketplace repo.
**Architecture:** Restore `.claude-plugin/marketplace.json` in the source repo (authoritative copy), update all install/update references from `turbocharge-marketplace` to `turbocharge`, collapse the two-repo publishing flow in CLAUDE.md to a single-repo flow. No code/runtime behavior changes — this is pure distribution plumbing.
**Tech Stack:** Bash (validate.sh), JSON (plugin.json, marketplace.json), Markdown (README.md, CLAUDE.md, CHANGELOG.md), `gh` CLI for repo description + deletion.

---

## Context

- Source design: `docs/plans/2026-04-13-repo-consolidation-design.md` (Phase 1 only; Phase 2 out of scope).
- Sibling clone present at `turbocharge-marketplace/` (gitignored) — used as source for the restored `marketplace.json`.
- `CLAUDE.md` declares domain terms and a "Publishing Flow" tied to the two-repo pattern — both must be rewritten.
- Only `README.md` and `CLAUDE.md` contain `turbocharge-marketplace` references in the source tree (verified via Grep). Skills and hooks are clean.
- Validate script (`scripts/validate.sh`) does NOT reference the marketplace repo — no edit needed there.
- Version currently `2.2.1` in `.claude-plugin/plugin.json`. Target: `2.3.0`.

## Assumptions

- The sibling `turbocharge-marketplace/` clone is current and its `marketplace.json` is the correct authoritative source to restore.
- `gh` CLI is authenticated and can edit/delete `nicodiansk/*` repos.
- The design doc's dated note (`"removed 2026-04-13"`) in CLAUDE.md was an earlier cleanup; the consolidation inverts that removal, so the note itself must go.
- Since this is a markdown/json-only plan with no runtime code, "TDD" is adapted: the failing test is a **`validate.sh` check or `grep` assertion** that fails before the change and passes after. No new unit-test framework is introduced.
- Repo deletion (Task 10) is gated by explicit user confirmation at run time — builder must pause before invoking `gh repo delete`.

---

## Task Index

1. Restore `.claude-plugin/marketplace.json` with updated `source.url`
2. Bump `plugin.json` to 2.3.0
3. Bump `marketplace.json` version field to 2.3.0
4. Update `README.md` install/update commands
5. Rewrite `CLAUDE.md` Distribution block
6. Rewrite `CLAUDE.md` Domain Terms — Marketplace entry
7. Remove stale "no marketplace.json in this repo" note in CLAUDE.md
8. Rewrite `CLAUDE.md` Publishing Flow (6 steps → 3)
9. Add CHANGELOG.md entry for 2.3.0
10. Local smoke-test via `claude --plugin-dir .` + `validate.sh`
11. Set GitHub repo description via `gh repo edit`
12. Commit `feat: v2.3.0 — consolidate plugin + marketplace into single repo`
13. Verify install from GitHub remote works end-to-end
14. Delete sibling `nicodiansk/turbocharge-marketplace` (gated, manual approval)

---

## Task 1: Restore `.claude-plugin/marketplace.json`

**Files:**
- Create: `C:\Users\nicho\VSCodeProjects\turbocharge\.claude-plugin\marketplace.json`

**Step 1: Write the failing test**

Save this check as a one-off bash assertion (run inline, not committed):

```bash
test -f .claude-plugin/marketplace.json \
  && grep -q '"url": "https://github.com/nicodiansk/turbocharge.git"' .claude-plugin/marketplace.json \
  && grep -q '"version": "2.3.0"' .claude-plugin/marketplace.json \
  && echo PASS || echo FAIL
```

**Step 2: Run test to verify it fails**

Run: `cd C:/Users/nicho/VSCodeProjects/turbocharge && test -f .claude-plugin/marketplace.json && echo EXISTS || echo MISSING`
Expected: `MISSING` (file was deleted on 2026-04-13; see `git status` showing `D .claude-plugin/marketplace.json`).

**Step 3: Write minimal implementation**

Create `C:\Users\nicho\VSCodeProjects\turbocharge\.claude-plugin\marketplace.json` with exact contents:

```json
{
  "name": "turbocharge",
  "owner": {
    "name": "Nicholas",
    "email": "nicholasprevitali96@gmail.com"
  },
  "metadata": {
    "description": "Engineering team orchestration plugins for Claude Code",
    "version": "2.3.0"
  },
  "plugins": [
    {
      "name": "turbocharge",
      "source": {
        "source": "url",
        "url": "https://github.com/nicodiansk/turbocharge.git"
      },
      "description": "Engineering team orchestration for Claude Code. 10 skills, 6 agents — single pipeline from brainstorm to shipped code.",
      "version": "2.3.0",
      "strict": true
    }
  ]
}
```

Note the two deliberate changes from the sibling-repo copy:
- `"name": "turbocharge-marketplace"` → `"name": "turbocharge"` (repo name match)
- `"version": "1.0.0"` at metadata + `"2.2.1"` at plugin → both `"2.3.0"`

**Step 4: Run test to verify it passes**

Run (from repo root):
```bash
test -f .claude-plugin/marketplace.json && grep -q '"url": "https://github.com/nicodiansk/turbocharge.git"' .claude-plugin/marketplace.json && grep -q '"version": "2.3.0"' .claude-plugin/marketplace.json && echo PASS
```
Expected: `PASS`

**Step 5: Commit**

Defer — we commit once at the end of Phase 1 (see Task 12) per the design doc.

---

## Task 2: Bump `plugin.json` to 2.3.0

**Files:**
- Modify: `C:\Users\nicho\VSCodeProjects\turbocharge\.claude-plugin\plugin.json`

**Step 1: Write the failing test**

```bash
grep -q '"version": "2.3.0"' .claude-plugin/plugin.json && echo PASS || echo FAIL
```

**Step 2: Run test to verify it fails**

Run: `cd C:/Users/nicho/VSCodeProjects/turbocharge && grep -q '"version": "2.3.0"' .claude-plugin/plugin.json && echo PASS || echo FAIL`
Expected: `FAIL` (current version is `2.2.1`)

**Step 3: Write minimal implementation**

Edit `plugin.json`: change `"version": "2.2.1"` → `"version": "2.3.0"`. No other fields touched.

**Step 4: Run test to verify it passes**

Run: same command as Step 2.
Expected: `PASS`

**Step 5: Commit**

Deferred to Task 12.

---

## Task 3: Verify `marketplace.json` plugin entry version matches

**Files:**
- Verify: `C:\Users\nicho\VSCodeProjects\turbocharge\.claude-plugin\marketplace.json`

This is a paranoia gate — Task 1 already wrote `2.3.0`, but the single-repo pattern's core promise is that version numbers in `plugin.json` and `marketplace.json` can never drift again. Prove it with a cross-file check.

**Step 1: Write the failing test**

```bash
plugin_v=$(grep -oE '"version": "[^"]+"' .claude-plugin/plugin.json | head -1)
mkt_meta_v=$(grep -oE '"version": "[^"]+"' .claude-plugin/marketplace.json | head -1)
mkt_plug_v=$(grep -oE '"version": "[^"]+"' .claude-plugin/marketplace.json | tail -1)
[ "$plugin_v" = "$mkt_meta_v" ] && [ "$plugin_v" = "$mkt_plug_v" ] && echo PASS || echo FAIL
```

**Step 2: Run test to verify it fails (if Tasks 1–2 skipped)**

If run before Task 1/2: `FAIL` (file missing or versions differ).
If run after: `PASS`.

**Step 3: Write minimal implementation**

No change needed — Tasks 1 + 2 already aligned the values. If this check fails at this point, STOP and audit Tasks 1 and 2.

**Step 4: Run test to verify it passes**

Run the Step 1 block.
Expected: `PASS`

**Step 5: Commit**

Deferred to Task 12.

---

## Task 4: Update `README.md` install/update commands

**Files:**
- Modify: `C:\Users\nicho\VSCodeProjects\turbocharge\README.md` (lines 23, 24, 27)

**Step 1: Write the failing test**

```bash
grep -c "turbocharge-marketplace" README.md
```

**Step 2: Run test to verify it fails**

Run: `cd C:/Users/nicho/VSCodeProjects/turbocharge && grep -c "turbocharge-marketplace" README.md`
Expected: `3` (must drop to `0` after edit)

**Step 3: Write minimal implementation**

Edit the Quick Start block (lines 21–31). Replace:

```bash
# Install from marketplace
claude plugin marketplace add nicodiansk/turbocharge-marketplace
claude plugin install turbocharge

# Update to latest version
claude plugin update turbocharge@turbocharge-marketplace
```

With:

```bash
# Install from marketplace
claude plugin marketplace add nicodiansk/turbocharge
claude plugin install turbocharge@turbocharge

# Update to latest version
claude plugin update turbocharge@turbocharge
```

Leave the "Or load locally" line untouched.

**Step 4: Run test to verify it passes**

Run: `grep -c "turbocharge-marketplace" README.md`
Expected: `0`

Additionally verify new commands exist:
```bash
grep -q "claude plugin marketplace add nicodiansk/turbocharge$" README.md && echo ADD_OK
grep -q "claude plugin install turbocharge@turbocharge$" README.md && echo INSTALL_OK
grep -q "claude plugin update turbocharge@turbocharge$" README.md && echo UPDATE_OK
```
Expected: `ADD_OK`, `INSTALL_OK`, `UPDATE_OK` (all three).

**Step 5: Commit**

Deferred to Task 12.

---

## Task 5: Rewrite `CLAUDE.md` Distribution block

**Files:**
- Modify: `C:\Users\nicho\VSCodeProjects\turbocharge\CLAUDE.md` (lines 36–44)

**Step 1: Write the failing test**

```bash
grep -q "Marketplace repo: nicodiansk/turbocharge-marketplace" CLAUDE.md && echo OLD_PRESENT || echo OLD_GONE
```

**Step 2: Run test to verify it fails**

Run: command above.
Expected: `OLD_PRESENT`

**Step 3: Write minimal implementation**

Replace the existing Distribution block:

```
### Distribution

```
Source repo:      nicodiansk/turbocharge (this repo)
Marketplace repo: nicodiansk/turbocharge-marketplace
Install:          claude plugin marketplace add nicodiansk/turbocharge-marketplace
                  claude plugin install turbocharge
Local dev:        claude --plugin-dir /path/to/turbocharge
```
```

With:

```
### Distribution

```
Source repo:  nicodiansk/turbocharge (this repo — single source of truth)
Install:      claude plugin marketplace add nicodiansk/turbocharge
              claude plugin install turbocharge@turbocharge
Update:       claude plugin update turbocharge@turbocharge
Local dev:    claude --plugin-dir /path/to/turbocharge
```
```

**Step 4: Run test to verify it passes**

```bash
grep -q "Marketplace repo: nicodiansk/turbocharge-marketplace" CLAUDE.md && echo FAIL || echo PASS
grep -q "single source of truth" CLAUDE.md && echo NEW_OK
```
Expected: `PASS`, `NEW_OK`

**Step 5: Commit**

Deferred to Task 12.

---

## Task 6: Rewrite `CLAUDE.md` Domain Terms — Marketplace entry

**Files:**
- Modify: `C:\Users\nicho\VSCodeProjects\turbocharge\CLAUDE.md` (line 53)

**Step 1: Write the failing test**

```bash
grep -q "lives in sibling repo \`turbocharge-marketplace\`" CLAUDE.md && echo OLD_PRESENT || echo OLD_GONE
```

**Step 2: Run test to verify it fails**

Run: command above.
Expected: `OLD_PRESENT`

**Step 3: Write minimal implementation**

Replace the existing `| **Marketplace** | …` row:

```
| **Marketplace** | GitHub repo with `.claude-plugin/marketplace.json` that indexes plugins — lives in sibling repo `turbocharge-marketplace`, NOT in this repo |
```

With:

```
| **Marketplace** | GitHub repo with `.claude-plugin/marketplace.json` that indexes plugins — lives at the root of this repo (`nicodiansk/turbocharge`) as of v2.3.0; previously a sibling `turbocharge-marketplace` repo (deleted 2026-04-13) |
```

**Step 4: Run test to verify it passes**

```bash
grep -q "lives at the root of this repo" CLAUDE.md && echo PASS || echo FAIL
```
Expected: `PASS`

**Step 5: Commit**

Deferred to Task 12.

---

## Task 7: Remove stale "no marketplace.json in this repo" note in CLAUDE.md

**Files:**
- Modify: `C:\Users\nicho\VSCodeProjects\turbocharge\CLAUDE.md` (line 73)

**Step 1: Write the failing test**

```bash
grep -q "there is intentionally NO \`.claude-plugin/marketplace.json\`" CLAUDE.md && echo STALE_PRESENT || echo STALE_GONE
```

**Step 2: Run test to verify it fails**

Run: command above.
Expected: `STALE_PRESENT`

**Step 3: Write minimal implementation**

Delete the entire line 73 note:

```
Note: there is intentionally NO `.claude-plugin/marketplace.json` in this repo. The marketplace manifest lives in the sibling repo `nicodiansk/turbocharge-marketplace`. Keeping a second copy here caused version drift (removed 2026-04-13). Repo consolidation is a tracked backlog item.
```

Replace with a single blank line (just the existing blank-line surrounds stay). Do NOT add a replacement note — the File Types table already lists the file type correctly; the standalone note was a historical marker that has served its purpose.

**Step 4: Run test to verify it passes**

```bash
grep -q "there is intentionally NO" CLAUDE.md && echo FAIL || echo PASS
```
Expected: `PASS`

**Step 5: Commit**

Deferred to Task 12.

---

## Task 8: Rewrite `CLAUDE.md` Publishing Flow (6 steps → 3)

**Files:**
- Modify: `C:\Users\nicho\VSCodeProjects\turbocharge\CLAUDE.md` (lines 99–110)

**Step 1: Write the failing test**

```bash
grep -q "two repos MUST always be in sync" CLAUDE.md && echo OLD_PRESENT || echo OLD_GONE
```

**Step 2: Run test to verify it fails**

Run: command above.
Expected: `OLD_PRESENT`

**Step 3: Write minimal implementation**

Replace the entire Publishing Flow section (lines 99–110):

```
### Publishing Flow

**The two repos MUST always be in sync. ALWAYS.**

1. Bump version in `.claude-plugin/plugin.json`
2. Push to `nicodiansk/turbocharge` (source repo)
3. Clone/pull `nicodiansk/turbocharge-marketplace`
4. Update version + description in marketplace `marketplace.json` AND `README.md` (skill count, version table, features list, pipeline diagram)
5. Push marketplace repo
6. Users run `claude plugin update turbocharge@turbocharge-marketplace`

Never push turbocharge without updating the marketplace in the same session.
```

With:

```
### Publishing Flow

Single-repo as of v2.3.0. No cross-repo sync.

1. Bump version in BOTH `.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json` (metadata.version and plugins[0].version — keep all three in lockstep)
2. Update `CHANGELOG.md` with the new entry
3. Commit + push to `nicodiansk/turbocharge`. Users pick it up via `claude plugin update turbocharge@turbocharge`.
```

**Step 4: Run test to verify it passes**

```bash
grep -q "two repos MUST always be in sync" CLAUDE.md && echo FAIL || echo PASS
grep -q "Single-repo as of v2.3.0" CLAUDE.md && echo NEW_OK
```
Expected: `PASS`, `NEW_OK`

**Step 5: Commit**

Deferred to Task 12.

---

## Task 9: Add CHANGELOG.md entry for 2.3.0

**Files:**
- Modify: `C:\Users\nicho\VSCodeProjects\turbocharge\CHANGELOG.md`

**Step 1: Write the failing test**

```bash
grep -q "^## \[2.3.0\]" CHANGELOG.md && echo PASS || echo FAIL
```

**Step 2: Run test to verify it fails**

Run: command above.
Expected: `FAIL` (top entry is currently `[2.2.0]`)

**Step 3: Write minimal implementation**

Insert the new entry immediately after line 1 (`# Changelog`) and before the `## [2.2.0]` line:

```markdown
## [2.3.0] - 2026-04-13

Single-repo distribution — plugin and marketplace manifest now live together.

### Changed
- Restored `.claude-plugin/marketplace.json` as the authoritative marketplace manifest (previously in sibling `nicodiansk/turbocharge-marketplace` repo)
- Install command: `claude plugin marketplace add nicodiansk/turbocharge` (was `nicodiansk/turbocharge-marketplace`)
- Update command: `claude plugin update turbocharge@turbocharge` (was `turbocharge@turbocharge-marketplace`)
- CLAUDE.md Publishing Flow collapsed from 6 steps across 2 repos to 3 steps in one repo
- README.md Quick Start updated with new install/update commands

### Removed
- Sibling `nicodiansk/turbocharge-marketplace` repo deleted — no longer needed

### Migration
- Existing users must re-add the marketplace: `claude plugin marketplace remove turbocharge-marketplace` then `claude plugin marketplace add nicodiansk/turbocharge`

```

**Step 4: Run test to verify it passes**

```bash
grep -q "^## \[2.3.0\] - 2026-04-13" CHANGELOG.md && echo PASS || echo FAIL
```
Expected: `PASS`

**Step 5: Commit**

Deferred to Task 12.

---

## Task 10: Local smoke-test — plugin loads + validator passes

**Files:**
- Run: `C:\Users\nicho\VSCodeProjects\turbocharge\scripts\validate.sh`

**Step 1: Write the failing test**

The test IS the validator + a manual plugin-dir smoke test. No new file.

**Step 2: Run test to verify it fails (baseline check before other tasks)**

N/A — validator was already passing at 2.2.1. We run it here to confirm no regressions from Tasks 1–9.

**Step 3: Write minimal implementation**

None — purely a verification gate.

**Step 4: Run tests to verify they pass**

Run from repo root:

```bash
bash scripts/validate.sh
```
Expected: `PASSED — 0 errors, 0 warnings` (or identical warning count to the pre-Task-1 baseline — no new warnings introduced).

Then manually:
```bash
claude --plugin-dir .
```
Inside the spawned session, run `/help` and confirm the 10 `turbocharge:*` slash commands are listed. Exit the session.

If either check fails: STOP. Do NOT proceed to Tasks 11–14. Investigate regression.

**Step 5: Commit**

Deferred to Task 12.

---

## Task 11: Set GitHub repo description via `gh repo edit`

**Files:**
- External: GitHub repo `nicodiansk/turbocharge` metadata (no local file change)

**Step 1: Write the failing test**

```bash
gh repo view nicodiansk/turbocharge --json description --jq .description
```

**Step 2: Run test to verify it fails**

Run: command above.
Expected: Empty string, `null`, or a stale description not matching the target copy below.

**Step 3: Write minimal implementation**

Run:

```bash
gh repo edit nicodiansk/turbocharge --description "Opinionated engineering pipeline for Claude Code — 10 skills, 6 agents, 3 hooks. Replaces ad-hoc agent sprawl with brainstorm → story → plan → build → review → ship."
```

**Step 4: Run test to verify it passes**

```bash
gh repo view nicodiansk/turbocharge --json description --jq .description
```
Expected: Exact string `Opinionated engineering pipeline for Claude Code — 10 skills, 6 agents, 3 hooks. Replaces ad-hoc agent sprawl with brainstorm → story → plan → build → review → ship.`

**Step 5: Commit**

N/A — GitHub metadata, not repo content.

---

## Task 12: Commit Phase 1 changes

**Files:**
- Stage: `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`, `README.md`, `CLAUDE.md`, `CHANGELOG.md`

**Step 1: Write the failing test**

```bash
git log --oneline -1 | grep -q "v2.3.0" && echo PASS || echo FAIL
```

**Step 2: Run test to verify it fails**

Run: command above.
Expected: `FAIL` (HEAD is `92da6a7 feat: v2.2.1`).

**Step 3: Write minimal implementation**

Run (explicit paths — no `git add .`):

```bash
git add .claude-plugin/marketplace.json .claude-plugin/plugin.json README.md CLAUDE.md CHANGELOG.md docs/plans/2026-04-13-repo-consolidation-design.md docs/plans/2026-04-13-repo-consolidation-plan.md
git status
```

Verify the staged set matches expectations and no stray files (particularly nothing under `turbocharge-marketplace/`) are included. Then:

```bash
git commit -m "$(cat <<'EOF'
feat: v2.3.0 — consolidate plugin + marketplace into single repo

Restore .claude-plugin/marketplace.json as the authoritative marketplace
manifest. Delete sibling nicodiansk/turbocharge-marketplace repo.

Install command changes from `turbocharge-marketplace` to `turbocharge`.
Publishing flow collapses from 6 steps across 2 repos to 3 steps in one.
EOF
)"
```

**Step 4: Run test to verify it passes**

```bash
git log --oneline -1 | grep -q "v2.3.0" && echo PASS || echo FAIL
git status
```
Expected: `PASS`, and `git status` shows a clean working tree (except for gitignored `turbocharge-marketplace/` clone and untracked docs if any).

**Step 5: Push**

```bash
git push origin master
```

---

## Task 13: Verify install from GitHub remote end-to-end

**Files:**
- None (external verification)

**Step 1: Write the failing test**

Install from the freshly pushed GitHub remote in a clean Claude Code session:

```bash
claude plugin marketplace remove turbocharge-marketplace 2>/dev/null || true
claude plugin marketplace remove turbocharge 2>/dev/null || true
claude plugin marketplace add nicodiansk/turbocharge
claude plugin install turbocharge@turbocharge
```

**Step 2: Run test to verify it fails (baseline)**

N/A — this is the acceptance test for the whole phase.

**Step 3: Write minimal implementation**

None — if Tasks 1–12 were correct, install succeeds. If it fails, STOP and debug before Task 14.

**Step 4: Run test to verify it passes**

After install, launch a Claude Code session and run:
```
/help
```
Expected: `turbocharge:brainstorm`, `turbocharge:story`, `turbocharge:plan`, `turbocharge:build`, `turbocharge:review`, `turbocharge:debug`, `turbocharge:ship`, `turbocharge:wrap`, `turbocharge:setup`, `turbocharge:atlas` all appear (10 skills).

Also verify version:
```bash
claude plugin list
```
Expected: `turbocharge` shown at version `2.3.0`.

**Step 5: Commit**

N/A — verification only.

---

## Task 14: Delete sibling `nicodiansk/turbocharge-marketplace` — GATED

**Files:**
- External: GitHub repo deletion
- Local cleanup: `C:\Users\nicho\VSCodeProjects\turbocharge\turbocharge-marketplace\` clone (optional — gitignored, but safe to remove)

**Step 1: Write the failing test**

```bash
gh repo view nicodiansk/turbocharge-marketplace >/dev/null 2>&1 && echo STILL_EXISTS || echo GONE
```

**Step 2: Run test to verify it fails**

Run: command above.
Expected: `STILL_EXISTS`

**Step 3: Write minimal implementation**

**🔒 GATE — do NOT auto-execute. Require explicit user "yes, delete" confirmation.**

Pre-conditions (ALL must be true — verify before asking):
- [x] Task 12 commit pushed to `origin/master`
- [x] Task 13 install-from-remote succeeded
- [x] User has manually confirmed via `claude plugin list` that `2.3.0` is live

Only after the user types approval, run:

```bash
gh repo delete nicodiansk/turbocharge-marketplace --yes
```

Optional local cleanup (safe because the clone is gitignored):
```bash
rm -rf C:/Users/nicho/VSCodeProjects/turbocharge/turbocharge-marketplace
```

**Step 4: Run test to verify it passes**

```bash
gh repo view nicodiansk/turbocharge-marketplace 2>&1 | grep -q "Could not resolve" && echo PASS || echo FAIL
```
Expected: `PASS`

**Step 5: Commit**

N/A — external action. If the local clone was deleted, no staged change results (gitignored).

---

## Completion Gate

Per global `coding-style.md` completion rules, before declaring Phase 1 done:

- [ ] `bash scripts/validate.sh` returns `PASSED — 0 errors`
- [ ] `grep -rn "turbocharge-marketplace" .` across the repo (excluding `docs/plans/` historical records and `turbocharge-marketplace/` gitignored clone if still present) returns ZERO matches
- [ ] `git log --oneline -1` shows the v2.3.0 commit
- [ ] `gh repo view nicodiansk/turbocharge --json description` returns the target description
- [ ] `claude plugin list` in a clean session shows `turbocharge 2.3.0` installed from `nicodiansk/turbocharge`
- [ ] `gh repo view nicodiansk/turbocharge-marketplace` fails with "Could not resolve"

## Chain Forward

After this plan completes, the next skill is Phase 2 (official marketplace submission): `/turbocharge:plan docs/plans/2026-04-13-repo-consolidation-design.md` targeting the Phase 2 section — gated on explicit user approval per the design doc.
