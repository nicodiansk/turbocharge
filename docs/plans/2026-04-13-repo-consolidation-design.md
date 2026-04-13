# Repo Consolidation + Official Marketplace Submission — Design

**Date:** 2026-04-13
**Status:** Approved
**Skill:** brainstorm → plan

## Problem

Every release requires 2 commits across 2 repos (`nicodiansk/turbocharge` + `nicodiansk/turbocharge-marketplace`). The 2.2.0 → 2.2.1 version drift (cleaned up 2026-04-13) is exactly this class of bug. Sync discipline is load-bearing but fragile. Single-repo pattern (precedent: `AZidan/codemap`) eliminates the sync problem.

Separately: turbocharge is not discoverable via Anthropic's official marketplace. Users must know the `nicodiansk/turbocharge-marketplace` string to install.

## Solution

Two-phase plan.

**Phase 1 — Consolidate.** `nicodiansk/turbocharge` becomes the single source of truth, with `marketplace.json` restored as the authoritative copy. Old `nicodiansk/turbocharge-marketplace` repo is deleted (only user is the author — no migration concern).

**Phase 2 — Official submission.** Research Anthropic's marketplace requirements, polish the plugin (license, README, metadata), then submit a PR pointing at the consolidated repo. Submission is gated behind user approval — nothing auto-chains to the PR.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Scope | Design both phases together | Consolidation choices shape submission readiness |
| Repo identity | Keep `nicodiansk/turbocharge`, delete the marketplace repo | Repo named after the product; `-marketplace` suffix is awkward for discovery and official-marketplace pitch |
| Migration strategy | None | User has no other users yet |
| Layout | Plugin at root, `marketplace.json` in `.claude-plugin/` | Matches pre-deletion layout + matches `AZidan/codemap` precedent |
| Version bump | 2.2.1 → 2.3.0 (minor) | Distribution model change is user-visible |
| Submission timing | Gated, manual trigger | Polish everything before exposing to Anthropic review |

---

## Phase 1 — Consolidated Layout

```
turbocharge/
├── .claude-plugin/
│   ├── plugin.json         ← already here
│   └── marketplace.json    ← NEW (authoritative, restored from sibling repo)
├── skills/
├── agents/
├── hooks/
├── settings.json
├── scripts/validate.sh
├── README.md
└── CLAUDE.md (gitignored)
```

**Install command becomes:**
```bash
claude plugin marketplace add nicodiansk/turbocharge
claude plugin install turbocharge@turbocharge
```

**Update command becomes:**
```bash
claude plugin update turbocharge@turbocharge
```

### Implementation Steps

1. **Copy `marketplace.json`** from sibling `turbocharge-marketplace/` clone into `.claude-plugin/marketplace.json`. Update `source` to point to this same repo.
2. **Grep-and-replace** `turbocharge-marketplace` → `turbocharge` across:
   - `README.md` (install, update, plugin list examples)
   - `CLAUDE.md` (Distribution block, Publishing Flow, Domain Terms)
   - `skills/*/SKILL.md` (any user-facing install/update references)
   - `hooks/*.md` (session-start bootstrap content)
   - `scripts/validate.sh` (if it references the marketplace repo)
3. **Rewrite Publishing Flow in CLAUDE.md** — collapse 6 steps to 3 (bump version → commit → push). Drop the "two repos MUST always be in sync" rule.
4. **Bump versions**: `plugin.json` and `marketplace.json` both to **2.3.0**.
5. **Set GitHub repo description** via `gh repo edit nicodiansk/turbocharge --description "…"`. Suggested: *"Opinionated engineering pipeline for Claude Code — 10 skills, 6 agents, 3 hooks. Replaces ad-hoc agent sprawl with brainstorm → story → plan → build → review → ship."*
6. **Commit** as `feat: v2.3.0 — consolidate plugin + marketplace into single repo`.
7. **Verify locally**: `claude --plugin-dir .` smoke-test, then simulate install from the updated GitHub remote.
8. **Delete sibling repo**: `gh repo delete nicodiansk/turbocharge-marketplace --yes` — only after step 7 passes.

---

## Phase 2 — Official Marketplace Submission

Gated, polish-first. PR submission is the **last** step and requires explicit user approval.

### Ordered Steps

1. **Research (agent).** Dispatch a researcher agent with today's date (reference point) as the freshness anchor. Prompt covers:
   - Locate Anthropic's official plugin marketplace repo (current, not stale refs)
   - Read submission docs, CONTRIBUTING, and last 3-5 merged plugin PRs
   - Extract: exact repo + path, required entry fields, review criteria, CI checks, turnaround expectations
   - Return a single checklist: "what turbocharge needs to ship before submitting"

2. **License decision + LICENSE file.** Candidates: MIT (permissive, default for small tools), Apache-2.0 (patent grant, matches Anthropic's own claude-code license), BSD-3-Clause. Default lean: **MIT**, unless research flags Anthropic preference for Apache-2.0 in marketplace submissions.

3. **README rewrite — captivating.** Current README is functional but workmanlike. Target: a README that makes someone *want* to install in 20 seconds. Reference inspiration: [ruvnet/ruflo](https://github.com/ruvnet/ruflo) — review its structure (hero section, tagline, demo-first ordering, visual hierarchy, pitch-before-docs). Extract applicable patterns without cargo-culting style mismatches. Use existing screenshots. Large enough task to warrant its own build task, not a drive-by edit.

4. **`plugin.json` polish.** Verify `description`, `author`, `homepage` fields are populated and punchy. Align with the README tagline.

5. **Pre-flight verification.** Run checklist below. All green before proceeding.

6. **🔒 GATE: explicit user approval to submit.** Pre-flight complete ≠ ready to PR. User decides when.

7. **Submit PR** to Anthropic's marketplace manifest. PR body: what turbocharge is, the problem it solves (agent sprawl), concrete before/after, link to README.

8. **Respond to review + merge.**

### Pre-flight Checklist

- ✅ Working install from `nicodiansk/turbocharge` (phase 1)
- ✅ Semver discipline (phase 1)
- ✅ Repo description set (phase 1)
- ✅ Screenshots exist (already in repo)
- ⬜ LICENSE file present
- ⬜ README rewritten — captivating, scannable, demo-forward
- ⬜ `plugin.json` description/author/homepage punchy and aligned with README

### Why Phase 2 Is Independent of Phase 1 Layout

Anthropic's marketplace references our repo by URL — they don't care about our internal `.claude-plugin/marketplace.json`. Phase 1 makes `nicodiansk/turbocharge` installable standalone; that's the only phase-1 output phase 2 needs.

---

## What We're NOT Building

- No CI to sync between repos (the whole point is to stop needing that)
- No migration hook / nudge for existing users (there are none)
- No README redirect on the old repo (it's being deleted, not archived)
- No automatic PR submission (gated, manual only)
- No new plugins in `marketplace.json` (stays single-plugin; forward-thinking later)

## Scope

**Phase 1:**
- 1 new file: `.claude-plugin/marketplace.json` (restored)
- Modified: `README.md`, `CLAUDE.md`, possibly `skills/*/SKILL.md`, `hooks/*.md`, `scripts/validate.sh`, `.claude-plugin/plugin.json`
- Version bump: minor (2.2.1 → 2.3.0)
- External: `gh repo edit` for description, `gh repo delete` for old repo

**Phase 2:**
- 1 new file: `LICENSE`
- Rewritten: `README.md`
- Modified: `.claude-plugin/plugin.json` (metadata polish)
- External: PR to Anthropic's marketplace repo (gated)
