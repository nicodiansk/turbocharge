---
name: brainstorm
description: Use when starting creative work - creating features, building components, adding functionality, or modifying behavior. Explores requirements through Socratic dialogue before any implementation.
---

# Brainstorm

Turn ideas into fully formed designs through collaborative dialogue.

**Announce:** "Using brainstorm to explore this idea before implementation."

## The Iron Law

```
NO IMPLEMENTATION WITHOUT UNDERSTANDING REQUIREMENTS FIRST
```

## Process

### 1. Understand Context
- Check project state (files, docs, recent commits)
- Read agent memory for relevant prior context

### 2. Discover Requirements
- Ask questions **one at a time**
- Prefer **multiple choice** when possible
- Focus on: purpose, constraints, success criteria, users
- Don't overwhelm — one question per message

### 3. Explore Approaches
- Propose **2-3 approaches** with trade-offs
- Lead with your recommendation and reasoning
- Be ready to combine or discard

### 4. Present Design
- Break into sections of **200-300 words**
- Ask after each section: "Does this look right?"
- Cover: architecture, components, data flow, error handling, testing
- Apply YAGNI — remove unnecessary features

### 5. Save and Continue
- Write design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Commit the design document
- Offer: "Ready for story breakdown?" → chains to `/turbocharge:story`
- Or: "Ready for implementation planning?" → chains to `/turbocharge:plan`

## Red Flags — STOP

| Flag | Problem |
|------|---------|
| Jumping to code | Didn't explore requirements |
| Single approach | Didn't propose 2-3 alternatives |
| Wall of text | Present in 200-300 word sections |
| Unanswered questions | Don't design around unknowns |
| No YAGNI review | Remove unnecessary features |

## Workflow Position

```
brainstorm → story → plan → build → review → ship
```
