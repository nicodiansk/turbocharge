# Changelog

## [3.2.1] - 2026-10-12

Docs: the real directory install command, and a correction to the [3.2.0] notes. No behavior change.

### Corrected
- **[3.2.0] said the 3.0.0 rename premise "was wrong". It was half wrong.** Another author's plugin, also named `turbocharge`, *is* listed in Claude's plugin directory. What 3.0.0 missed was that this plugin's own listing already existed. The directory tells same-named plugins apart by appending the publisher, so ours is `turbocharge-nicodiansk`. Restoring the name is still right: the directory takes the command namespace from `plugin.json` `name`, so the listing's users keep `/turbocharge:`. The [3.2.0] entry stays as released.

### Changed
- `README.md`: Install leads with the directory, using `claude plugin install turbocharge-nicodiansk@anthropic-plugin-directory` (Claude Code has that marketplace built in) and its `claude plugin update` counterpart. The repo marketplace comes second, for releases before the directory's review. A note says to install one copy, not both, since they register the same commands.
- `.claude/CLAUDE.md`: the Distribution block gives the directory install id and how to check the live version. The name-history note is corrected.
- `README.md`: the "Coming from turboflow 3.0–3.1" migration section is gone. Only the maintainer ever installed the interim turboflow releases, so the README's Upgrading section now speaks to directory and 2.x users alone. The compatibility code stays (the `renames` map, the snapshot fallback, setup's turboflow markers), and the [3.2.0] notes keep the migration steps.
- `README.md`: a new **Where it works** section explains that Claude Code runs the whole pipeline, Cowork loads the skills, agents and hook, and Chat loads only the skills, ignoring agents and hooks. The hook disclosure now says the repo's `.github/workflows` are CI for maintaining the plugin, never run on users' machines, and use only the repo's own secret. The snapshot row says the newer of the two snapshot files loads.
- Removed the plugin's `settings.json`. It was empty (`permissions: {}`, `env: {}`), Chat and Cowork ignore plugin settings, and the directory flagged it as modifying settings. `validate.sh`, `.claude/CLAUDE.md` and the README tree no longer expect it (`t_no_plugin_settings.sh`).
- CI: new `.github/workflows/tests.yml` runs the full gate (`scripts/validate.sh`, meaning the content-shape tests plus `claude plugin validate --strict`, with Claude Code pinned to 2.1.296) on every PR and on pushes to `master` and `release`. It fails fast without jq and uses no secrets (`t_ci_tests_workflow.sh`).
- `.claude/CLAUDE.md` Publishing Flow: the directory will track a `release` branch, fast-forwarded with `git push origin vX.Y.Z:release`, so merges to `master` reach repo-marketplace installs without creating directory versions. The switch waits until 3.2.0 is live, because changing the tracked branch cancels a waiting publish request (`t_release_flow_docs.sh`).
- `README.md`: the Discover hint says which listing to pick. The redundant Update stanza under "Other install methods" is removed, since each install path now carries its own update command.
- New `t_directory_listing_docs.sh` guards the directory install and update commands, the repo-marketplace commands, the one-copy note and the corrected history. New `t_changelog_321.sh` checks this entry.

## [3.2.0] - 2026-10-12

**The name is `turbocharge` again.** 3.0.0 renamed the plugin to `turboflow` because we believed a different author already listed `turbocharge` in Claude's plugin directory. That was wrong: the **Turbocharge** listing in the claude.ai plugin directory is this plugin's own (submitted 2026-06-23, published 2026-09-24, live at v2.8.1 with about 300 installs). 3.2.0 restores the plugin, marketplace and repo name `turbocharge` so those users can upgrade without their commands changing, and keeps everything 3.0–3.1 added.

### Upgrading from 2.8.x (the directory listing)
Update as usual. Your commands stay `/turbocharge:<skill>`, your `.claude/turbocharge-session.json` snapshot keeps loading, and `/turbocharge:setup` finds the `<!-- turbocharge:… -->` blocks it wrote. 3.2.0 requires **Claude Code 2.1.288 or later**. Since 2.8.1:
- **Build:** plans hold decisions instead of complete code, grouped into lanes. Build runs mechanical lanes in your session and gives each real-logic lane one Sonnet builder. Independent lanes run in parallel, the full suite runs once at the end, and fix rounds resume the same builder. Build no longer pauses every 3 tasks; `--checkpoint` brings back a pause per lane.
- **Background subagents:** `plan` and `review` block until done, and build waits for each subagent to finish.
- **AGENTS.md and CLAUDE.md:** SessionStart and setup handle projects that use `AGENTS.md`, `.claude/CLAUDE.md` or `CLAUDE.local.md`.
- **SessionStart output:** capped so it stays inline, with the session snapshot getting the space left over.
- **Agent Teams:** multi-track mode is gone, and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is no longer needed.

### Coming from turboflow 3.0–3.1
`/turboflow:<skill>` is `/turbocharge:<skill>` again. `marketplace.json` now carries `renames: {"turboflow": "turbocharge"}`, so Claude Code follows the plugin rename. An existing install keeps its marketplace key; check it with `claude plugin marketplace list`.
- **Key `turbocharge`** (marketplace added before 3.0.0): `claude plugin marketplace update turbocharge`, then `claude plugin install turbocharge@turbocharge`.
- **Key `turboflow`, Quick:** `claude plugin marketplace update turboflow`, then `claude plugin install turbocharge@turboflow`.
- **Key `turboflow`, Clean:** `claude plugin marketplace remove turboflow`, `claude plugin marketplace add nicodiansk/turbocharge`, then `claude plugin install turbocharge@turbocharge`. `marketplace remove` also deletes the plugin's saved options and data.

Then run `/reload-plugins`, and update personal rules, permissions and scripts that name `turboflow:*`. Nothing else needs migrating:
- **Snapshot:** SessionStart loads the newer of `.claude/turbocharge-session.json` and `.claude/turboflow-session.json`. A stale 2.x snapshot left beside a 3.x one never wins. The next `/turbocharge:wrap` writes the turbocharge name and deletes the interim file.
- **Setup blocks:** setup adopts blocks written under `<!-- turboflow:NAME -->` markers and rewrites them in place instead of appending duplicates. If a project has both forms of a block, it keeps the turbocharge one and removes the turboflow copy.

### Changed
- **Bulk rename:** `perl -pi` (CRLF-safe) changed `turboflow` → `turbocharge` and `Turboflow` → `Turbocharge` across 45 files: skills, hooks, examples, SVGs, the template (`templates/CLAUDE-turboflow.md` → `templates/CLAUDE-turbocharge.md`), the validators, README, `.claude/CLAUDE.md` and tests. No agent file names the plugin. Earlier CHANGELOG entries are unchanged, and `t_migration_docs.sh` still checks the frozen [3.0.0] migration paths.
- **Manifests:**
  - `plugin.json`: `name` is `turbocharge`, `displayName` is `Turbocharge`, URLs point to `nicodiansk/turbocharge`, version 3.2.0.
  - `marketplace.json`: `name` and plugin entry are `turbocharge`, the source URL is `turbocharge.git`, and `renames` is `{"turboflow": "turbocharge"}`. The 3.0.0 reverse entry is removed, because keeping it would make a cycle.
- **README:** Install names the directory listing, and Upgrading covers both audiences.
- **`.claude/CLAUDE.md`:** records the directory listing and the name history.
- **Guards:** `t_no_titlecase_brand.sh` now forbids title-case `Turboflow`, and `t_no_old_repo_path.sh` forbids the `nicodiansk/turboflow` path. The new `t_no_turboflow_namespace.sh` fails on any lowercase `turboflow` in skills, agents, hooks, templates, examples or images, outside the snapshot and setup-marker compatibility references. The rest of the suite was rehomed to the turbocharge names (`t_session_snapshot.sh`, `t_gitignore_session.sh`, `t_marketplace_renames.sh`, `t_migration_docs.sh`, `t_setup_claudemd_phase.sh`).

### Repo
After merge the GitHub repo is renamed back to `nicodiansk/turbocharge`. GitHub redirects the `nicodiansk/turboflow` URLs, and the directory listing keeps tracking the repo.

## [3.1.1] - 2026-10-12

Review follow-ups. These are the valid findings from the automated Claude reviews on PR #19 (3.0.2) and PR #20 (3.1.0). No user action is needed.

### Fixed
- `hooks/session-start.sh`: with `CLAUDE.local.md` and `AGENTS.md` but no `CLAUDE.md`, Claude Code skips AGENTS.md, because CLAUDE.local.md counts as a CLAUDE.md. Before this fix the hook printed nothing. It now shows a new **AGENTS.md Not Loaded** nudge (`hooks/agentsmd-not-loaded-nudge.md`), which points to adding `@AGENTS.md` to CLAUDE.local.md or running `/turboflow:setup`. The nudge clears once CLAUDE.local.md imports `@AGENTS.md`; that check reads only CLAUDE.local.md, and the README disclosure says so. CLAUDE.local.md alone, or any setup with a `CLAUDE.md`, gets no nudge. A comment records that the hook checks the working directory only (`t_claudemd_variants.sh`).
- `hooks/session-start.sh`: when the leftover budget is ≤ 0, the snapshot block is skipped instead of printed empty. Today's fixed caps never reach that point. The review's exit-1 concern was a false positive, since the hook ends with `exit 0`. `t_session_start_exit_code.sh` now pins exit 0 across four project shapes, and runs a copy of the hook with no budget to prove the snapshot block is skipped.
- `skills/build/SKILL.md`, `agents/builder.md`: these now list every place a stashing commit hook can be configured. That covers `.pre-commit-config.yaml`, plus lint-staged via `.lintstagedrc*`, `lint-staged.config.*`, a `lint-staged` key in `package.json`, or a `.husky/` hook. Before, lint-staged set up through Husky could slip through, and build would overlap lanes in that repo.
- `skills/plan/SKILL.md`, `agents/planner.md`: a task's Verify runs only that task's tests, never the full suite, which build runs once at the join. Line ranges are plan-time hints, and build and the builder re-locate code by content when an earlier task has shifted it.

### Changed
- `t_version_310.sh` → `t_version_matches_changelog.sh`, which checks that plugin.json `version` equals the newest CHANGELOG heading. Releases no longer need a per-version test file. `t_changelog_310.sh` drops its newest-entry check.
- `README.md`: the SessionStart row mentions the AGENTS.md-not-loaded nudge.

### Not changed (review items declined)
- **Hook exits 1 (PR #20):** a false positive. The hook ends with `exit 0`, which is now pinned by a test.
- **`experimental.cacheTtl` support (PR #20):** it is a documented subagent-frontmatter key in the sub-agents docs, with values `5m`/`1h`. It needs Claude Code 2.1.248+, and `1h` is ignored while a subscription is on usage credits. (`claude plugin validate --strict` is no evidence either way: at the repo root it checks the marketplace manifest, not agent frontmatter.)
- **Minor bump for breaking changes (PR #20):** a deliberate choice for 3.1.0, documented in its Migration section.
- **Repeated dispatch-prefix sentence (PR #19):** this is deliberate. Each skill must stand alone, and `t_dispatch_agentsmd_prefix.sh` plus `t_claudemd_dotclaude_refs.sh` catch drift.
- **CI for the test suite (PR #19):** deferred to its own change.

## [3.1.0] - 2026-10-09

Fast build: plans record decisions instead of complete code, and build runs them by lane. Mechanical lanes run in your main session with no spawn, lanes with real logic get one builder each, and independent lanes overlap. In the 3.0.0 cycle the planner spent 19 minutes writing a 69 KB plan (~5 KB of code per task), then 13 builders spent 26–89 s and ~25k tokens each re-typing it. The 3.1.0 plan is ~1.35 KB per task; its build ran 4 lanes inline and 1 builder lane in the background.

### Migration
No action is needed. Plans written before 3.1 have no Lanes table, so `/turboflow:build` runs them as one lane. `/turboflow:build` keeps its plan-file argument. **Build no longer pauses for approval every 3 tasks by default.** It reports one line per finished lane and keeps going. `--checkpoint` (formerly `--checkpoint=N`) brings back a pause, now after each lane. If you used multi-track mode, overlapping lanes replace it and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is no longer needed. If a pre-3.0.0 `.claude/turbocharge-session.json` is still in a project, rename it to `.claude/turboflow-session.json`, because SessionStart no longer reads the old name.

### Added
- **Lanes:** a `## Lanes` table in every plan, `| Lane | Owns files | Tasks | After | Executor | Effort |`. No file belongs to two lanes. `After` orders lanes. The Executor hint (`inline`/`builder`) and Effort guide build (`t_plan_lean_format.sh`).
- **Routing:** build sends each lane inline (main session) or to one Sonnet builder. It overrides the hint for real logic or tiny exact-text lanes. `--inline` runs every lane in the main session, and `--delegate` gives every lane a builder (`t_build_lanes.sh`).
- **Overlap and join:**
  - Builder lanes run in the background while the main session runs inline lanes.
  - Every commit is scoped to its task's files with `git commit -m … -- <this task's files>`, with one retry on `index.lock`.
  - Lanes don't overlap in repos whose commit hooks stash unstaged changes (`.pre-commit-config.yaml`, lint-staged).
  - When a lane finishes, build reports it and starts the lanes it unblocked.
  - At the join, build waits for every completion notification and runs the full suite plus validators once (`t_build_background_wait.sh` retargeted).
- **Per-spawn effort:** builder lanes pass the plan's Effort on the Agent call.
- **Fix rounds** resume the lane's builder with `SendMessage`, so its context and prompt cache stay warm. Re-review resumes the same task-reviewer. The builder agent gains `experimental.cacheTtl: 1h` (`t_builder_lane_agent.sh`).
- `t_guards_set_e.sh`: the git-grep guard tests must pass under `bash -e`.

### Changed
- `skills/plan/SKILL.md` and `agents/planner.md`: tasks carry Lane, Files with line ranges, **Decision**, **Test** assertions, **Verify** and **Commit**. Code appears only where the exact text is the decision. The planner's self-review gains a lane-disjointness check. `model: inherit` and `effort: high` are unchanged.
- `skills/build/SKILL.md`: rewritten around lanes.
  - The Iron Law now gates on the join: no build is complete without the full suite green there.
  - `--reviewed` runs one task-reviewer per lane, on `git diff $BEFORE_SHA..HEAD -- <lane paths>`.
  - New Red Flags: the full suite while lanes are in flight, unscoped `git commit`/`git add -A`, a new spawn for a fix round, and a builder spawned for a tiny exact-text lane.
- `agents/builder.md` runs a whole lane, with per-task tests and pathspec commits, and never runs the full suite mid-overlap. `agents/task-reviewer.md` reviews a lane's diff and is resumed for re-review.
- `hooks/session-start.sh`: the session snapshot gets the leftover budget, `9500 B` minus everything else the hook prints, instead of a fixed 2,500 B. Earlier output is captured in shell variables, so the hook still writes nothing (`t_session_start_output_cap.sh`).
- README: the skills table, How Build Works and the build diagram describe lanes. `.claude/CLAUDE.md` gains a **Lane** domain term.

### Removed
- **Agent Teams multi-track mode** (build Step 5) and its `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` setup. Overlapping lanes give the parallelism without an experimental flag. `t_build_multitrack_refresh.sh` → `t_build_lanes.sh`, which keeps the builder-isolation assertions.
- The 3.0.x `.claude/turbocharge-session.json` fallback in SessionStart and its `.gitignore` line, as announced in 3.0.0. `t_session_snapshot_fallback.sh` → `t_session_snapshot.sh`, which asserts the old file is ignored.

### Fixed
- The git-grep guards (`t_no_old_repo_path.sh`, `t_no_titlecase_brand.sh`) add `|| true` inside their `$(git grep …)` calls. git grep exits 1 on no match, and that aborted the script under `set -e`.

## [3.0.2] - 2026-10-09

Directory-ready: the plugin now passes `claude plugin validate --strict` and documents what its hook does, ahead of submission to the claude.ai plugin directory. No user action is needed.

### Changed
- This repo's `CLAUDE.md` moved to `.claude/CLAUDE.md`. A `CLAUDE.md` at the plugin root is not loaded as plugin context, and `claude plugin validate` warns on it, which fails `--strict`. Claude Code still loads `.claude/CLAUDE.md` as project memory. `.gitignore` now ignores only a root `/CLAUDE.md`; the old bare entry also matched `.claude/CLAUDE.md` (`t_no_root_claudemd.sh`).
- The version lives only in `.claude-plugin/plugin.json`. `marketplace.json` drops `metadata.version` and `plugins[0].version`: plugin.json wins over the marketplace entry, and the docs advise setting it in one place. The three-field lockstep rule is retired. `t_version_lockstep.sh` now fails if `marketplace.json` carries any version, and it uses grep, so it never skips without jq. `t_version_301.sh` → `t_version_302.sh`.
- `scripts/validate.sh` runs `claude plugin validate --strict` and prints the validator's findings when it fails. When the `claude` CLI is missing, it prints a visible warning instead of skipping silently (`t_validate_sh_strict.sh`).

### Added
- `README.md`: a **What the hook does** section for the directory's security review. It says when the SessionStart hook runs (start, resume, clear, compact), that it is read-only, writes nothing, changes no settings or permissions, and sends nothing over the network itself, and that what it prints becomes session context. It lists every file the hook reads and the one command it may run, `codemap stats` (`t_readme_hook_disclosure.sh`).

### Fixed
- `hooks/session-start.sh`: `CLAUDE.md`, `.claude/CLAUDE.md` and `CLAUDE.local.md` in the working directory now each count as "a CLAUDE.md exists". These are the files the Claude Code docs count for the AGENTS.md rule, though the docs also look in parent directories and the hook does not. Before, a project that kept its instructions in `.claude/CLAUDE.md` got a false "No CLAUDE.md" nudge, or the AGENTS.md-only nudge although Claude Code was not reading AGENTS.md (`t_claudemd_variants.sh`).
- `@CLAUDE.md` does not resolve for such projects either. In build (builder and researcher prefixes), plan and review, `.claude/CLAUDE.md` now counts as a CLAUDE.md and is prefixed as `@.claude/CLAUDE.md`. wrap uses it in the resume prompt and edits it in place, and atlas reads it. `setup` edits whichever file exists and never creates a second. Imports resolve relative to the importing file, so inside `.claude/CLAUDE.md` setup writes `@../AGENTS.md` (`t_claudemd_dotclaude_refs.sh`).
- `t_version_302.sh` checks with grep, so a missed version bump is caught even without jq.

### Unchanged (intentional)
- The 3.0.x `.claude/turbocharge-session.json` fallback stays until 3.1, as announced.

## [3.0.1] - 2026-10-09

Repo rename: the GitHub repo moved from `nicodiansk/turbocharge` to `nicodiansk/turboflow`, so it matches the plugin and marketplace name 3.0.0 introduced. GitHub redirects the old URLs, so existing installs, `claude plugin update turboflow@turboflow`, and `claude plugin marketplace add nicodiansk/turbocharge` keep working. No user action is needed. New installs use `claude plugin marketplace add nicodiansk/turboflow`.

### Changed
- `.claude-plugin/plugin.json`: `homepage` and `repository` → `https://github.com/nicodiansk/turboflow`.
- `.claude-plugin/marketplace.json`: plugin source `url` → `https://github.com/nicodiansk/turboflow.git`.
- All three `version` fields → 3.0.1.
- `README.md`: Install and Clean-migration `marketplace add` → `nicodiansk/turboflow`, local dev `--plugin-dir ./turboflow`, and Project Structure tree label → `turboflow/`.
- `CLAUDE.md`: Distribution block (source repo, install, local dev), the Marketplace domain term, and the Publishing Flow push target → `nicodiansk/turboflow`.
- Tests: `t_version_300.sh` → `t_version_301.sh`. `t_migration_docs.sh` now checks that the README re-add uses `nicodiansk/turboflow`, while the [3.0.0] entry keeps the path it shipped with. New `t_changelog_301.sh`, plus `t_no_old_repo_path.sh`, which fails if any tracked file except CHANGELOG.md names the old repo path or clone dir. The historical `turbocharge-marketplace` sibling repo may still be named.

### Unchanged (intentional)
- Local marketplace and plugin keys are not the repo, so they stay: the `renames` map and the README Quick migration path (`marketplace update turbocharge`, `install turboflow@turbocharge`).
- The 3.0.x session-snapshot fallback, the dead `.gitignore` entries, and every earlier CHANGELOG entry. The [3.0.0] entry's "repo unchanged" notes were true at release.

## [3.0.0] - 2026-10-09

**BREAKING — plugin renamed `turbocharge` → `turboflow`.** The Anthropic community directory already lists a different author's `turbocharge`, so this plugin migrates to the free `turboflow` slug. The plugin `name` field IS the slash-command namespace: **every `/turbocharge:<skill>` is now `/turboflow:<skill>`.** The GitHub repo, `claude plugin marketplace add nicodiansk/turbocharge` install path, homepage, and repository URL are UNCHANGED — only the plugin/marketplace NAME migrated.

### Migration guidance

**Requires Claude Code 2.1.288 or later.** Slash commands: `/turbocharge:build` → `/turboflow:build`, and likewise for every skill.

`marketplace.json` now carries `renames: {"turbocharge": "turboflow"}`, so Claude Code follows the plugin rename and rewrites `enabledPlugins`/`pluginConfigs` keys. The marketplace **name** has no such mechanism: an existing install keeps its local marketplace key, `turbocharge`. Pick one path:

- **Quick** — keep the old marketplace key:
  ```bash
  claude plugin marketplace update turbocharge
  claude plugin install turboflow@turbocharge
  ```
- **Clean (recommended)** — match the documented install id:
  ```bash
  claude plugin marketplace remove turbocharge
  claude plugin marketplace add nicodiansk/turbocharge
  claude plugin install turboflow@turboflow
  ```
  then run `/reload-plugins` in any open session. **Warning:** `marketplace remove` also uninstalls the plugin and deletes its saved options and data.

Both paths: update personal rules, permissions, and scripts naming `turbocharge:*` or `/turbocharge:<skill>` (for example `~/.claude/rules/**` and `Skill(turbocharge:…)` permission entries). Your last `/wrap` snapshot carries over: SessionStart still reads `.claude/turbocharge-session.json` when the new file is absent (3.0.x only).

### Changed
- Manifests: `plugin.json` + `marketplace.json` `name`/`displayName`/marketplace-name → turboflow; all three `version` fields → 3.0.0. URLs unchanged.
- All 6 skills, hooks, examples, `README.md`, `CLAUDE.md`: `/turbocharge:` → `/turboflow:`.
- Full brand identity: SessionStart bootstrap, `hooks.json` status message, `setup` skill self-references (prose, table headers, section titles), `validate.sh` banner, `.gitignore` comment, and colon-namespace refs (`turbocharge:build` etc.) → turboflow.
- Template renamed `templates/CLAUDE-turbocharge.md` → `templates/CLAUDE-turboflow.md`; block markers `<!-- turbocharge:NAME -->` → `<!-- turboflow:NAME -->`.
- Session snapshot file `.claude/turbocharge-session.json` → `.claude/turboflow-session.json` (wrap skill + SessionStart hook + tests).
- Brand SVGs (`hero-banner-v2`, `before-after`, `brainstorm-session`) wordmarks → turboflow.
- Tests/validator: `t_plugin_displayname.sh` name/displayName assertions, `t_setup_plugin_tooling.sh`, `validate.sh` STALE_REFS, and all session-file/marker/namespace test assertions rehomed to turboflow. New `t_no_titlecase_brand.sh` guards against title-case `Turbocharge` resurfacing in any tracked file (CHANGELOG exempt).

### Added
- `marketplace.json`: top-level `renames: {"turbocharge": "turboflow"}` so existing installs follow the plugin rename (`t_marketplace_renames.sh`).
- `hooks/agentsmd-only-nudge.md`: SessionStart shows it instead of the missing-CLAUDE.md nudge when a project has `AGENTS.md` but no `CLAUDE.md` — Claude Code reads AGENTS.md only while no CLAUDE.md exists (`t_agentsmd_nudge.sh`).
- `scripts/tests/helpers.sh`: `frontmatter` helper (CRLF-safe YAML frontmatter extraction).
- `hooks/session-start.sh`: falls back to `.claude/turbocharge-session.json` when `.claude/turboflow-session.json` is absent (3.0.x only, removed in 3.1); `wrap` writes only the new name, and `.gitignore` keeps the old name ignored for 3.0.x (`t_session_snapshot_fallback.sh`, `t_gitignore_session.sh`).

### Fixed — Claude Code 2.1.143 → 2.1.295 behavior changes
- `skills/build/SKILL.md` Step 3b: subagents now run in the background, so build waits for each builder's and task-reviewer's completion notification before the next dispatch, `BEFORE_SHA` capture, review, or completion mark. New Red Flag row. Single-track builders are dispatched without a `name`, because a named spawn becomes a teammate (`t_build_background_wait.sh`).
- `skills/plan/SKILL.md`, `skills/review/SKILL.md`: `background: false`. Forked skills run in the background since 2.1.218; plan and review must block (`t_forked_skills_block.sh`).
- `agents/{researcher,task-reviewer,code-reviewer}.md`: `Agent` added to `disallowedTools`, since subagents may nest to depth 3 by default. builder and planner keep `tools:` allowlists without Agent (`t_agent_no_nested_spawn.sh`).
- `skills/build/SKILL.md` Step 5: Agent Teams prose describes the one implicit team, `name`-param teammate spawns (`subagent_type: turboflow:builder`), and 2.1.288 as the reason plugin teammates keep the builder definition. Teammate spawn prompts must not name a model, because that overrides the builder's Sonnet pin (`t_build_multitrack_refresh.sh` updated). Full multi-track rework deferred to 3.1.
- AGENTS.md coexistence: when only AGENTS.md exists, `setup` creates CLAUDE.md with `@AGENTS.md` as its first line. When both exist and CLAUDE.md lacks the import, `setup` offers to add it. Every subagent dispatch prefix (build's builder and researcher, plan's planner, review's code-reviewer) falls back to `@AGENTS.md` when there is no CLAUDE.md (`t_setup_agentsmd.sh`, `t_dispatch_agentsmd_prefix.sh`).
- `hooks/session-start.sh`: per-section caps (ATLAS Where to Look 3,500 B, session snapshot 2,500 B, CodeMap stats 1,200 B), cut at line boundaries with a `…truncated — Read <file> for the rest` marker, keep the output under Claude Code's 10,000-char inline limit. Past that limit only a 2,000-char preview reaches the model (`t_session_start_output_cap.sh`).

### Fixed — docs and tests
- `README.md` Hooks table: removed the stale **Stop** row. The Stop hook was removed in 2.8.1 but the README still listed it (`t_claudemd_hook_ref.sh` now guards README too). The SessionStart row now mentions the AGENTS.md-aware nudge and the per-section output caps.
- `scripts/tests/t_no_titlecase_brand.sh`: no longer matches its own ABOUTME line once the file is tracked.

### Unchanged (intentional)
- GitHub repo `nicodiansk/turbocharge`, all `homepage`/`repository`/marketplace `url`, and the `marketplace add nicodiansk/turbocharge` install path.
- Historical CHANGELOG entries (2.8.1 and earlier) retain their original `/turbocharge:` references and old filenames as accurate point-in-time records.
- Dead `.gitignore` entries (`.turbocharge/…`, `turbocharge-marketplace/`) and the README Project-Structure tree label (`turbocharge/`, the git-clone dir).

## [2.8.1] - 2026-07-03

Hook fix — remove the Stop wrap-reminder hook. The 2.8.0 Stop hook emitted `hookSpecificOutput.additionalContext`, which is **not a valid Stop output field**: current Claude Code rejects it as invalid JSON, and builds that parse it as a `block` decision loop the turn until `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` force-ends it (observed in the wild). Because Stop fires at the end of *every* assistant turn, there is no non-looping way to inject a model-visible per-turn nudge; wrap guidance already ships in the SessionStart payload, so the hook is removed rather than reworked.

### Removed
- `hooks/stop-wrap-reminder.sh` and its `Stop` registration in `hooks/hooks.json` — invalid/looping Stop output (see above). Wrap is still nudged via the SessionStart Red Flags.
- `scripts/tests/t_stop_wrap_nudge.sh` — asserted the now-removed hook's output shape.

### Changed
- Roster corrected to **1 hook** (SessionStart) across `plugin.json`, `marketplace.json`, `README.md`, `CLAUDE.md`, and the hero/before-after SVGs.
- `scripts/tests/t_claudemd_hook_ref.sh`: now asserts the 1-hook inventory with no stale `Stop`/`2 hooks` references.
- Version → 2.8.1 across `plugin.json` + `marketplace.json` (both fields).

## [2.8.0] - 2026-06-25

Capability refresh — adopt Claude Code features shipped Jan–Jun 2026 (effort, maxTurns, agent-teams mechanics, displayName, context-aware Stop hook, real plugin-health tooling). Sonnet floor and version lockstep preserved; no new components.

### Added
- `agents/researcher.md`: `effort: low` + `maxTurns: 25` — bounds the fast/background explorer.
- `agents/code-reviewer.md`: `effort: high` — deeper holistic pre-merge reasoning.
- `agents/planner.md`: `effort: high` (keeps `model: inherit`).
- `agents/task-reviewer.md`: `effort: medium`.
- `.claude-plugin/plugin.json`: `displayName: "Turbocharge"` (v2.1.143+ field; `name` unchanged, marketplace lockstep unaffected).
- `hooks/stop-wrap-reminder.sh`: context-aware Stop nudge emitting `hookSpecificOutput.additionalContext` so the model is steered to OFFER `/turbocharge:wrap`, not merely printed at. Read-only.
- Content-shape tests: `t_agent_effort_caps.sh`, `t_build_multitrack_refresh.sh`, `t_plugin_displayname.sh`, `t_stop_wrap_nudge.sh`, `t_setup_plugin_tooling.sh`, `t_version_280.sh`, `t_changelog_280.sh`.

### Changed
- `skills/build/SKILL.md` (Step 5): replaced stale "Create team"/`TeamCreate`/`TeamDelete` prose with current Agent Teams mechanics — `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` gate, natural-language teammate spawn referencing the `builder` subagent by name (honors its `model`/`tools`, NOT its `skills`/`mcpServers`), file-ownership conflict avoidance, automatic session-end cleanup. Documented the builder no-self-isolation decision (worktree branches from default branch + only auto-cleans when unchanged → would break the `BEFORE_SHA..HEAD` reviewer diff; worktree management stays in skill prose).
- `hooks/hooks.json`: Stop now runs `stop-wrap-reminder.sh` instead of `cat`-ing the prose file.
- `skills/setup/SKILL.md`: plugin health/conflict audit now uses `claude plugin details turbocharge` and `claude plugin list --json`, and scans for competing orchestration plugins (not just `~/.claude/agents/`). `disable-model-invocation: true` retained.
- Version → 2.8.0 across `plugin.json` + `marketplace.json` (both fields).

### Removed
- `hooks/stop-wrap-reminder.md` — superseded by the structured `.sh` hook.

## [2.7.3] - 2026-06-23

Description consistency — every project-level description now states the full roster.

### Changed
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`: plugin description now reads "10 skills, 5 agents, 2 hooks" (hooks count added) so the manifest, marketplace, and the GitHub About all agree on the roster.

## [2.7.2] - 2026-06-23

Directory-readiness — leaner SessionStart payload, read-only hook attestation.

### Changed
- `hooks/session-bootstrap.md`: replaced the 10-row skill table with a one-line pipeline summary + `/help` pointer. Standing per-session context cost ~434 → ~306 tokens (~30% lighter; the skill table duplicated descriptions Claude Code already loads). Red Flags and Critical Rules retained — they add anti-rationalization behavior Claude Code's skill descriptions don't. All 10 skills still named (pipeline line + red flags).
- `hooks/session-start.sh`: header now attests the hook is read-only (stdout only, no writes, no network) for plugin-directory safety screening.

## [2.7.1] - 2026-06-23

README visuals refresh — value/positioning diagram, terminal mockups, accurate build chain.

### Added
- `images/before-after.svg`: scattered-config vs. single-pipeline diagram, embedded under the README intro.
- `images/brainstorm-session.svg`: hand-authored terminal mockup of a brainstorm session (announce → dialogue → captured doc → chain-forward).
- `images/build-review-chain.svg`: accurate SVG of default vs. `--reviewed` task execution (2–6 spawns/task on the failure path); replaces the ASCII diagrams in "How Build Works".
- `README.md`: "Why a Pipeline" section sharpening the positioning.
- `scripts/tests/t_svg_roster_counts.sh`: asserts each SVG's "N skills · N agents · N hooks" tagline matches ground truth (skills/agents from `plugin.json`, hooks from `hooks.json`) — guards against the next stale-count regression.

### Changed
- `CLAUDE.md`: document the planner's deliberate `model: inherit` carve-out (rides the orchestrator model, ≥ Sonnet in normal use) so it no longer reads as a contradiction of the Sonnet-floor rule.

### Fixed
- `images/hero-banner-v2.svg`: agent count corrected 6 → 5 (missed in the 2.7.0 roster update; now matches `plugin.json` and the README badge).

### Removed
- `images/build-review-chain.png` (orphaned and stale — depicted the `spec-reviewer`/`quality-reviewer` agents removed in 2.7.0) and `images/story-output.png` (orphaned, unreferenced). Replaced by version-controlled SVGs.

## [2.7.0] - 2026-06-23

Lean review pipeline — planner self-review, single Sonnet task-reviewer, Sonnet floor, build UX.

### Added
- `agents/planner.md`: mandatory Spec Self-Review 3-point checklist (spec coverage + add missing tasks, placeholder scan, type consistency) run inline before the plan is written.
- `agents/task-reviewer.md` (NEW, Sonnet): reads a task diff once and emits two verdicts — `Spec: ✅/❌` and `Quality: Approved/Issues found`. Replaces the spec-reviewer + quality-reviewer pair.
- `skills/build/SKILL.md`: `--checkpoint=N` flag (default 3; `0` / `--no-checkpoint` disables the batch wait) and a per-batch + completion visibility line (`agents spawned: A · models: sonnet×A · tasks: X/Y`).
- `CLAUDE.md`: "Sonnet minimum, never Haiku" agent-model convention.

### Changed
- `agents/researcher.md`: model changed from Haiku to Sonnet.
- `skills/build/SKILL.md`: Reviewed mode now spawns one Sonnet task-reviewer per task (two verdicts, one diff-load) instead of two reviewers — 2 spawns/task instead of 3.
- `README.md`, `images/model-tiering.svg`: updated to the Sonnet-floor roster; agent count 6 → 5.

### Removed
- `agents/spec-reviewer.md` and `agents/quality-reviewer.md` (merged into `task-reviewer`).

### Performance
- Reviewed build: 2 spawns per task (was 3), all Sonnet. One diff-load instead of two.
- No agent runs Haiku — turn count beats token price.

## [2.6.1] - 2026-05-20

Fix: session snapshot always on first line of resume prompt.

### Fixed
- `skills/wrap/SKILL.md`: `@.claude/turbocharge-session.json` moved from "Context Files" list onto the first line of the resume prompt template — it is now fixed and mandatory, not a variable placeholder. Added explicit MANDATORY note to prevent Claude from omitting it.

## [2.6.0] - 2026-05-20

Lean Builder v3 — simpler, faster, cheaper build pipeline.

### Changed
- `agents/builder.md`: model changed from inherit (Opus) to Sonnet; worktree isolation removed — builder works in main tree.
- `agents/spec-reviewer.md`: model changed from inherit to Haiku.
- `agents/quality-reviewer.md`: model changed from inherit to Haiku.
- `agents/code-reviewer.md`: model changed from inherit to Sonnet.
- `skills/build/SKILL.md`: review chain (spec-reviewer + quality-reviewer) now opt-in via `--reviewed` flag, not mandatory. Default mode is builder-only with self-review. Leaner dispatch — plan file:line pointers instead of context dumps. Frontmatter description and argument-hint updated.

### Performance
- Default build: 1 agent spawn per task (was 3-5). ~70% token reduction.
- Reviewed build: 3 spawns per task on Haiku/Sonnet (was 3-5 on Opus). ~30% additional token + cost reduction.
- Builder runs on Sonnet (98% of Opus coding capability at 1/5 cost, 2x speed).
- No worktree overhead.

## [2.5.2] - 2026-04-22

CodeMap + ATLAS enforcement at session start and wrap.

### Changed
- `hooks/session-start.sh`: injects CodeMap stats and usage reminder when `.codemap/` index is present — models now see the index on every session start, same as ATLAS.
- `skills/wrap/SKILL.md`: `@ATLAS.md` added to resume prompt template (was `@CLAUDE.md` only); section 5.5 Atlas Freshness made mandatory — always run `/turbocharge:atlas` and `codemap update` before ending a session, not conditional on "significant changes".

## [2.5.1] - 2026-04-15

Token waste fix for planner and researcher agents.

### Changed
- `planner.md`: replaced "read ATLAS.md first" with "do NOT re-read @-referenced files" — eliminates redundant ATLAS.md read on every plan invocation.
- `researcher.md`: same "do not re-read @-referenced files" instruction.
- `skills/plan/SKILL.md`: added token discipline rule — dispatch sends paths and line ranges only, not file contents (matches build skill pattern from v2.5.0).

## [2.5.0] - 2026-04-15

ATLAS gets smarter; token overhead trimmed.

### Added
- Lazy-load: SessionStart pre-loads only the Where to Look table; remaining sections available via Read on demand.
- Staleness detection: atlas generation writes a directory-listing hash (`<!-- atlas-hash:XXXX -->`); SessionStart compares it and nudges re-run if structure changed.
- Codemap integration: `/turbocharge:atlas` reads `.codemap/` JSON index (when present) to auto-populate Key Symbols and Module Map, cutting generation cost from ~20 tool calls to ~5.
- Setup audit: `/turbocharge:setup` now checks for global rules that duplicate turbocharge behavior and suggests consolidation.

### Changed
- `planner`, `researcher`, `code-reviewer` agents updated to reflect lazy-load (Where to Look in context, full file on demand).
- ATLAS.md template now includes `<!-- atlas-hash:XXXX -->` footer comment.
- Build skill: builder dispatch sends file paths + line ranges instead of full code blocks (~1-3K tokens saved per task).
- Debug skill: trimmed from 10.7KB to <7KB — removed verbose examples, redundant tables, meta-commentary.
- CLAUDE.md: ATLAS.md term updated to reflect lazy-load and staleness detection.

## [2.4.0] - 2026-04-14

ATLAS becomes core navigation layer; CLAUDE.md bootstrap gets a coherent chain.

### Added
- ATLAS pre-load: SessionStart hook cats `ATLAS.md` (if present) into context every session — navigation lookups cost zero tool calls after turn 1.
- Session snapshot: `/wrap` writes `.claude/turbocharge-session.json`; SessionStart cats it for zero-tool-call resume.
- `CLAUDE.md bootstrap` phase in `/turbocharge:setup` — auto-detects language/test command/package manager, asks ≤5 skippable questions, writes HTML-comment-delimited idempotent blocks.
- `templates/CLAUDE-turbocharge.md` — default values for the setup interview.
- `scripts/validate-atlas.sh` — ATLAS.md format check; wired into `scripts/validate.sh`.
- `scripts/tests/` — shell-based content-shape test harness.
- Memory discipline in `/wrap`: confidence+source metadata on bullets, 200-line cap with prune-before-build, session snapshot JSON.

### Changed
- ATLAS.md format reshaped to lookup-first tables (Where to Look, Entry Points, Module Map, Key Symbols, Integration Points, Conventions & Gotchas). Data Flows / Domain Model / Active Work sections removed.
- `planner`, `researcher`, `code-reviewer` agents now explicitly read ATLAS.md before exploration.
- `/turbocharge:plan` and `/turbocharge:review` inject `@ATLAS.md` + `@CLAUDE.md` into subagent dispatch prompts (subagents do not inherit parent history).
- `/turbocharge:build` injects `@CLAUDE.md` into builder/reviewer dispatches; only the on-demand researcher sub-dispatch gets `@ATLAS.md`.
- `hooks/missing-claudemd-nudge.md` tightened from 30 lines of manual copy-paste to a 2-line `/init → /turbocharge:setup` chain.
- `hooks/missing-atlasmd-nudge.md` tightened; notes pre-load behavior.
- `CLAUDE.md` (this repo) demoted inaccurate ATLAS claim to match new pre-load+dispatch-inject wording.

### Removed
- `PreToolUse` Read hook + `hooks/pretool-read-codemap.sh` — redundant once ATLAS is pre-loaded on every session.

### Migration
- Existing users: re-run `/turbocharge:atlas` to regenerate ATLAS.md in the new lookup-first format. Old ATLAS files still work but won't match the expected headers.

## [2.3.0] - 2026-04-13

Single-repo distribution — plugin and marketplace manifest now live together.

### Changed
- Restored `.claude-plugin/marketplace.json` as the authoritative marketplace manifest (previously in sibling `nicodiansk/turbocharge-marketplace` repo)
- Install command: `claude plugin marketplace add nicodiansk/turbocharge` (was `nicodiansk/turbocharge-marketplace`)
- Update command: `claude plugin update turbocharge@turbocharge` (was `turbocharge@turbocharge-marketplace`)
- README rewritten: ruflo-inspired structure, with vs without comparison, progressive disclosure via collapsible deep-dives
- CLAUDE.md Publishing Flow collapsed from 6 steps across 2 repos to 3 steps in one repo

### Removed
- Sibling `nicodiansk/turbocharge-marketplace` repo deleted — no longer needed

### Migration
- Existing users must re-add the marketplace: `claude plugin marketplace remove turbocharge-marketplace` then `claude plugin marketplace add nicodiansk/turbocharge`

## [2.2.0] - 2026-04-10

New skill: semantic domain mapping.

### Added
- `atlas` skill — generates and maintains ATLAS.md, a semantic domain map covering entry points, data flows, domain model, module purposes, integration points, and conventions
- Pipeline integration: session-bootstrap lists atlas, plan skill reads ATLAS.md for context, wrap skill nudges atlas refresh, setup skill checks for ATLAS.md

### Changed
- Plugin description updated to "10 skills, 6 agents"
- README updated with atlas documentation and revised pipeline diagram
- .gitignore updated to exclude `.codemap/` directory

## [2.1.0] - 2026-04-09

Pipeline hardening and operational discipline — driven by 91 sessions of real usage.

### Added
- `setup` skill — one-time config audit that finds duplicate agents, competing skills, and stale rules; offers to clean them up
- SessionStart hook — bootstraps skill awareness so Claude knows the pipeline exists from the first message
- Stop hook — reminds users to run `/turbocharge:wrap` before ending a session
- Anti-rationalization "Red Flags" tables in build, review, and debug skills — catches Claude skipping process steps
- Mandatory domain verification step in builder and planner agents

### Changed
- `wrap` skill now encodes session learnings into memory files and CLAUDE.md (not just resume prompts)
- README rewritten with install/usage/architecture sections
- CLAUDE.md updated with full plugin conventions and domain terms
- validate.sh now recognizes the `setup` skill and fixes a bash arithmetic bug with `((VAR++))` under `set -e`

### Removed
- `docs/power-user-guide.md` — content migrated to global rules and blog post draft

## [2.0.0] - 2026-03-19

Complete rebuild on native Claude Code primitives.

### Changed
- Rebuilt all agents as native subagents with `memory: project`, tool restrictions, and isolation
- Replaced 16 skills with 8 focused skills: brainstorm, story, plan, build, review, debug, ship, wrap
- Replaced custom `.turbocharge/memory/` system with native `memory: project` on all agents
- Replaced session-manager agent with `/turbocharge:wrap` skill
- Replaced baton-passing workflow with native subagent dispatch and Agent Teams
- Builder agent now runs in isolated worktree (`isolation: worktree`)
- TDD enforcement baked into builder agent (no longer a separate skill)
- Plugin manifest updated to v2.0.0

### Added
- `build` skill — orchestrates builder→spec-reviewer→quality-reviewer review chain
- `wrap` skill — session continuity with resume prompts
- `researcher` agent — fast, read-only codebase exploration (haiku model, background)
- Agent Teams support for multi-track parallel execution
- Stop hook reminding users to wrap sessions
- `settings.json` enabling experimental Agent Teams
- `marketplace.json` for self-hosted distribution
- `scripts/validate.sh` for plugin health checks
- `examples/` directory with sample pipeline outputs

### Removed
- 10 slash commands (skills now serve as commands via `/turbocharge:skillname`)
- `lib/skills-core.js` (custom skill dispatch infrastructure)
- `hooks/session-start.sh` (replaced by Stop hook)
- Agents: implementer (→ builder), story-writer (→ story skill), session-manager (→ wrap skill)
- Skills: using-turbocharge, session-memory, dispatching-parallel-agents, subagent-driven-development, verification-before-completion, receiving-code-review, test-driven-development, executing-plans, writing-skills, using-git-worktrees

## [1.0.0] - 2026-02-11

Initial release. 16 skills, 7 agents, 10 commands with baton-passing orchestration workflow.
