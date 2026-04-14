# ATLAS + CLAUDE.md Bootstrap Implementation Plan

**Goal:** Make ATLAS.md turbocharge's core pre-loaded navigation layer and repair the CLAUDE.md bootstrap chain so first-run setup is coherent.

**Architecture:** Rewrite ATLAS format as lookup-first tables, strengthen SessionStart hook to cat ATLAS.md + session snapshot into context on every session, delete the per-Read PreToolUse codemap nudge (redundant once ATLAS is pre-loaded), inject `@ATLAS.md` into planner/researcher/code-reviewer dispatch prompts, add an auto-detect + 5-question CLAUDE.md interview phase to setup with HTML-comment-delimited idempotent blocks, and fold ruflo-style file-and-markdown memory discipline (confidence metadata, 200-line cap, session snapshot JSON) into `/wrap`.

**Tech Stack:** Bash hooks, Markdown SKILL.md files, JSON manifests, POSIX shell validation scripts. No runtime code — this is a plugin content edit.

---

## Assumptions

1. Testing is file-shape-based: tests assert required headers exist, required sections are present, stale patterns are absent, JSON blobs validate. No unit-test runner is required — each task uses a shell "grep / diff / jq / bash -n" verifier as its failing-test surrogate since this is a content plugin, not an application.
2. Tests are added as shell blocks under `scripts/tests/` (new directory) and wired into `scripts/validate.sh`. A test "fails" when the grep/jq assertion exits non-zero; "passes" when it exits zero.
3. The lookup-first ATLAS format change is a rewrite of `skills/atlas/SKILL.md` only — we do NOT regenerate this repo's non-existent ATLAS.md (per CLAUDE.md line 56, this plugin repo intentionally has no ATLAS.md).
4. Version bump to 2.4.0 is done once at the end (Task 24), not per-task.
5. "Zero tool calls for lookup" is the success metric for SessionStart cat — not directly testable, so we test only that the hook emits ATLAS.md contents when present.
6. All file paths below are absolute-from-repo-root; every command assumes `cd` to the repo root.

---

## Prerequisites

- [x] Design doc frozen at `docs/plans/2026-04-14-atlas-claudemd-bootstrap-design.md`
- [x] Current version 2.3.0 in `.claude-plugin/plugin.json`
- [ ] Working directory clean or on a feature branch

---

## Tasks

---

### Task 1: Test harness — shell-based content tests

**Files:**
- Create: `scripts/tests/run.sh`
- Create: `scripts/tests/helpers.sh`
- Modify: `scripts/validate.sh`

**Step 1: Write the failing test**

Create `scripts/tests/run.sh`:
```bash
#!/usr/bin/env bash
# ABOUTME: Aggregator for all content-shape tests for turbocharge plugin.
# ABOUTME: Each test file in scripts/tests/t_*.sh is sourced; non-zero exit fails the run.
set -u
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/../.." && pwd)"
export PLUGIN_DIR
FAIL=0
for t in "$TESTS_DIR"/t_*.sh; do
    [ -f "$t" ] || continue
    echo "--- $(basename "$t") ---"
    if bash "$t"; then
        echo "  PASS"
    else
        echo "  FAIL"
        FAIL=$((FAIL+1))
    fi
done
echo ""
if [ "$FAIL" -eq 0 ]; then echo "All tests passed."; exit 0
else echo "$FAIL test file(s) failed."; exit 1
fi
```

Create `scripts/tests/helpers.sh`:
```bash
#!/usr/bin/env bash
# ABOUTME: Shared assertion helpers for content-shape tests.
# ABOUTME: Sourced by every t_*.sh; provides assert_grep, assert_no_grep, assert_file.
assert_file()      { [ -f "$1" ] || { echo "    missing file: $1"; return 1; }; }
assert_grep()      { grep -q "$2" "$1" || { echo "    missing pattern '$2' in $1"; return 1; }; }
assert_no_grep()   { ! grep -q "$2" "$1" || { echo "    forbidden pattern '$2' still in $1"; return 1; }; }
assert_jq()        { command -v jq >/dev/null 2>&1 || { echo "    jq not installed, skipping"; return 0; }; jq -e "$2" "$1" >/dev/null || { echo "    jq query '$2' failed on $1"; return 1; }; }
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/run.sh`
Expected: FAIL with "No such file or directory" (runner doesn't exist yet) — run before creation to confirm.

**Step 3: Write minimal implementation**
Files above are the implementation. Then append to `scripts/validate.sh` just before the final summary:
```bash
# 6. Content-shape tests
echo "--- Content-Shape Tests ---"
if bash "$PLUGIN_DIR/scripts/tests/run.sh"; then
    pass "content-shape tests passed"
else
    error "content-shape test(s) failed"
fi
echo ""
```

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/run.sh`
Expected: PASS — "All tests passed." (no t_*.sh files exist yet, loop is a no-op, exit 0)

**Step 5: Commit**
`git commit -m "test: add shell-based content-test harness for turbocharge plugin"`

---

### Task 2: ATLAS new format — required headers test

**Files:**
- Create: `scripts/tests/t_atlas_format.sh`
- Modify: `skills/atlas/SKILL.md`

**Step 1: Write the failing test**

Create `scripts/tests/t_atlas_format.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/atlas/SKILL.md"
assert_file "$F" || exit 1
# New format required sections
assert_grep "$F" "^## Where to Look"        || exit 1
assert_grep "$F" "^## Entry Points"         || exit 1
assert_grep "$F" "^## Module Map"           || exit 1
assert_grep "$F" "^## Key Symbols"          || exit 1
assert_grep "$F" "^## Integration Points"   || exit 1
assert_grep "$F" "^## Conventions & Gotchas" || exit 1
# Removed sections must NOT appear in the template section of the skill
assert_no_grep "$F" "^## Data Flows"        || exit 1
assert_no_grep "$F" "^## Domain Model"      || exit 1
assert_no_grep "$F" "^## Active Work"       || exit 1
# Manual-note marker must shift from 📌 to 📌-prefixed line comment
assert_grep "$F" "📌"                       || exit 1
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_atlas_format.sh`
Expected: FAIL with "missing pattern '^## Where to Look' in skills/atlas/SKILL.md"

**Step 3: Write minimal implementation**

Replace the `## Step 4: ATLAS.md Format` template block in `skills/atlas/SKILL.md` (lines ~48-112) with:
````markdown
## Step 4: ATLAS.md Format

````markdown
# ATLAS — [Project Name]

Last updated: YYYY-MM-DD

## Where to Look

| I want to... | Open | Why |
|--------------|------|-----|
| [Intent phrased as user goal] | `path/to/file` | One-line why this is the right file |

## Entry Points

| File | Role | Starts |
|------|------|--------|
| `path/to/main` | CLI / API / Job / Hook | What it boots |

## Module Map

| Directory | One-line purpose | Key files |
|-----------|------------------|-----------|
| `src/module/` | What this module does | `important.ext`, `other.ext` |

## Key Symbols

(20-30 most-referenced; heuristic, not AST-exhaustive.)

| Symbol | File:line-range | Kind |
|--------|-----------------|------|
| `SymbolName` | `path/to/file:10-42` | class / function / const |

## Integration Points

| System | Config key | Path |
|--------|------------|------|
| ServiceName | `ENV_VAR` | `path/to/client` |

## Conventions & Gotchas

- [Non-obvious trap that burned someone]
- [Intentional-looking-wrong pattern]

<!-- 📌-prefixed lines are manual notes, preserved across atlas updates -->
````

**Constraint:** every section above is a table or bullet list. No prose paragraphs.

**Removed from prior format:** Data Flows (prose arrows), Domain Model (→ CLAUDE.md), Active Work & Known Issues.
**Added:** Where to Look (intent→file), Key Symbols (heuristic).
````

Also update `## What NOT to Include` to add: `- Data flow prose → describe as a Where to Look row ("I want to trace request X" → entry file)` and update Red Flags table's "Writing prose paragraphs" row to be first, not last.

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_atlas_format.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "feat(atlas): reshape ATLAS.md format to lookup-first tables"`

---

### Task 3: `validate-atlas.sh` — format validator for user projects

**Files:**
- Create: `scripts/validate-atlas.sh`
- Create: `scripts/tests/t_validate_atlas_script.sh`
- Modify: `scripts/validate.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_validate_atlas_script.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/scripts/validate-atlas.sh"
assert_file "$F" || exit 1
# Executable bit (best-effort; on Windows NTFS this can be a noop, tolerate)
bash -n "$F" || { echo "    syntax error"; exit 1; }
# Drives required-header logic
assert_grep "$F" "Where to Look"       || exit 1
assert_grep "$F" "Entry Points"        || exit 1
assert_grep "$F" "Module Map"          || exit 1
assert_grep "$F" "Key Symbols"         || exit 1
assert_grep "$F" "Integration Points"  || exit 1
# Fails cleanly when ATLAS.md missing
TMP="$(mktemp -d)"; cd "$TMP"
if bash "$F"; then echo "    expected nonzero when ATLAS.md missing"; cd - >/dev/null; rm -rf "$TMP"; exit 1; fi
cd - >/dev/null; rm -rf "$TMP"
# Passes when minimal ATLAS.md with all headers present
TMP="$(mktemp -d)"; cd "$TMP"
cat > ATLAS.md <<'EOF'
# ATLAS — Test
## Where to Look
## Entry Points
## Module Map
## Key Symbols
## Integration Points
## Conventions & Gotchas
EOF
if ! bash "$F"; then echo "    expected zero on valid ATLAS.md"; cd - >/dev/null; rm -rf "$TMP"; exit 1; fi
cd - >/dev/null; rm -rf "$TMP"
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_validate_atlas_script.sh`
Expected: FAIL with "missing file: .../scripts/validate-atlas.sh"

**Step 3: Write minimal implementation**

Create `scripts/validate-atlas.sh`:
```bash
#!/usr/bin/env bash
# ABOUTME: Validates ATLAS.md in CWD has turbocharge's required lookup-first headers.
# ABOUTME: Exits 0 on pass, 1 on any missing header or missing file.
set -u
TARGET="${1:-ATLAS.md}"
REQUIRED=("## Where to Look" "## Entry Points" "## Module Map" "## Key Symbols" "## Integration Points" "## Conventions & Gotchas")
if [ ! -f "$TARGET" ]; then
    echo "ATLAS-VALIDATE: $TARGET not found." >&2
    exit 1
fi
MISSING=0
for h in "${REQUIRED[@]}"; do
    if ! grep -q "^${h}\$" "$TARGET"; then
        echo "ATLAS-VALIDATE: missing required header: $h" >&2
        MISSING=$((MISSING+1))
    fi
done
if [ "$MISSING" -gt 0 ]; then
    echo "ATLAS-VALIDATE: $MISSING header(s) missing." >&2
    exit 1
fi
echo "ATLAS-VALIDATE: $TARGET OK"
```

Add to `scripts/validate.sh` after the "Required Files" block:
```bash
# 5b. Validate ATLAS.md format IF one exists (not expected in plugin repo)
if [ -f "$PLUGIN_DIR/ATLAS.md" ]; then
    if bash "$PLUGIN_DIR/scripts/validate-atlas.sh" "$PLUGIN_DIR/ATLAS.md"; then
        pass "ATLAS.md format valid"
    else
        error "ATLAS.md format invalid"
    fi
fi
```

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_validate_atlas_script.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "feat: add scripts/validate-atlas.sh for user-project ATLAS.md format check"`

---

### Task 4: SessionStart hook — pre-load ATLAS.md into context

**Files:**
- Modify: `hooks/session-start.sh`
- Create: `scripts/tests/t_session_start_cat_atlas.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_session_start_cat_atlas.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/session-start.sh"
assert_file "$F" || exit 1
bash -n "$F" || exit 1
# When ATLAS.md exists in cwd, hook must cat its contents
TMP="$(mktemp -d)"; cp "$PLUGIN_DIR/hooks/"*.md "$TMP/" 2>/dev/null || true
cd "$TMP"
cat > ATLAS.md <<'EOF'
# ATLAS — Fixture
UNIQUE_ATLAS_MARKER_37812
EOF
OUT="$(bash "$F" 2>&1 || true)"
cd - >/dev/null
echo "$OUT" | grep -q "UNIQUE_ATLAS_MARKER_37812" || { echo "    session-start.sh did not cat ATLAS.md"; rm -rf "$TMP"; exit 1; }
# When _session.json snapshot exists, hook must cat it too
cd "$TMP"
mkdir -p ".claude"
cat > ".claude/turbocharge-session.json" <<'EOF'
{"marker":"UNIQUE_SESSION_MARKER_99123"}
EOF
OUT="$(bash "$F" 2>&1 || true)"
cd - >/dev/null
rm -rf "$TMP"
echo "$OUT" | grep -q "UNIQUE_SESSION_MARKER_99123" || { echo "    session-start.sh did not cat session snapshot"; exit 1; }
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_session_start_cat_atlas.sh`
Expected: FAIL with "session-start.sh did not cat ATLAS.md"

**Step 3: Write minimal implementation**

Replace `hooks/session-start.sh` with:
```bash
#!/usr/bin/env bash
# ABOUTME: SessionStart hook — bootstrap cat, pre-load ATLAS.md + session snapshot.
# ABOUTME: Pre-loading ATLAS means zero tool calls for "where is X" lookups.
set -e
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"

cat "$HOOK_DIR/session-bootstrap.md"

if [ -f "ATLAS.md" ]; then
    echo ""
    echo "--- ATLAS.md (pre-loaded for zero-tool-call navigation) ---"
    cat "ATLAS.md"
    echo "--- end ATLAS.md ---"
else
    echo ""
    cat "$HOOK_DIR/missing-atlasmd-nudge.md"
fi

if [ -f ".claude/turbocharge-session.json" ]; then
    echo ""
    echo "--- Session snapshot (previous /wrap) ---"
    cat ".claude/turbocharge-session.json"
    echo "--- end snapshot ---"
fi

if [ ! -f "CLAUDE.md" ]; then
    echo ""
    cat "$HOOK_DIR/missing-claudemd-nudge.md"
fi
```

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_session_start_cat_atlas.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "feat(hooks): pre-load ATLAS.md and session snapshot in SessionStart"`

---

### Task 5: Delete the PreToolUse codemap hook

**Files:**
- Modify: `hooks/hooks.json`
- Delete: `hooks/pretool-read-codemap.sh`
- Create: `scripts/tests/t_no_pretooluse.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_no_pretooluse.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/hooks.json"
assert_file "$F" || exit 1
assert_no_grep "$F" "PreToolUse"          || exit 1
assert_no_grep "$F" "pretool-read-codemap" || exit 1
[ ! -f "$PLUGIN_DIR/hooks/pretool-read-codemap.sh" ] || { echo "    pretool-read-codemap.sh still exists"; exit 1; }
# hooks.json still parses as valid JSON
if command -v jq >/dev/null 2>&1; then
    jq -e '.hooks.SessionStart' "$F" >/dev/null || { echo "    SessionStart missing"; exit 1; }
    jq -e '.hooks.Stop' "$F" >/dev/null         || { echo "    Stop missing"; exit 1; }
fi
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_no_pretooluse.sh`
Expected: FAIL with "forbidden pattern 'PreToolUse' still in hooks/hooks.json"

**Step 3: Write minimal implementation**

Replace `hooks/hooks.json`:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh\"",
            "statusMessage": "Loading turbocharge..."
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cat \"${CLAUDE_PLUGIN_ROOT}/hooks/stop-wrap-reminder.md\""
          }
        ]
      }
    ]
  }
}
```

Then: `git rm hooks/pretool-read-codemap.sh`

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_no_pretooluse.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "refactor(hooks): drop PreToolUse codemap nudge — redundant with ATLAS pre-load"`

---

### Task 6: Tighten `missing-atlasmd-nudge.md`

**Files:**
- Modify: `hooks/missing-atlasmd-nudge.md`
- Create: `scripts/tests/t_missing_atlas_nudge.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_missing_atlas_nudge.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/missing-atlasmd-nudge.md"
assert_file "$F" || exit 1
assert_grep "$F" "/turbocharge:atlas"     || exit 1
assert_grep "$F" "pre-loaded"             || exit 1
LINES=$(wc -l < "$F")
[ "$LINES" -le 8 ] || { echo "    nudge is $LINES lines, expected ≤ 8"; exit 1; }
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_missing_atlas_nudge.sh`
Expected: FAIL with "missing pattern 'pre-loaded' in hooks/missing-atlasmd-nudge.md"

**Step 3: Write minimal implementation**

Replace `hooks/missing-atlasmd-nudge.md`:
```markdown
## No ATLAS.md Detected

Suggest `/turbocharge:atlas` to generate one. When present, ATLAS.md is pre-loaded into context on every session so navigation lookups cost zero tool calls.
```

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_missing_atlas_nudge.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "docs(hooks): tighten missing-atlasmd-nudge — note pre-load behavior"`

---

### Task 7: Tighten `missing-claudemd-nudge.md` to 2-line chain nudge

**Files:**
- Modify: `hooks/missing-claudemd-nudge.md`
- Create: `scripts/tests/t_missing_claudemd_nudge.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_missing_claudemd_nudge.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/hooks/missing-claudemd-nudge.md"
assert_file "$F" || exit 1
assert_grep "$F" "/init"                  || exit 1
assert_grep "$F" "/turbocharge:setup"     || exit 1
# No more manual 5-section dump
assert_no_grep "$F" "### ABOUTME Convention" || exit 1
assert_no_grep "$F" "### TDD Workflow"        || exit 1
LINES=$(wc -l < "$F")
[ "$LINES" -le 10 ] || { echo "    nudge is $LINES lines, expected ≤ 10"; exit 1; }
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_missing_claudemd_nudge.sh`
Expected: FAIL with "forbidden pattern '### ABOUTME Convention' still in ..."

**Step 3: Write minimal implementation**

Replace `hooks/missing-claudemd-nudge.md`:
```markdown
## No CLAUDE.md Detected

This project has no `CLAUDE.md`. Recommend the chain:

1. Run `/init` — Claude Code generates a baseline CLAUDE.md (identity, stack, structure).
2. Run `/turbocharge:setup` — appends turbocharge-specific rule blocks (TDD, debug, conventions) via a short interview.
```

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_missing_claudemd_nudge.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "docs(hooks): tighten missing-claudemd-nudge to init+setup chain"`

---

### Task 8: Template — `templates/CLAUDE-turbocharge.md` default blocks

**Files:**
- Create: `templates/CLAUDE-turbocharge.md`
- Create: `scripts/tests/t_template_claudemd.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_template_claudemd.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/templates/CLAUDE-turbocharge.md"
assert_file "$F" || exit 1
for marker in tdd debug naming file-header domain-terms; do
    assert_grep "$F" "<!-- turbocharge:${marker} -->"    || exit 1
    assert_grep "$F" "<!-- /turbocharge:${marker} -->"   || exit 1
done
# Each block is bounded and non-empty
python3 - "$F" <<'PY' || exit 1
import re, sys
t = open(sys.argv[1], encoding='utf-8').read()
for m in ["tdd","debug","naming","file-header","domain-terms"]:
    pat = rf"<!-- turbocharge:{m} -->(.*?)<!-- /turbocharge:{m} -->"
    mo = re.search(pat, t, re.DOTALL)
    if not mo or not mo.group(1).strip():
        print(f"    block '{m}' empty or missing"); sys.exit(1)
PY
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_template_claudemd.sh`
Expected: FAIL with "missing file: .../templates/CLAUDE-turbocharge.md"

**Step 3: Write minimal implementation**

Create `templates/CLAUDE-turbocharge.md`:
```markdown
<!-- turbocharge:tdd -->
## TDD Workflow

- Every task starts on a failing test.
- Test command: `{{TEST_COMMAND}}`
- Never ask permission to run tests; run them after every task and every refactor.
<!-- /turbocharge:tdd -->

<!-- turbocharge:debug -->
## Debugging Protocol

When investigating bugs: trace data flow first. Do not propose fixes until the root cause is identified. Say where the data diverges from expected, then propose the minimal fix.
<!-- /turbocharge:debug -->

<!-- turbocharge:naming -->
## Naming Conventions

- Files, functions, and variables follow `{{NAMING_STYLE}}`.
- Match existing patterns in the codebase over imposing new conventions.
<!-- /turbocharge:naming -->

<!-- turbocharge:file-header -->
## File Header Convention

{{FILE_HEADER_CONVENTION}}
<!-- /turbocharge:file-header -->

<!-- turbocharge:domain-terms -->
## Domain Terms

| Term | Definition |
|------|------------|
| {{TERM_1}} | {{DEFINITION_1}} |
<!-- /turbocharge:domain-terms -->
```

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_template_claudemd.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "feat(templates): add CLAUDE-turbocharge.md default block template"`

---

### Task 9: Setup skill — add CLAUDE.md phase (detection + interview)

**Files:**
- Modify: `skills/setup/SKILL.md`
- Create: `scripts/tests/t_setup_claudemd_phase.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_setup_claudemd_phase.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/setup/SKILL.md"
assert_grep "$F" "## CLAUDE.md Phase"             || exit 1
assert_grep "$F" "Auto-Detect"                    || exit 1
assert_grep "$F" "package.json"                   || exit 1
assert_grep "$F" "pyproject.toml"                 || exit 1
assert_grep "$F" "Cargo.toml"                     || exit 1
assert_grep "$F" "go.mod"                         || exit 1
assert_grep "$F" "Interview"                      || exit 1
assert_grep "$F" "Test discipline"                || exit 1
assert_grep "$F" "File-header convention"         || exit 1
assert_grep "$F" "Naming style"                   || exit 1
assert_grep "$F" "Debug protocol strictness"      || exit 1
assert_grep "$F" "domain terms"                   || exit 1
assert_grep "$F" "templates/CLAUDE-turbocharge.md" || exit 1
assert_grep "$F" "<!-- turbocharge:"              || exit 1
assert_grep "$F" "180 lines"                      || exit 1
# Chains forward to atlas
assert_grep "$F" "/turbocharge:atlas"             || exit 1
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_setup_claudemd_phase.sh`
Expected: FAIL with "missing pattern '## CLAUDE.md Phase' in skills/setup/SKILL.md"

**Step 3: Write minimal implementation**

In `skills/setup/SKILL.md`: replace `### 7. Check for Project Atlas` (lines ~95-99) and insert a new `## CLAUDE.md Phase` section between step 7 and `## Report Format`. The new section:

```markdown
## CLAUDE.md Phase

Run this phase after the conflict audit completes and before the final report.

### 1. Auto-Detect (no questions)

Probe the project root for these files and extract values:

| Signal | Inspect | Extract |
|--------|---------|---------|
| `package.json` | `scripts.test`, `scripts.lint`, top-level `name` | test command, lint command, project name |
| `pyproject.toml` | `[tool.poetry]`, `[project]`, `[tool.pytest.ini_options]` | language (Python), test framework |
| `Cargo.toml` | `[package].name`, `[dev-dependencies]` | language (Rust), test runner |
| `go.mod` | `module` line | language (Go), module path |
| `pnpm-lock.yaml` / `yarn.lock` / `package-lock.json` | presence | package manager |
| Primary entry | `src/index.*`, `main.*`, `cmd/*/main.go` | entry-point file |

Do not ask the user about anything detectable.

### 2. Interview (≤5 questions, each skippable)

Ask at most these five, each with `[skip]` producing the template default:

1. **Test discipline** — Strict TDD / Tests-alongside / Tests-when-reasonable
2. **File-header convention** — ABOUTME / JSDoc-style / None
3. **Naming style** — camelCase / snake_case / mixed-by-language
4. **Debug protocol strictness** — Always 4-phase / Non-trivial only
5. **Project-specific domain terms** — free text; empty skips the block

The interview must be completable in under 90 seconds.

### 3. Render and Append

Read `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE-turbocharge.md`. Substitute answers (test command, naming style, file-header convention, domain terms). Each block is delimited by `<!-- turbocharge:NAME -->` and `<!-- /turbocharge:NAME -->`.

- If CLAUDE.md exists and contains a block with the same marker → replace between markers, leave surrounding content untouched.
- If CLAUDE.md exists and does not contain that block → append to end of file.
- If CLAUDE.md does not exist → suggest `/init` first, do not create a bare CLAUDE.md from the template alone.

### 4. Show Diff, Confirm, Write

Always show the diff and ask for confirmation before writing. Never modify CLAUDE.md silently.

### 5. Size Guard

After writing, if CLAUDE.md exceeds 180 lines, warn the user and suggest extracting personal rules to `~/.claude/CLAUDE.md`.

### 6. Chain Forward

If ATLAS.md does not exist, offer: `/turbocharge:atlas` to generate the navigation index. This closes the bootstrap loop: `/init → /turbocharge:setup → /turbocharge:atlas`.
```

Also remove the now-redundant step 7 ("Check for Project Atlas") since the new CLAUDE.md phase covers the atlas chain-forward.

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_setup_claudemd_phase.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "feat(setup): add CLAUDE.md detect+interview+append phase"`

---

### Task 10: Planner agent — explicit "read ATLAS first"

**Files:**
- Modify: `agents/planner.md`
- Create: `scripts/tests/t_agent_atlas_refs.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_agent_atlas_refs.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
for a in planner researcher code-reviewer; do
    F="$PLUGIN_DIR/agents/$a.md"
    assert_file "$F" || exit 1
    grep -qi "ATLAS" "$F" || { echo "    $a.md missing ATLAS reference"; exit 1; }
    grep -qi "read.*ATLAS" "$F" || grep -qi "ATLAS.*first" "$F" || { echo "    $a.md missing 'read ATLAS first' instruction"; exit 1; }
done
# Builder, spec-reviewer, quality-reviewer must NOT reference ATLAS (per design)
for a in builder spec-reviewer quality-reviewer; do
    F="$PLUGIN_DIR/agents/$a.md"
    [ -f "$F" ] || continue
    if grep -qi "ATLAS" "$F"; then echo "    $a.md unexpectedly references ATLAS (design says no)"; exit 1; fi
done
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_agent_atlas_refs.sh`
Expected: FAIL with "planner.md missing ATLAS reference"

**Step 3: Write minimal implementation**

Add to `agents/planner.md` under `### Verify Domain Understanding First (MANDATORY)`, as step 0 before step 1:
```markdown
0. **Read ATLAS.md first** — if `ATLAS.md` exists in the project root, read it before exploring. Its Where-to-Look table maps intent→file and saves token-expensive searches. Treat it as the navigation index for this project.
```

**Step 4: Run test to verify it passes (partial — other agents still fail)**
Run: `bash scripts/tests/t_agent_atlas_refs.sh`
Expected: FAIL on researcher.md (will be fixed next task) — this is expected partial pass.

Note: skip to Step 5 once planner.md section is in place; full test passes after Task 12.

**Step 5: Commit**
`git commit -m "feat(agents): planner reads ATLAS.md first before codebase exploration"`

---

### Task 11: Researcher agent — explicit "read ATLAS first"

**Files:**
- Modify: `agents/researcher.md`

**Step 1: Write the failing test**
Reuse `scripts/tests/t_agent_atlas_refs.sh` from Task 10.

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_agent_atlas_refs.sh`
Expected: FAIL with "researcher.md missing ATLAS reference"

**Step 3: Write minimal implementation**

In `agents/researcher.md`, replace step 1 of `## How to Work`:
```markdown
0. **Read ATLAS.md first** — if it exists in the project root, it is the authoritative Where-to-Look table. Start there; it saves most broad-search tool calls.
1. **Start broad** — if ATLAS is absent or incomplete, understand project structure, key files, conventions
```

**Step 4: Run test to verify it passes (partial)**
Run: `bash scripts/tests/t_agent_atlas_refs.sh`
Expected: Still FAIL on code-reviewer.md — OK, fixed in Task 12.

**Step 5: Commit**
`git commit -m "feat(agents): researcher reads ATLAS.md first before broad exploration"`

---

### Task 12: Code-reviewer agent — explicit "read ATLAS first"

**Files:**
- Modify: `agents/code-reviewer.md`

**Step 1: Write the failing test**
Reuse `scripts/tests/t_agent_atlas_refs.sh`.

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_agent_atlas_refs.sh`
Expected: FAIL with "code-reviewer.md missing ATLAS reference"

**Step 3: Write minimal implementation**

In `agents/code-reviewer.md`, add as the first item of `## Your Review`:
```markdown
0. **Read ATLAS.md first**
   - If `ATLAS.md` exists, read it before reviewing the diff.
   - Use its Module Map and Key Symbols tables to identify which modules the diff touches and what their role is.
   - Flag any divergence between the diff and ATLAS — either the diff is wrong or ATLAS is stale.
```
(Renumber subsequent items 1→2, 2→3, etc.)

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_agent_atlas_refs.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "feat(agents): code-reviewer reads ATLAS.md first and flags divergence"`

---

### Task 13: Plan skill — inject `@ATLAS.md` in dispatch prompt

**Files:**
- Modify: `skills/plan/SKILL.md`
- Create: `scripts/tests/t_skill_atlas_injection.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_skill_atlas_injection.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
for s in plan build review; do
    F="$PLUGIN_DIR/skills/$s/SKILL.md"
    assert_file "$F" || exit 1
    grep -q "@ATLAS.md" "$F" || { echo "    skills/$s/SKILL.md does not inject @ATLAS.md"; exit 1; }
done
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_skill_atlas_injection.sh`
Expected: FAIL with "skills/plan/SKILL.md does not inject @ATLAS.md"

**Step 3: Write minimal implementation**

In `skills/plan/SKILL.md`, replace the `## Context Gathering` section with:
```markdown
## Context Gathering

Before planning, preload domain context. When dispatching the planner agent, prefix its prompt with:

```
@ATLAS.md (navigation index — use its Where to Look and Module Map tables before any codebase search)
@CLAUDE.md (conventions, rules, domain vocabulary)
```

If either file does not exist, omit the corresponding `@` reference. These inform task design — use correct entity names, file paths, and architectural patterns. `@` references auto-read on dispatch so the subagent receives them in context; subagents do NOT inherit parent conversation history.
```

**Step 4: Run test to verify it passes (partial)**
Run: `bash scripts/tests/t_skill_atlas_injection.sh`
Expected: Still FAIL on build and review — OK, fixed next two tasks.

**Step 5: Commit**
`git commit -m "feat(plan): inject @ATLAS.md into planner dispatch prompt"`

---

### Task 14: Build skill — inject `@ATLAS.md` in dispatch prompt

**Files:**
- Modify: `skills/build/SKILL.md`

**Step 1: Write the failing test**
Reuse `scripts/tests/t_skill_atlas_injection.sh`.

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_skill_atlas_injection.sh`
Expected: FAIL with "skills/build/SKILL.md does not inject @ATLAS.md"

**Step 3: Write minimal implementation**

In `skills/build/SKILL.md`, modify `### 3a. Dispatch Builder` to append:
```markdown
Prefix the builder's dispatch prompt with `@CLAUDE.md` (conventions). Do NOT inject `@ATLAS.md` here — builders read the spec and diff, not the navigation index.
```

Then modify `### 3b. Dispatch Spec Reviewer` and `### 3c. Dispatch Quality Reviewer`: same — `@CLAUDE.md` only.

Then add a new sub-step `### 3f. Dispatch Researcher (on demand)`:
```markdown
If the builder blocks on unclear context, dispatch the researcher with `@ATLAS.md @CLAUDE.md` prefixed. Subagents do not inherit parent history — `@ATLAS.md` must ride on the dispatch prompt itself.
```

**Step 4: Run test to verify it passes (partial)**
Run: `bash scripts/tests/t_skill_atlas_injection.sh`
Expected: Still FAIL on review — fixed next.

**Step 5: Commit**
`git commit -m "feat(build): inject @ATLAS.md only when dispatching researcher sub-step"`

---

### Task 15: Review skill — inject `@ATLAS.md` in dispatch prompt

**Files:**
- Modify: `skills/review/SKILL.md`

**Step 1: Write the failing test**
Reuse `scripts/tests/t_skill_atlas_injection.sh`.

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_skill_atlas_injection.sh`
Expected: FAIL with "skills/review/SKILL.md does not inject @ATLAS.md"

**Step 3: Write minimal implementation**

In `skills/review/SKILL.md`, replace `## Context` with:
```markdown
## Context

The plan or requirements being reviewed: $ARGUMENTS

Dispatch the code-reviewer agent with this prefix so the subagent sees the navigation index (subagents do not inherit parent history):

```
@ATLAS.md (navigation index — use Module Map + Key Symbols to locate touched modules)
@CLAUDE.md (conventions, rules)
```

Omit either reference if the file doesn't exist.
```

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_skill_atlas_injection.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "feat(review): inject @ATLAS.md + @CLAUDE.md into code-reviewer dispatch"`

---

### Task 16: Wrap skill — confidence/source metadata format

**Files:**
- Modify: `skills/wrap/SKILL.md`
- Create: `scripts/tests/t_wrap_memory_format.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_wrap_memory_format.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/wrap/SKILL.md"
assert_grep "$F" "conf:"                    || exit 1
assert_grep "$F" "source,"                  || exit 1
assert_grep "$F" "200-line cap"             || exit 1
assert_grep "$F" "turbocharge-session.json" || exit 1
assert_grep "$F" "\.claude/turbocharge-session" || exit 1
# Specific bullet format shown
grep -qE -- "- .* _\(.*, [0-9]{4}-[0-9]{2}-[0-9]{2}, conf: 0\.[0-9]\)_" "$F" || { echo "    canonical bullet format example missing"; exit 1; }
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_wrap_memory_format.sh`
Expected: FAIL with "missing pattern 'conf:' in skills/wrap/SKILL.md"

**Step 3: Write minimal implementation**

In `skills/wrap/SKILL.md`, append a new section after `### 6. Encode Session Learnings`:

```markdown
### 7. Write Memory With Confidence Metadata

When persisting items to `~/.claude/projects/<project>/memory/*.md`, use this bullet format:

```
- Summary sentence _(source, YYYY-MM-DD, conf: 0.8)_
```

- `source` — where the claim came from (`websearch`, `user`, `codebase`, `testrun`)
- `YYYY-MM-DD` — date written
- `conf` — 0.1 to 1.0; 0.9+ only for verified facts, 0.5–0.8 for reasoned claims, <0.5 for speculation

Example:
- Tailwind v4 drops the JS config _(websearch, 2026-04-14, conf: 0.9)_

### 8. 200-Line Cap on MEMORY.md — prune-before-build

Before appending new entries, if `~/.claude/projects/<project>/memory/MEMORY.md` is at or over 200 lines:
1. Sort existing entries by (confidence asc, date asc) — lowest confidence and oldest first
2. Drop entries until under 180 lines
3. Then append new entries

Dropped entries are not archived separately — file-based memory is lossy by design; high-value entries survive by being re-surfaced each session.

### 9. Session Snapshot JSON

Write `.claude/turbocharge-session.json` in the project root (the standard Claude Code project-state directory — same place `.claude/settings.json` and `.claude/settings.local.json` live):

```json
{
  "date": "2026-04-14",
  "branch": "master",
  "current_task": "ATLAS reshape design",
  "blockers": [],
  "next_steps": ["Chain to /turbocharge:plan", "Break into tasks"],
  "open_files": ["skills/atlas/SKILL.md"]
}
```

The SessionStart hook cats this on next session so resume is zero-tool-call. Make sure `.claude/turbocharge-session.json` is in the project `.gitignore` — it is per-user session-local state (don't exclude all of `.claude/` because `settings.json` is team-shared).
```

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_wrap_memory_format.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "feat(wrap): confidence metadata, 200-line cap, session snapshot JSON"`

---

### Task 17: `.gitignore` adds `.claude-session/`

**Files:**
- Modify: `.gitignore`
- Create: `scripts/tests/t_gitignore_session.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_gitignore_session.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/.gitignore"
assert_file "$F" || exit 1
grep -qE '^\.claude/turbocharge-session\.json$' "$F" || { echo "    .claude/turbocharge-session.json not in .gitignore"; exit 1; }
# Must NOT exclude all of .claude/ (settings.json is team-shared)
if grep -qE '^\.claude/?$' "$F"; then echo "    .gitignore excludes all of .claude/ — would hide team-shared settings.json"; exit 1; fi
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_gitignore_session.sh`
Expected: FAIL with ".claude-session/ not in .gitignore"

**Step 3: Write minimal implementation**

Append to `.gitignore`:
```
# turbocharge session snapshot (per-user, zero-tool-call resume)
.claude/turbocharge-session.json
```

Do NOT exclude all of `.claude/` — `.claude/settings.json` is the team-shared project config and must remain committable.

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_gitignore_session.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "chore: gitignore .claude/turbocharge-session.json (per-user session snapshot)"`

---

### Task 18: Remove manual-notes 📌 from Step 3 Update Mode — use HTML comment contract

**Files:**
- Modify: `skills/atlas/SKILL.md`
- Create: `scripts/tests/t_atlas_manual_notes.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_atlas_manual_notes.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/atlas/SKILL.md"
# Manual notes still preserved, still signaled by 📌
assert_grep "$F" "📌"                                || exit 1
# Update Mode explicitly says preserve 📌-prefixed lines
grep -q "preserve.*📌" "$F" || grep -q "📌.*preserve" "$F" || { echo "    Update Mode does not explicitly preserve 📌 lines"; exit 1; }
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_atlas_manual_notes.sh`
Expected: Likely PASSES if Task 2 already preserves this text; if not, this task hardens it.

If it already passes, **skip Steps 3-5 of this task, note "preserved by Task 2"**, and move on.

**Step 3: Write minimal implementation (if needed)**
Confirm `## Step 3: Generate or Update` → `### Update Mode (ATLAS.md exists)` step 3 reads: "Update stale sections — preserve any manually-added notes (lines starting with 📌)"

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_atlas_manual_notes.sh`
Expected: PASS

**Step 5: Commit (if content changed)**
`git commit -m "docs(atlas): harden 📌 manual-note preservation contract in Update Mode"`

---

### Task 19: CLAUDE.md — demote ATLAS claim on line 56

**Files:**
- Modify: `CLAUDE.md`
- Create: `scripts/tests/t_claudemd_atlas_claim.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_claudemd_atlas_claim.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CLAUDE.md"
assert_file "$F" || exit 1
# New accurate claim
assert_grep "$F" "Pre-loaded into context by the SessionStart hook" || exit 1
assert_grep "$F" "injected into dispatch prompts"                  || exit 1
# Old inaccurate claim is gone
assert_no_grep "$F" "Read by .setup, wrap, plan. skills"            || exit 1
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_claudemd_atlas_claim.sh`
Expected: FAIL with "missing pattern 'Pre-loaded into context by the SessionStart hook'"

**Step 3: Write minimal implementation**

In `CLAUDE.md` line 56, replace the ATLAS.md row of the Domain Terms table:

```markdown
| **ATLAS.md** | Semantic domain map generated by `/turbocharge:atlas` in user projects (Where to Look, Entry Points, Module Map, Key Symbols, Integration Points). **Pre-loaded into context by the SessionStart hook** when present; **injected into dispatch prompts** for planner, researcher, and code-reviewer agents; nudged by SessionStart when absent. This plugin repo intentionally does NOT ship one — CLAUDE.md + README cover the same ground for a plugin blueprint. |
```

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_claudemd_atlas_claim.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "docs(claudemd): demote ATLAS claim to accurate pre-load+dispatch-inject wording"`

---

### Task 20: Hook description in CLAUDE.md — drop PreToolUse reference

**Files:**
- Modify: `CLAUDE.md`
- Create: `scripts/tests/t_claudemd_hook_ref.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_claudemd_hook_ref.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CLAUDE.md"
assert_grep "$F" "SessionStart, Stop" || exit 1
assert_no_grep "$F" "SessionStart, PreToolUse, Stop" || exit 1
assert_no_grep "$F" "3 hooks (SessionStart bootstrap, PreToolUse codemap nudge, Stop wrap reminder)" || exit 1
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_claudemd_hook_ref.sh`
Expected: FAIL — current CLAUDE.md references 3 hooks including PreToolUse.

**Step 3: Write minimal implementation**

In `CLAUDE.md`, change every occurrence of:
- `3 hooks (SessionStart bootstrap, PreToolUse codemap nudge, Stop wrap reminder)` → `2 hooks (SessionStart bootstrap + ATLAS pre-load, Stop wrap reminder)`
- `lifecycle events (SessionStart, Stop, PreToolUse)` → `lifecycle events (SessionStart, Stop)`

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_claudemd_hook_ref.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "docs(claudemd): hook inventory drops PreToolUse (deleted in hooks.json)"`

---

### Task 21: Validate-atlas runs in plugin validate.sh when appropriate

**Files:**
- Create: `scripts/tests/t_validate_sh_wires_atlas.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_validate_sh_wires_atlas.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/scripts/validate.sh"
assert_grep "$F" "validate-atlas.sh" || exit 1
# Full validate.sh still exits 0 on this repo
bash "$F" >/dev/null 2>&1 || { echo "    validate.sh exits nonzero on clean repo"; exit 1; }
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_validate_sh_wires_atlas.sh`
Expected: Should already PASS if Task 3 wired `validate-atlas.sh` into `validate.sh`. If not, this task is the catch.

**Step 3: Write minimal implementation**
If Task 3 wired it, no change. Otherwise, see Task 3 Step 3 wiring.

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_validate_sh_wires_atlas.sh`
Expected: PASS

**Step 5: Commit (only if changes made)**
`git commit -m "test: verify validate.sh calls validate-atlas.sh on ATLAS.md presence"`

---

### Task 22: Full test run gate

**Files:**
- None (verification step)

**Step 1: Write the failing test**
N/A — meta-task.

**Step 2: Run test to verify it fails**
N/A.

**Step 3: Write minimal implementation**
N/A.

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/run.sh && bash scripts/validate.sh`
Expected: Both exit 0. Every `t_*.sh` passes. `validate.sh` says "PASSED — 0 errors".

If either fails, go back and fix the failing task's output before proceeding.

**Step 5: Commit (no-op)**
No commit — this is a gate. Any fixes commit under their originating task.

---

### Task 23: CHANGELOG.md — v2.4.0 entry

**Files:**
- Modify: `CHANGELOG.md`
- Create: `scripts/tests/t_changelog_240.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_changelog_240.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[2\.4\.0\]" "$F" || { echo "    missing [2.4.0] entry"; exit 1; }
assert_grep "$F" "ATLAS pre-load"        || exit 1
assert_grep "$F" "PreToolUse"            || exit 1
assert_grep "$F" "CLAUDE.md bootstrap"   || exit 1
assert_grep "$F" "session snapshot"      || exit 1
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_changelog_240.sh`
Expected: FAIL with "missing [2.4.0] entry"

**Step 3: Write minimal implementation**

Prepend to `CHANGELOG.md` (under the `# Changelog` heading, before `## [2.3.0]`):

```markdown
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
```

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_changelog_240.sh`
Expected: PASS

**Step 5: Commit**
`git commit -m "docs: CHANGELOG entry for v2.4.0"`

---

### Task 24: Version bump — 2.4.0 across manifests

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Create: `scripts/tests/t_version_240.sh`

**Step 1: Write the failing test**

Create `scripts/tests/t_version_240.sh`:
```bash
#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
P="$PLUGIN_DIR/.claude-plugin/plugin.json"
M="$PLUGIN_DIR/.claude-plugin/marketplace.json"
assert_file "$P" || exit 1
assert_file "$M" || exit 1
if command -v jq >/dev/null 2>&1; then
    jq -e '.version == "2.4.0"' "$P" >/dev/null || { echo "    plugin.json version != 2.4.0"; exit 1; }
    jq -e '.metadata.version == "2.4.0"' "$M" >/dev/null || { echo "    marketplace.json metadata.version != 2.4.0"; exit 1; }
    jq -e '.plugins[0].version == "2.4.0"' "$M" >/dev/null || { echo "    marketplace.json plugins[0].version != 2.4.0"; exit 1; }
else
    grep -q '"version": "2\.4\.0"' "$P" || { echo "    plugin.json version"; exit 1; }
    grep -q '"version": "2\.4\.0"' "$M" || { echo "    marketplace.json version"; exit 1; }
fi
```

**Step 2: Run test to verify it fails**
Run: `bash scripts/tests/t_version_240.sh`
Expected: FAIL with "plugin.json version != 2.4.0"

**Step 3: Write minimal implementation**
- `.claude-plugin/plugin.json`: `"version": "2.3.0"` → `"version": "2.4.0"`
- `.claude-plugin/marketplace.json`: two occurrences of `"version": "2.3.0"` → `"version": "2.4.0"` (the `metadata.version` and `plugins[0].version`)

**Step 4: Run test to verify it passes**
Run: `bash scripts/tests/t_version_240.sh && bash scripts/tests/run.sh && bash scripts/validate.sh`
Expected: All three exit 0.

**Step 5: Commit**
`git commit -m "chore: bump turbocharge to 2.4.0"`

---

## Final Gate

After Task 24:

```bash
bash scripts/tests/run.sh       # every t_*.sh passes
bash scripts/validate.sh        # PASSED — 0 errors
git log --oneline -25           # 22–24 commits since start of this plan
```

Then: `/turbocharge:review docs/plans/2026-04-14-atlas-claudemd-bootstrap.md` for holistic pre-merge review.

---

## Task Count Summary

24 tasks total:
- **1 harness** (Task 1)
- **2 format/validator** (Tasks 2–3)
- **4 hooks** (Tasks 4–7)
- **2 templates + setup** (Tasks 8–9)
- **3 agents** (Tasks 10–12)
- **3 skill dispatches** (Tasks 13–15)
- **2 wrap memory** (Tasks 16–17)
- **1 atlas update-mode hardening** (Task 18, may no-op)
- **3 CLAUDE.md + validate.sh catchup** (Tasks 19–21)
- **1 gate** (Task 22)
- **2 release** (Tasks 23–24)

Each task: 2–5 min of implementation work + test write. All tests are shell-based assertions on file content, run via `bash scripts/tests/run.sh`.
