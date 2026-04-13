# Anthropic Official Marketplace — Submission Research

**Date:** 2026-04-13
**Status:** Research complete; informs Phase 2 re-planning
**Researcher:** turbocharge:researcher agent (see plan `2026-04-13-repo-consolidation-design.md` §Phase 2 Step 1)

## TL;DR — What changes vs. our Phase 2 design assumptions

| Assumption | Reality | Impact |
|------------|---------|--------|
| PR-based submission | **Form-based** — `clau.de/plugin-directory-submission` | Rewrite Phase 2 Step 3 when re-planning |
| Phase 2 ends with a GitHub PR | Ends with a form submission → internal review → nightly sync to repo | Different gating UX |
| License: MIT preferred | Either MIT or Apache-2.0 is safe; Anthropic uses Apache-2.0 internally | Keep MIT (already declared in plugin.json); just add actual LICENSE file |
| No hard license requirement | `license` field increasingly expected by reviewers | Add `license: MIT` to marketplace.json plugins[] entry |

## Key Facts

### Repositories
- Official: [`anthropics/claude-plugins-official`](https://github.com/anthropics/claude-plugins-official) — curated, high-quality
- Community mirror: `anthropics/claude-plugins-community` — read-only mirror of community submissions
- **Neither is PR-target.** Both are downstream of the submission form + nightly sync.

### Submission Path
1. Form: `clau.de/plugin-directory-submission` (GitHub link or zip)
2. In-app alternatives: `claude.ai/settings/plugins/submit`, `platform.claude.com/plugins/submit`
3. Internal Anthropic review pipeline
4. Approved entries appear in `.claude-plugin/marketplace.json` of the official (or community) repo on next nightly sync

### Automated Checks
- Schema validation on marketplace.json
- Security scan on submission
- Source URL/git ref accessibility
- Plugin manifest structure validation

### Human Review Criteria (inferred from recent merged PRs)
- Description clarity
- Source URL accessibility
- Basic post-install functionality
- Code quality (no published metric)
- Documentation completeness

### Tiers
- **Basic approval** — passes automated + basic review
- **Anthropic Verified** — additional manual quality/safety review (discretionary)

### Turnaround
- Not published. Recent community PRs (Superpowers #148, Conductor #237, Ruby LSP #106) merged within days, but those were already pre-approved in the pipeline.
- First-time submissions via form: estimated 1–4 weeks (unconfirmed).

## Pre-Flight Checklist (applied to turbocharge)

### `.claude-plugin/plugin.json`
- ✅ `name` kebab-case and unique (`turbocharge`)
- ✅ `description` clear, under 150 chars
- ✅ `version` semver (`2.3.0` after Phase 1)
- ✅ `author` populated
- ✅ `license: "MIT"` declared
- ✅ `repository` set
- ✅ `homepage` set
- ⬜ **`category` field** — consider adding (reviewers increasingly expect it). Candidates: `"development"`, `"productivity"`, `"workflow"`

### `.claude-plugin/marketplace.json` (plugins[0] entry)
- ✅ `name`, `description`, `source.url`
- ✅ `version`, `strict`
- ⬜ **`license: "MIT"`** — add (increasingly expected)
- ⬜ **`category`** — add (see above)
- ⬜ **`source.ref` or git SHA pinning** — consider. Improves reproducibility; Anthropic accepts plain URL too.

### Repository
- ⬜ **LICENSE file at repo root** — plugin.json claims MIT but there's no actual license file. MUST add.
- ⬜ Clean git history (Phase 1 commits OK; no stray WIP)
- ✅ Public GitHub repo

### Documentation
- ⬜ README rewrite (already in Phase 2 Step 3 — captivating, ruflo-inspired)
- ⬜ Each skill/agent with invocation example
- ⬜ Dependencies documented (MCP servers, external tools)
- ⬜ Env vars documented (if any)

### Functionality
- ⬜ All 10 skills load via `claude --plugin-dir .` (Phase 1 Task 10 covers this)
- ⬜ 6 agents visible in `/agents`
- ⬜ Hooks trigger correctly
- ⬜ No hardcoded secrets

## Open Questions

1. Exact review timeline SLA — not documented.
2. Rejection criteria — no public list.
3. Version management — pull from main vs. tagged release vs. git SHA? Docs unclear.
4. MCP server vetting — if plugin declares MCP servers, are they reviewed separately?
5. "Anthropic Verified" badge criteria — discretionary, no public rubric.
6. Community vs. official pathway — same form, possibly different review bar, undefined publicly.

## Sources

- [Submission form](https://clau.de/plugin-directory-submission)
- [Plugin docs](https://code.claude.com/docs/en/plugins)
- [Marketplace docs](https://code.claude.com/docs/en/plugin-marketplaces)
- [Official marketplace repo](https://github.com/anthropics/claude-plugins-official)
- [Community marketplace mirror](https://github.com/anthropics/claude-plugins-community)

## Action Items for Phase 2 Re-plan

When `/turbocharge:plan` is run on Phase 2 later, update the design doc to reflect:
- Submission = form, not PR
- Step 3 renamed: "Submit via clau.de form"
- Add a task to append `license` + `category` to both `plugin.json` and `marketplace.json`
- Add a task to create a `LICENSE` file at repo root (MIT text)
- Keep the gated-approval principle — user approves before the form is submitted
