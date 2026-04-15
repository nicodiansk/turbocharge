# v2.5.0 — ATLAS Improvements + Token Overhead Reduction

**Goal:** Make ATLAS cheaper to generate, smarter on startup, aware of its own staleness — and cut token waste from builder dispatch and bloated skill prompts.
**Architecture:** Five independent features: (1) lazy-load only the Where to Look table on SessionStart, (2) staleness detection via directory-listing hash, (3) codemap integration for atlas generation, (4) trim builder dispatch to avoid code duplication, (5) trim debug skill and add global-rules overlap audit to setup.
**Tech Stack:** Bash (hooks, scripts), Markdown (skills, agents). No new runtime dependencies. jq optional for codemap JSON reading (graceful fallback to grep/awk).

---

## Decisions

- **Lazy-load boundary:** Extract from `# ATLAS` through the end of `## Where to Look` table (up to the next `## ` header). Everything else is on-demand via `Read ATLAS.md`.
- **Hash storage:** Append a `<!-- atlas-hash:XXXX -->` HTML comment to the last line of ATLAS.md. No sidecar files.
- **Hash algorithm:** `ls -1 | grep -v (ignored dirs) | sort | md5sum | cut -c1-12`. Cheap, catches new/deleted top-level dirs and files.
- **Codemap integration:** Optional. If `.codemap/.codemap.json` exists, atlas skill instructs Claude to read it and use the data. No Python dependency — Claude reads the JSON directly via the Read tool.
- **Builder dispatch trim:** Send file paths + line ranges in dispatch prompt, not full code blocks. Builders read files via worktree anyway (domain verification is mandatory). Saves ~1,000-3,000 tokens per task dispatch.
- **Debug skill trim:** Cut from 10.7KB to <7KB by removing verbose examples, redundant tables, and sections that overlap with builder.md.
- **Setup audit extension:** Add global-rules overlap check to the setup skill. Detects when `~/.claude/rules/common/` files duplicate turbocharge behavior and suggests consolidation.
- **Test convention:** Bash+grep only (no python3). Matches v2.4.0 pattern.

---

## Task List

### Task 1: Lazy-load — extract Where to Look section in session-start.sh

**Files:**
- Modify: `hooks/session-start.sh`

**What to do:**
Replace `cat "ATLAS.md"` with an awk one-liner that extracts from line 1 through the end of the `## Where to Look` section (stopping at the next `## ` header). After the extracted section, output a one-liner hint.

**Before (lines 9-13):**
```bash
if [ -f "ATLAS.md" ]; then
    echo ""
    echo "--- ATLAS.md (pre-loaded for zero-tool-call navigation) ---"
    cat "ATLAS.md"
    echo "--- end ATLAS.md ---"
```

**After:**
```bash
if [ -f "ATLAS.md" ]; then
    echo ""
    echo "--- ATLAS.md (Where to Look — pre-loaded) ---"
    awk '/^## Where to Look/{found=1} found && /^## [^W]/{exit} {print}' "ATLAS.md"
    echo ""
    echo "(Full ATLAS.md available via Read — contains Module Map, Key Symbols, Integration Points, Conventions & Gotchas)"
    echo "--- end ATLAS.md ---"
```

**Verify:** `bash -n hooks/session-start.sh` — syntax ok. `bash scripts/validate.sh` — exit 0.

---

### Task 2: Lazy-load — update test to expect partial output

**Files:**
- Modify: `scripts/tests/t_session_start_cat_atlas.sh`

**What to do:**
The current test creates a minimal fixture ATLAS.md with `UNIQUE_ATLAS_MARKER_37812` and checks that session-start.sh outputs it. After Task 1, the hook only outputs through the Where to Look section. Update the fixture to put the marker inside Where to Look, add a marker in Module Map that should NOT appear, and assert the hint line is present.

**Replace the fixture creation (lines 9-12) and assertion (line 15) with:**
```bash
cat > ATLAS.md <<'EOF'
# ATLAS — Fixture

## Where to Look

| I want to... | Open | Why |
|--------------|------|-----|
| Find the marker | `marker.txt` | UNIQUE_ATLAS_MARKER_37812 |

## Module Map

| Directory | Purpose | Key files |
|-----------|---------|-----------|
| `src/` | UNIQUE_MODULE_MARKER_55555 | `foo.ts` |
EOF
OUT="$(bash "$F" 2>&1 || true)"
cd - >/dev/null
echo "$OUT" | grep -q "UNIQUE_ATLAS_MARKER_37812" || { echo "    session-start.sh did not output Where to Look section"; rm -rf "$TMP"; exit 1; }
echo "$OUT" | grep -q "UNIQUE_MODULE_MARKER_55555" && { echo "    session-start.sh leaked Module Map (should be lazy)"; rm -rf "$TMP"; exit 1; }
echo "$OUT" | grep -q "Full ATLAS.md available" || { echo "    session-start.sh missing lazy-load hint"; rm -rf "$TMP"; exit 1; }
```

Keep the session snapshot test (lines 17-25) unchanged.

**Verify:** `bash scripts/tests/run.sh` — all tests pass.

---

### Task 3: Staleness hash — write hash on atlas generation

**Files:**
- Modify: `skills/atlas/SKILL.md`

**What to do:**
Two changes:

1. Add `## Step 5: Write Staleness Hash` between "Step 4: ATLAS.md Format" (after its closing constraint/removed/added notes at line 98) and "## What NOT to Include" (line 100). Insert at line 99:

```markdown
## Step 5: Write Staleness Hash

After writing ATLAS.md, compute a directory-listing hash and append it as an HTML comment on the very last line:

```bash
HASH=$(ls -1 | grep -v -e '^\.codemap$' -e '^node_modules$' -e '^\.git$' -e '^__pycache__$' -e '^\.venv$' -e '^venv$' -e '^dist$' -e '^build$' | sort | md5sum | cut -c1-12)
echo "<!-- atlas-hash:$HASH -->" >> ATLAS.md
```

This hash is checked by the SessionStart hook to detect structural changes. If the user adds or removes top-level files/directories, the hash will mismatch and the hook will nudge a re-run.
```

2. Inside the ATLAS.md format template in Step 4 (line 92, after the `📌` comment), add as the last line of the template:
```
<!-- atlas-hash:XXXXXXXXXXXX -->
```

**Verify:** `bash scripts/validate.sh` — exit 0.

---

### Task 4: Staleness check — add hash comparison to session-start.sh

**Files:**
- Modify: `hooks/session-start.sh`

**What to do:**
After the ATLAS pre-load block (after `echo "--- end ATLAS.md ---"` / the `fi` closing the ATLAS block), and before the session snapshot block (line 19: `if [ -f ".claude/turbocharge-session.json" ]`), add:

```bash
# Staleness check
if [ -f "ATLAS.md" ]; then
    STORED=$(sed -n 's/.*<!-- atlas-hash:\([a-f0-9]*\) -->.*/\1/p' "ATLAS.md" 2>/dev/null || true)
    if [ -n "$STORED" ]; then
        if command -v md5sum >/dev/null 2>&1; then
            CURRENT=$(ls -1 | grep -v -e '^\.' -e '^node_modules$' -e '^__pycache__$' -e '^venv$' -e '^dist$' -e '^build$' | sort | md5sum | cut -c1-12)
        elif command -v md5 >/dev/null 2>&1; then
            CURRENT=$(ls -1 | grep -v -e '^\.' -e '^node_modules$' -e '^__pycache__$' -e '^venv$' -e '^dist$' -e '^build$' | sort | md5 -r | cut -c1-12)
        else
            CURRENT=""
        fi
        if [ -n "$CURRENT" ] && [ "$STORED" != "$CURRENT" ]; then
            echo ""
            echo "ATLAS.md may be stale — project structure changed since last generation. Consider running /turbocharge:atlas to update."
        fi
    fi
fi
```

Uses `sed` instead of `grep -oP` for portability (macOS has no PCRE grep). Uses `md5 -r` fallback for macOS.

**Verify:** `bash -n hooks/session-start.sh` — syntax ok. `bash scripts/validate.sh` — exit 0.

---

### Task 5: Staleness check — add test

**Files:**
- Create: `scripts/tests/t_atlas_staleness.sh`

**What to do:**
```bash
#!/usr/bin/env bash
# ABOUTME: Tests that session-start.sh detects stale ATLAS.md via hash mismatch.
# ABOUTME: Also verifies graceful skip when no hash comment present.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
assert_file "$F" || exit 1

# Test 1: Wrong hash → staleness warning
TMP="$(mktemp -d)"; cp "$PLUGIN_DIR/hooks/"*.md "$TMP/" 2>/dev/null || true
cd "$TMP"
cat > ATLAS.md <<'EOF'
# ATLAS — Fixture

## Where to Look

| I want to... | Open | Why |
|--------------|------|-----|
| Test | `test.txt` | test |

<!-- atlas-hash:000000000000 -->
EOF
OUT="$(bash "$F" 2>&1 || true)"
cd - >/dev/null
echo "$OUT" | grep -qi "stale\|structure changed" || { echo "    no staleness warning for mismatched hash"; rm -rf "$TMP"; exit 1; }

# Test 2: No hash → no warning
cd "$TMP"
cat > ATLAS.md <<'EOF'
# ATLAS — Fixture

## Where to Look

| I want to... | Open | Why |
|--------------|------|-----|
| Test | `test.txt` | test |
EOF
OUT="$(bash "$F" 2>&1 || true)"
cd - >/dev/null
rm -rf "$TMP"
echo "$OUT" | grep -qi "stale\|structure changed" && { echo "    false staleness warning when no hash present"; exit 1; }
```

**Verify:** `bash scripts/tests/run.sh` — all tests pass.

---

### Task 6: Codemap integration — add optional step to atlas skill

**Files:**
- Modify: `skills/atlas/SKILL.md`

**What to do:**
Add a new section after "## Step 2: Read the Codebase" (after line 33) and before "## Step 3: Generate or Update" (line 35):

```markdown
### Step 2b: Read Codemap Index (if available)

If `.codemap/.codemap.json` exists in the project root:

1. Read `.codemap/.codemap.json` — it contains a manifest with `directories` (list of indexed paths) and `stats` (total files, total symbols).
2. For each directory in the manifest, read `.codemap/<dir>/.codemap.json` — each contains `files` with symbol entries (name, type, lines, language).
3. Use this data to pre-populate:
   - **Module Map** — each directory with its file count and key files
   - **Key Symbols** — pick the 20-30 most important symbols (classes, exported functions) with their `file:line-range`
4. You still need to fill in the semantic layer manually: **Where to Look** (intent→file mapping), **Entry Points** (which files boot the app), **Integration Points** (external services), **Conventions & Gotchas**.

This shortcut reduces atlas generation from ~20 tool calls to ~5. If `.codemap/` does not exist, skip this step entirely — fall through to the standard codebase scan in Step 2.
```

**Verify:** `bash scripts/validate.sh` — exit 0.

---

### Task 7: Codemap integration — add test

**Files:**
- Create: `scripts/tests/t_atlas_codemap_integration.sh`

**What to do:**
```bash
#!/usr/bin/env bash
# ABOUTME: Tests that atlas SKILL.md contains codemap integration instructions.
# ABOUTME: Verifies .codemap reference, Module Map/Key Symbols mentions, and graceful fallback.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/atlas/SKILL.md"
assert_file "$F" || exit 1
assert_grep "$F" "\.codemap/\.codemap\.json" || exit 1
assert_grep "$F" "Module Map"                 || exit 1
assert_grep "$F" "Key Symbols"                || exit 1
assert_grep "$F" "skip this step"             || exit 1
```

**Verify:** `bash scripts/tests/run.sh` — all tests pass.

---

### Task 8: Update agents to reference lazy-load behavior

**Files:**
- Modify: `agents/planner.md`
- Modify: `agents/researcher.md`
- Modify: `agents/code-reviewer.md`

**What to do:**

**planner.md line 20** — replace:
```
0. **Read ATLAS.md first** — if `ATLAS.md` exists in the project root, read it before exploring. Its Where-to-Look table maps intent→file and saves token-expensive searches. Treat it as the navigation index for this project.
```
with:
```
0. **ATLAS.md** — the Where to Look table is pre-loaded in context when ATLAS.md exists. For Module Map, Key Symbols, or Integration Points, read the full ATLAS.md file.
```

**researcher.md line 21** — replace:
```
0. **Read ATLAS.md first** — if it exists in the project root, it is the authoritative Where-to-Look table. Start there; it saves most broad-search tool calls.
```
with:
```
0. **ATLAS.md** — the Where to Look table is pre-loaded in context when ATLAS.md exists. Read the full file only if you need Module Map, Key Symbols, or deeper navigation.
```

**code-reviewer.md lines 20-23** — replace:
```
0. **Read ATLAS.md first**
   - If `ATLAS.md` exists, read it before reviewing the diff.
   - Use its Module Map and Key Symbols tables to identify which modules the diff touches and what their role is.
   - Flag any divergence between the diff and ATLAS — either the diff is wrong or ATLAS is stale.
```
with:
```
0. **ATLAS.md** — the Where to Look table is pre-loaded in context when ATLAS.md exists. Read the full ATLAS.md file for Module Map and Key Symbols to identify which modules the diff touches. Flag any divergence between the diff and ATLAS.
```

**Verify:** `bash scripts/tests/run.sh` — `t_agent_atlas_refs.sh` must still pass (it checks for "ATLAS" references and "read.*ATLAS" or "ATLAS.*first" patterns). The new text contains "ATLAS" and "Read the full ATLAS.md file" which will match `grep -qi "read.*ATLAS"`.

---

### Task 9: Trim builder dispatch — send paths, not code

**Files:**
- Modify: `skills/build/SKILL.md`

**What to do:**
Replace Step 3a (lines 54-59):
```markdown
### 3a. Dispatch Builder
Spawn builder subagent with:
- Task number and full task text from plan
- Context: where this task fits, what's already done, architecture
- Working directory
- Prefix the builder's dispatch prompt with `@CLAUDE.md` (conventions). Do NOT inject `@ATLAS.md` here — builders read the spec and diff, not the navigation index.
```

with:
```markdown
### 3a. Dispatch Builder
Spawn builder subagent with:
- Task number and task description (objective, file paths, line ranges, verification commands)
- Do NOT paste full code blocks from the plan — builders read the actual files in their worktree. Duplicating code in the dispatch wastes ~1-3K tokens per task.
- Context: where this task fits in the sequence, what previous tasks completed
- Working directory
- Prefix the dispatch prompt with `@CLAUDE.md` (conventions). Do NOT inject `@ATLAS.md` here — builders read the spec and diff, not the navigation index.
```

**Verify:** `bash scripts/validate.sh` — exit 0.

---

### Task 10: Trim debug SKILL.md — cut from 10.7KB to <7KB

**Files:**
- Modify: `skills/debug/SKILL.md`

**What to do:**
The debug skill is 10,727 bytes (319 lines) — 2x the next largest skill. Cut to <7KB by:

1. **Remove "When to Use" section (lines 24-45)** — 22 lines of "use for ANY technical issue" and "use ESPECIALLY when" and "don't skip when" that state the obvious. The skill description + Iron Law already cover this.

2. **Remove "Phase 1, Step 4: Gather Evidence in Multi-Component Systems" example (lines 76-108)** — 32 lines of bash examples for a specific debugging scenario (keychain/signing). Replace with a 3-line instruction:
```markdown
4. **Gather Evidence at Component Boundaries**
   For multi-component systems: log what enters and exits each component. Run once to find WHERE it breaks, then investigate that specific component.
```

3. **Remove "Your Human Partner's Signals" section (lines 234-243)** — 10 lines. Unnecessary meta-commentary.

4. **Remove "Real-World Impact" section (lines 312-319)** — 8 lines of statistics that don't help Claude debug.

5. **Remove "Supporting Techniques" section (lines 279-285)** — 7 lines referencing companion .md files. Those files exist in the directory; Claude can discover them if needed.

6. **Condense "Common Rationalizations" table (lines 245-257)** — merge with "Red Flags" section (lines 215-232) into a single table. Remove duplicate entries between the two tables.

Target: <7,000 bytes (~200 lines).

**Verify:** `bash scripts/validate.sh` — exit 0. `wc -c skills/debug/SKILL.md` — under 7000.

---

### Task 11: Setup skill — add global rules overlap audit

**Files:**
- Modify: `skills/setup/SKILL.md`

**What to do:**
In "### 6. Check Global Rules Alignment" (lines 86-93), add a new subsection after the existing alignment checks:

```markdown
### 7. Check for Global Rules / Turbocharge Overlap

Scan `~/.claude/rules/common/` for files that duplicate what turbocharge skills already enforce:

| Global Rule File | Overlaps With | Recommendation |
|------------------|---------------|----------------|
| `agents.md` | turbocharge pipeline (SessionStart bootstrap) | Keep only the "Primary System: Turbocharge Plugin" header + pipeline table. Remove agent dispatch details — turbocharge skills handle dispatch. |
| `development-workflow.md` | turbocharge:plan, turbocharge:build | Remove TDD steps and plan-first sections — builder.md and planner.md enforce these. Keep only git workflow and research steps. |
| `testing.md` | builder.md TDD mandate | Remove TDD workflow section — builder.md is the single source. Keep coverage targets and test types. |

**Action:** For each overlap found, show the user what's duplicated and offer to trim. Don't delete files — trim the overlapping sections and keep unique content.

**Why this matters:** Every global rule file is loaded into context on every turn (~4 bytes/token). Duplicate instructions between rules and turbocharge skills waste ~2,000 tokens per session and can cause conflicting guidance.
```

Also renumber the existing "After Setup" and "Red Flags" sections to account for the new step 7.

**Verify:** `bash scripts/validate.sh` — exit 0.

---

### Task 12: Update agents to reference lazy-load in ATLAS.md CLAUDE.md term

**Files:**
- Modify: `CLAUDE.md`

**What to do:**
The ATLAS.md domain term definition (line 56) currently says "Pre-loaded into context by the SessionStart hook". Update to reflect lazy-load:

Replace:
```
| **ATLAS.md** | Semantic domain map generated by `/turbocharge:atlas` in user projects (Where to Look, Entry Points, Module Map, Key Symbols, Integration Points, Conventions & Gotchas). **Pre-loaded into context by the SessionStart hook** when present; **injected into dispatch prompts** for planner, researcher, and code-reviewer agents; nudged by SessionStart when absent. This plugin repo intentionally does NOT ship one — CLAUDE.md + README cover the same ground for a plugin blueprint. |
```

with:
```
| **ATLAS.md** | Semantic domain map generated by `/turbocharge:atlas` in user projects (Where to Look, Entry Points, Module Map, Key Symbols, Integration Points, Conventions & Gotchas). **Where to Look table pre-loaded by SessionStart hook** (remaining sections available via Read on demand); **injected into dispatch prompts** for planner, researcher, and code-reviewer agents; nudged by SessionStart when absent; staleness detected via `<!-- atlas-hash:XXXX -->` footer. This plugin repo intentionally does NOT ship one — CLAUDE.md + README cover the same ground for a plugin blueprint. |
```

**Verify:** `bash scripts/tests/run.sh` — `t_claudemd_atlas_claim.sh` must still pass.

---

### Task 13: Version bump + CHANGELOG

**Files:**
- Modify: `.claude-plugin/plugin.json` — version → `"2.5.0"`
- Modify: `.claude-plugin/marketplace.json` — `metadata.version` → `"2.5.0"`, `plugins[0].version` → `"2.5.0"`
- Modify: `CHANGELOG.md` — add v2.5.0 entry at the top

**CHANGELOG entry:**
```markdown
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
```

**Verify:** `bash scripts/validate.sh` — exit 0.

---

### Task 14: Update version test

**Files:**
- Rename: `scripts/tests/t_version_240.sh` → `scripts/tests/t_version_250.sh`

**What to do:**
Create new file `t_version_250.sh` with content identical to current `t_version_240.sh` but with `2.4.0` replaced by `2.5.0` everywhere. Delete `t_version_240.sh`.

```bash
#!/usr/bin/env bash
# ABOUTME: Tests that plugin.json and marketplace.json are both at version 2.5.0.
# ABOUTME: Checks all three version fields are in lockstep.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
M="$PLUGIN_DIR/.claude-plugin/marketplace.json"
assert_file "$P" || exit 1
assert_file "$M" || exit 1
if command -v jq >/dev/null 2>&1; then
    jq -e '.version == "2.5.0"' "$P" >/dev/null || { echo "    plugin.json version != 2.5.0"; exit 1; }
    jq -e '.metadata.version == "2.5.0"' "$M" >/dev/null || { echo "    marketplace.json metadata.version != 2.5.0"; exit 1; }
    jq -e '.plugins[0].version == "2.5.0"' "$M" >/dev/null || { echo "    marketplace.json plugins[0].version != 2.5.0"; exit 1; }
else
    grep -q '"version": "2\.5\.0"' "$P" || { echo "    plugin.json version"; exit 1; }
    grep -q '"version": "2\.5\.0"' "$M" || { echo "    marketplace.json version"; exit 1; }
fi
```

**Verify:** `bash scripts/tests/run.sh` — all tests pass.

---

### Task 15: Update CHANGELOG test

**Files:**
- Rename: `scripts/tests/t_changelog_240.sh` → `scripts/tests/t_changelog_250.sh`

**What to do:**
Create new file `t_changelog_250.sh` that checks for the v2.5.0 entry. Drop v2.4.0 assertions (they test an old version).

```bash
#!/usr/bin/env bash
# ABOUTME: Tests CHANGELOG.md has a [2.5.0] entry with required keywords.
# ABOUTME: Verifies lazy-load, staleness, codemap, and overhead reduction.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[2\.5\.0\]" "$F" || { echo "    missing [2.5.0] entry"; exit 1; }
assert_grep "$F" "Lazy-load"               || exit 1
assert_grep "$F" "Staleness detection"      || exit 1
assert_grep "$F" "Codemap integration"      || exit 1
assert_grep "$F" "Debug skill"              || exit 1
```

Delete `t_changelog_240.sh`.

**Verify:** `bash scripts/tests/run.sh` — all tests pass.

---

## Execution Order

```
Group A (lazy-load):     Task 1 → Task 2
Group B (staleness):     Task 3 → Task 4 → Task 5
Group C (codemap):       Task 6 → Task 7
Group D (agents):        Task 8
Group E (overhead):      Task 9 → Task 10 → Task 11
Group F (bookkeeping):   Task 12 → Task 13 → Task 14 → Task 15
```

**Dependencies:**
- Groups A-E are independent — can be parallelized.
- Group F depends on all of A-E completing first (version bump + CHANGELOG must reflect all changes).
- Within each group, tasks are sequential.

**Recommended execution:** Run Groups A, B, C in parallel (they touch different files). Then D, then E. Finally F.

## Assumptions

1. `md5sum` is available on the user's system (it is on Linux, Git Bash for Windows). The hook includes a macOS fallback using `md5 -r`.
2. `awk` is available (standard on all targets — Linux, macOS, Git Bash/MINGW64).
3. `sed -n 's/.../p'` works portably (POSIX sed). Used instead of `grep -oP` which requires PCRE.
4. The `<!-- atlas-hash:XXXX -->` comment at the end of ATLAS.md will not be stripped by markdown renderers (HTML comments are preserved by all major renderers).
5. `.codemap/.codemap.json` format matches what AZidan/codemap produces (verified from source code in prior session).
6. Debug skill can be cut to <7KB without losing essential phase structure or iron law enforcement.
