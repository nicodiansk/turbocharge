# Positioning & README Rewrite v2 — Design

**Date:** 2026-04-13
**Status:** Approved (brainstorm complete, ready for plan/story breakdown)
**Skill:** brainstorm → plan
**Supersedes pitch layer of:** `README.md` (v2.3.0 scaffold — structure kept, copy replaced)

---

## Problem

The v2.3.0 README rewrite fixed the *shape* of the pitch (hero → why → install → pipeline → with/without → what-you-get → iron laws → deep-dives) but the *copy* doesn't land. User quote from the 2026-04-13 wrap: *"I don't like how turbocharge is sold."*

Diagnosed failure modes in the current copy:
- Tagline ("One pipeline. No agent sprawl. From idea to shipped code.") is three claims competing for attention, none of which is ownable.
- "Why" section opens with "Claude Code's agent ecosystem has a drift problem" — an abstract industry complaint, not a scene the reader recognizes.
- Capability-brag phrases ("Enforced review chains. No ambiguity.") assert claims instead of *showing* them.
- The memory/wrap capability — turbocharge's most compounding feature — is invisible in the pitch.

---

## Positioning Core

### Register (3-beat)

| Beat | What it promises | Vocabulary |
|------|------------------|------------|
| **(B) Discipline** *(lead)* | Refuses to let you skip your own process | refuses, won't, enforced, gated, mandatory |
| **(A) Calm** *(sub-beat)* | One pipeline, no decisions to make | one, no, stop choosing, on rails |
| **(C) Compounding** *(third beat)* | Claude remembers what you taught it last session | remembers, carries over, inherits |

**Banned vocabulary** (this is ruflo's register, not ours):
- "powerful," "comprehensive," "advanced," "platform," "framework"
- Numbered capability-brags: "100+ agents," "310 MCP tools"
- "Orchestration" in the tagline (ruflo owns it)
- "Learns" when describing memory (too ML-flavored; say "remembers")

### Tagline

**Primary:** *"Claude Code with a spine."*

**Subtitle:** *"An opinionated pipeline that refuses to let you skip review, skip tests, or pick the wrong agent."*

Rationale: "Spine" carries structure *and* courage in one syllable. Nobody else can say this line. It survives quoting out of context (tweet, marketplace row, npm card).

### Hero paragraph (two sentences, under the tagline)

> *"Turbocharge is the pipeline you'd build yourself if you had six months — and the discipline you'd enforce if you weren't tired at 11 PM. Ten skills, six agents, three hooks, one chain of command. Install it and stop maintaining your own orchestration.*
>
> *It also remembers. Every session you close with `/wrap` teaches Claude something — your preferences, your conventions, the corrections you made today. Next Monday, Claude already knows."*

### Enemy pair (what turbocharge replaces)

1. **The reader's own `~/.claude/agents/` graveyard** — DIY orchestration that grew into a framework they now maintain instead of shipping.
2. **The reader's own good intentions** — code review when they remember, TDD when not tired, root-cause when the bug is bad enough.

---

## The Five Scenes (narrative spine)

Replaces the current "Why" section entirely. Each scene: `### <Scene Title>`, Before/After paragraph pair (2–3 sentences each), `![gif:<scene-name>]` VHS slot.

| # | Title | Before | After | Primary register beat |
|---|-------|--------|-------|----------------------|
| 1 | **The 11 PM Skip** | Feature works. You know you should review. You don't. Teammate finds the bug two days later. | `/turbocharge:build` won't mark complete until the review chain runs. Not a button — the pipeline. | (B) Discipline |
| 2 | **The Agent Graveyard** | `code-reviewer.md`, `code-reviewer-v2.md`, `tdd-guide.md`, `tdd-guide-strict.md` — Claude picks one at random. | One plugin. Ten skills. Six agents. `/turbocharge:setup` deletes the graveyard. | (A) Calm |
| 3 | **The Monday Re-explain** | You explain *again*: immutable patterns, tests in `__tests__/`, small files. Same speech as Friday. | `/wrap` wrote it all to memory Friday afternoon. Monday's Claude read it before you sat down. | (C) Compounding |
| 4 | **The Context Amnesia** | Monday. "Where was I?" You scroll terminal history, read your own commits, rebuild the mental model. 20 minutes gone. | `/wrap` captured it. Fresh session picks it up. Coding in 90 seconds. | (C) Compounding |
| 5 | **The Guess-and-Check Debug** | Test fails. Try something. Still fails. Try something else. An hour later it's green but you don't know why. | `/turbocharge:debug` forces a four-phase root-cause investigation *before* any fix. You understand the break before you unbreak it. | (B) Discipline |

---

## README Structure Map (v2.3.0 scaffold → v3 copy)

1. **Hero block** — logo slot (MCP-generated), `# Turbocharge`, tagline, subtitle, badges row.
2. **Hero paragraph** — two sentences from §Positioning Core above.
3. **Five Scenes** — replaces the current "Why." Each scene is a sub-section with Before/After + VHS gif.
4. **Install block** — three commands (`marketplace add`, `install`, first-run `/setup`) + one reassurance line: *"`setup` cleans up any conflicting agents or skills before you start. Run it once."*
5. **Pipeline diagram** — ASCII art kept. Caption reframed: *"Enter at any step. Each skill gates the next — review before ship, root-cause before fix, wrap before you forget."*
6. **With/Without table** — kept structure, rewritten voice (Before/After per row), new row: *"Claude gets smarter across sessions? · Without: you re-explain every Monday. With: memory populated by `/wrap`."*
7. **What You Get** — 10 skills + 6 agents + 3 hooks tables. Rewrite each "Does" column as a *constraint or relief*, not a feature brag. Example: `build` → *"Dispatches builder agents. Refuses to mark a task complete until spec + quality review pass."*
8. **Iron Laws** — kept verbatim; already nails the (B) register.
9. **Collapsible deep-dives** (`<details>`) — What to remove, Complementary skills, Directory structure, Validation. Kept.
10. **License footer** — kept.

### Drops

- Opening "agent ecosystem drift" paragraph.
- Self-congratulatory "Turbocharge is the *only* orchestration system you install" (relocated as a subtle beat inside scene 2 After).
- Any capability-brag phrase — replaced with Before/After scenes that *show* the claim.

---

## Visual Identity Workstream

Two separate sub-workstreams. Different tools, different outputs, different cadences.

### (a) Scene gifs — **VHS (Charmbracelet)**

- Install: `brew install vhs` (or `go install github.com/charmbracelet/vhs@latest`)
- Author one `.tape` file per scene under `vhs/<scene-name>.tape`
- Renders to `images/scenes/<scene-name>.gif` on `vhs <tape>`
- Reproducible, version-controlled, CI-regenerable on every version bump
- Supports GIF/MP4/WebM; GIF is native, no post-processing
- Register fit: shows the *actual* Claude Code CLI — authenticity > motion-graphics polish
- Five tape files needed: `11pm-skip.tape`, `agent-graveyard.tape`, `monday-reexplain.tape`, `context-amnesia.tape`, `guess-and-check.tape`
- Each tape scripts the Before keystrokes, then the After keystrokes, producing one gif per scene

### (b) Logo / hero banner — **`mcp-hfspace` + FLUX.1-Krea-dev** (locked)

Chosen after 2026-04-13 web research (see design §Open Decisions resolution below).

**Install** (one command, in Claude Code):
```bash
claude mcp add-json "mcp-hfspace" '{"command":"npx","args":["-y","@llmindset/mcp-hfspace"]}'
```
Then at `https://huggingface.co/mcp/settings`, add `mcp-tools/FLUX.1-Krea-dev` to Spaces Tools.

**Why this tool:**
- 100% free via HuggingFace ZeroGPU — no API keys, no billing
- FLUX.1-Krea-dev specifically trained to eliminate the "AI look" — realistic textures, natural lighting, matches our honest/structural register (not ruflo's chrome-metallic aesthetic)
- Spaces-based = upgrade path to self-hosted Space if we hit ZeroGPU quota ceilings

**Caveats:**
- ZeroGPU timeouts possible under heavy Hub load; retry is the mitigation
- PNG output only; SVG vectorization needs a post-processing step (Inkscape trace or `vtracer` — both free)

**Output:**
- `images/logo.svg` (vectorized from best PNG iteration)
- `images/logo.png` (source raster, 1024×1024)
- `images/banner.png` (wide aspect, README hero block)

**Style brief for prompt authoring:**
- Spine motif — literal anatomical spine or abstract vertical-segmented column
- Monochrome or two-tone (no rainbow gradients)
- Evokes structure + restraint, not power + scale
- Explicitly negative prompt: "glossy, chrome, metallic, futuristic, swirling energy, neural network, glowing, holographic"

### (c) 6-second hero animation — **Motion Canvas** (locked, swapped from Remotion 2026-04-13)

**In scope for v3.** Hero block sits above the tagline; a 6-second looping animation sells the "spine" metaphor in motion before the reader reads a word. Concept brief: a `~/.claude/agents/` jumble of files collapses/folds/aligns into a single vertical spine of ten labeled segments (the ten skills). No narration, no text overlay — just the visual transformation.

**Tool choice: Motion Canvas** — swapped from Remotion after 2026-04-13 web-search re-check. Motion Canvas is **MIT, free forever, no engineer-count strings**; Remotion is source-available and requires a paid license for orgs with ≥4 engineers. Motion Canvas's imperative generator-based timeline API also fits the three-phase animation (jumble → collapse → hold) more naturally than Remotion's per-frame interpolation.

**Install:**
```bash
npm init @motion-canvas@latest motion
```
Project lives in `motion/` at repo root. Renders MP4 via the Motion Canvas editor or `npm run render`; GIF is produced by post-processing the MP4 with `ffmpeg` (already installed for VHS).

**Output:** `images/hero.gif` (web-optimized, <2 MB) + `images/hero.mp4` (fallback for high-DPI renders). Embedded at the very top of the README, above `# Turbocharge`.

**Free-tool mapping (full stack, locked):**

| Workstream | Tool | Licensing |
|------------|------|-----------|
| Scene gifs | **VHS** (Charmbracelet) | MIT, fully OSS |
| Logo / banner | **`mcp-hfspace`** + FLUX.1-Krea-dev | Free via HF ZeroGPU |
| Hero animation | **Motion Canvas** | MIT, free forever (no engineer-count strings) |

---

## Open Decisions (deferred — not blocking plan/story)

1. ~~**MCP image generator pick**~~ — **Locked 2026-04-13:** `mcp-hfspace` + FLUX.1-Krea-dev.
2. ~~**Hero animation tool pick**~~ — **Locked 2026-04-13:** Motion Canvas (swapped from Remotion same day after 2026 web-search re-check confirmed Motion Canvas is the only fully-MIT free option; removes the licensing caveat for future adopters).
3. **Logo style** — abstract spine (recommended), literal anatomical spine (bold), typographic wordmark (safe). Iterate during the logo-generation task.
4. **VHS theme** — default Charm theme vs custom matching the logo palette. Decide after logo lands so they're coherent.
5. **Whether to add a 6th scene for `/ship`** — current 5 scenes skew toward `build`, `wrap`, `debug`. `ship` / `plan` / `story` are underrepresented. Possible add: *"The Stalled PR"* — but risks bloating the narrative spine. Default: ship with 5.

---

## What We're NOT Building (this iteration)

- No multi-language pitch variations (English only for v3).
- No rewritten pipeline diagram or iron-laws section — both are working; don't touch.
- No new deep-dive sections. `<details>` blocks stay as-is.
- No docs site, no landing page outside GitHub. README is the whole pitch surface.

---

## Scope

**Files modified:**
- `README.md` — hero, scenes section (new), install, with/without rows, what-you-get copy. Preserves scaffold structure.
- `images/` — new `logo.svg` + `banner.png` + `scenes/*.gif` (5 files).
- `vhs/` — new directory with 5 `.tape` files.

**Files added:**
- `vhs/<5 tapes>.tape`
- `images/scenes/<5 gifs>.gif`
- `images/logo.svg`, `images/banner.png`

**External:**
- MCP image generator install (one-time, user workspace).
- VHS install (one-time, user workspace).

**No version bump required** — copy + assets only, no plugin behavior change. Could be a patch (2.3.0 → 2.3.1) if the user wants to signal the README rewrite shipped.

---

## Chain Forward

Ready for `/turbocharge:story` to break this into INVEST-compliant stories, then `/turbocharge:plan` for task breakdown. Recommended story decomposition:
1. **Positioning copy rewrite** — hero, tagline, subtitle, enemy paragraph. No assets needed; pure text.
2. **Five Scenes prose** — Before/After copy for all five scenes. No gif dependency.
3. **With/Without + What You Get copy** — rewrite remaining sections.
4. **VHS setup + 5 tapes + gif generation** — tool install, tape authoring, rendering.
5. **Logo generation via MCP** — install one MCP image tool (HuggingFace or Gemini-free), iterate to final logo + banner, drop into README.
6. **Hero animation via Motion Canvas** — scaffold project in `motion/`, author the spine-collapse scene, render to `images/hero.mp4` then convert to `images/hero.gif` via ffmpeg.
7. **Final README assembly + polish pass** — stitch copy + assets, verify links/images render on GitHub.

Stories 1–3 are purely text (unblocked). Stories 4–6 are asset workstreams that run in parallel to 1–3 and merge at story 7. All tools free.
