# CLAUDE.md

## Project Context

**Turbocharge: Claude Code Plugin Blueprint**

A Claude Code plugin that replaces ad-hoc agents, scattered skills, and custom commands with a single opinionated engineering pipeline. Also serves as a reference implementation for building Claude Code plugins.

### What This Project Is

This is a **plugin** for Claude Code — not a standalone app. It consists of:
- 9 skills (SKILL.md files that define slash commands)
- 6 agents (markdown agent definitions dispatched by skills)
- 2 hooks (SessionStart bootstrap, Stop wrap reminder)
- A marketplace manifest for distribution

### Architecture

```
Plugin Structure:
  skills/         → SKILL.md files (user-invocable slash commands)
  agents/         → Agent definitions (dispatched by skills, not invocable directly)
  hooks/          → hooks.json + content files (lifecycle automation)
  .claude-plugin/ → plugin.json manifest
  settings.json   → Plugin-scoped settings
```

### The Pipeline

```
brainstorm → story → plan → build → review → ship
                                  |               |
                                debug            wrap
```

### Distribution

```
Source repo:      nicodiansk/turbocharge (this repo)
Marketplace repo: nicodiansk/turbocharge-marketplace
Install:          claude plugin marketplace add nicodiansk/turbocharge-marketplace
                  claude plugin install turbocharge
Local dev:        claude --plugin-dir /path/to/turbocharge
```

### Domain Terms

| Term | Definition |
|------|------------|
| **Skill** | A SKILL.md file in `skills/<name>/` — becomes `/turbocharge:<name>` |
| **Agent** | A markdown file in `agents/` — dispatched by skills via the Agent tool |
| **Hook** | Shell command executed at lifecycle events (SessionStart, Stop, PreToolUse) |
| **Marketplace** | GitHub repo with `.claude-plugin/marketplace.json` that indexes plugins |
| **Iron Law** | An enforced constraint (not a suggestion) baked into skill definitions |
| **Red Flag** | Anti-rationalization table that catches Claude skipping process steps |

---

## Development Conventions

### File Types

| File | Format | Purpose |
|------|--------|---------|
| `skills/<name>/SKILL.md` | Markdown with YAML frontmatter | Skill definition (prompt template) |
| `agents/<name>.md` | Plain markdown | Agent system prompt |
| `hooks/hooks.json` | JSON | Hook registration (lifecycle → command mapping) |
| `hooks/*.md` | Markdown | Hook content (injected into context) |
| `.claude-plugin/plugin.json` | JSON | Plugin manifest (name, version, author) |
| `settings.json` | JSON | Plugin-scoped Claude Code settings |

### Skill Anatomy

Every skill MUST have:
1. YAML frontmatter with `name`, `description`
2. Clear instructions Claude can follow without ambiguity
3. A "Red Flags" section for anti-rationalization (build, review, debug at minimum)
4. Chain-forward: suggest the next skill in the pipeline

### Versioning

- Version lives in `.claude-plugin/plugin.json`
- Marketplace manifest version must match after publishing
- Use semver: patch for fixes, minor for new skills/features, major for breaking changes

### Testing Locally

```bash
# Load plugin from local directory
claude --plugin-dir .

# Validate plugin structure
./scripts/validate.sh
```

### Publishing Flow

1. Bump version in `.claude-plugin/plugin.json`
2. Push to `nicodiansk/turbocharge` (source repo)
3. Update version + description in `nicodiansk/turbocharge-marketplace` marketplace manifest
4. Users run `claude plugin update turbocharge`
