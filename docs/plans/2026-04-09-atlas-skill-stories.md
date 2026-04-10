# Atlas Skill — User Stories

**Epic:** Add `/turbocharge:atlas` skill that generates and maintains a semantic domain map (ATLAS.md) for projects. Complements codemap's structural index (symbol→location) with the domain layer (purpose→relationships→context). Consumer is Claude — optimized for LLM lookup.

**Total:** 7 story points, 3 stories
**Dependency:** Story 1 → (Story 2 + Story 3 in parallel)

---

## Story 1: Atlas Skill Definition (3 pts)

**As a** developer using turbocharge,
**I want** to invoke `/turbocharge:atlas` to generate or update a semantic domain map of my project,
**So that** Claude has persistent domain context without repeated codebase exploration.

### Acceptance Criteria

#### AC1: Skill file exists with valid frontmatter
**Given** the turbocharge plugin
**When** I check `skills/atlas/SKILL.md`
**Then** it has `name: atlas`, a description under 1024 chars, and follows the standard skill anatomy (Iron Law, Red Flags, workflow position)

#### AC2: Generate mode creates ATLAS.md
**Given** a project without an ATLAS.md
**When** I invoke `/turbocharge:atlas`
**Then** Claude reads the codebase and generates an ATLAS.md in the project root with these sections:
- **Project Identity** — one-liner, tech stack, repo structure summary
- **Entry Points** — where execution starts (CLI commands, API routes, jobs, main)
- **Domain Model** — key entities, their relationships, and definitions
- **Data Flows** — how data moves through the system (pipelines, request paths)
- **Module Directory** — what each major directory/module does, key files within each
- **Integration Points** — external services, APIs, databases, queues
- **Conventions & Gotchas** — patterns that aren't obvious, things that trip people up
- **Active Work & Known Issues** — current pain points, tech debt, in-progress migrations

#### AC3: Update mode refreshes stale sections
**Given** a project with an existing ATLAS.md
**When** I invoke `/turbocharge:atlas`
**Then** Claude compares the existing atlas against the current codebase, identifies stale sections, and updates only what changed — preserving manually-added notes

#### AC4: Format is optimized for LLM consumption
**Given** a generated ATLAS.md
**When** Claude reads it in a future session
**Then** each section uses consistent structure (tables, `file:description` pairs, `→` for flows) that Claude can parse without ambiguity. No prose walls — structured data over paragraphs.

#### AC5: Clear boundary with CLAUDE.md
**Given** both CLAUDE.md and ATLAS.md exist
**When** the skill generates the atlas
**Then** it does NOT duplicate content from CLAUDE.md (rules, conventions, instructions). ATLAS.md contains facts about the project; CLAUDE.md contains instructions for Claude.

### Technical Notes
- The skill is a SKILL.md prompt template — Claude does all the work at invocation time
- No agents needed — Claude reads the codebase directly (similar to how setup works)
- Should recommend codemap for structural indexing if not already present
- `disable-model-invocation: false` (pipeline skill convention)

---

## Story 2: Pipeline Integration (2 pts)

**As a** developer using turbocharge,
**I want** other turbocharge skills to consult ATLAS.md when it exists,
**So that** domain context from the atlas flows through plan, build, and debug without manual referencing.

### Acceptance Criteria

#### AC1: Session bootstrap mentions atlas
**Given** the session-bootstrap.md hook
**When** a new session starts
**Then** the bootstrap table includes atlas: "Generate or update the project domain map" → `/turbocharge:atlas`

#### AC2: Plan skill references atlas
**Given** a project with an ATLAS.md
**When** I invoke `/turbocharge:plan`
**Then** the planner reads ATLAS.md for domain context before creating tasks

#### AC3: Wrap skill nudges atlas refresh
**Given** a session where significant code changes were made
**When** I invoke `/turbocharge:wrap`
**Then** the wrap output includes a note: "Consider running `/turbocharge:atlas` to update the domain map"

#### AC4: Setup skill recommends atlas
**Given** a project without ATLAS.md
**When** I invoke `/turbocharge:setup`
**Then** the setup audit mentions: "No ATLAS.md found — run `/turbocharge:atlas` to generate a domain map"

### Technical Notes
- Minimal changes to existing skills — add 1-2 lines referencing ATLAS.md
- Don't make atlas mandatory — skills work without it, just better with it

---

## Story 3: Plugin Release Housekeeping (2 pts)

**As a** turbocharge maintainer,
**I want** the plugin metadata updated for the atlas addition,
**So that** validation passes, documentation is current, and the release is clean.

### Acceptance Criteria

#### AC1: validate.sh includes atlas
**Given** the validation script
**When** I run `./scripts/validate.sh`
**Then** it checks for `skills/atlas/SKILL.md` in the expected skills list and passes

#### AC2: README lists atlas
**Given** the README
**When** I read the skills section
**Then** atlas is listed with a one-line description

#### AC3: Pipeline diagram updated
**Given** the README pipeline diagram
**When** I view it
**Then** atlas appears as a utility skill (accessible from any point, like debug/wrap)

#### AC4: Version bumped
**Given** `.claude-plugin/plugin.json`
**When** atlas is added
**Then** version is bumped to `2.2.0` (minor — new skill) and description updated to "10 skills, 6 agents"

#### AC5: CHANGELOG updated
**Given** the CHANGELOG
**When** the release is prepared
**Then** v2.2.0 entry documents: new atlas skill, pipeline integration updates

### Technical Notes
- Standard release checklist
