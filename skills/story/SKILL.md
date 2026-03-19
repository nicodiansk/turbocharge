---
name: story
description: Use when you have requirements, PRDs, or feature descriptions that need to become implementable work. Transforms requirements into INVEST-compliant user stories with testable acceptance criteria.
disable-model-invocation: true
argument-hint: "[requirements-source]"
---

# Story Breakdown

Transform requirements into INVEST-compliant user stories with testable acceptance criteria.

**Announce:** "Using story breakdown to create implementable stories."

## The Iron Law

```
NO STORY WITHOUT ACCEPTANCE CRITERIA
```

Every story must have testable acceptance criteria before implementation.

**No exceptions:**
- Don't start work without criteria
- Don't assume "obvious" criteria
- Don't defer criteria to "later"
- Later never comes

## INVEST Criteria

Every story MUST pass:

| Criterion | Question | Failure Symptom |
|-----------|----------|-----------------|
| **I**ndependent | Can this ship without other stories? | "We need to do X first" |
| **N**egotiable | Can scope be discussed? | "It has to be exactly this" |
| **V**aluable | Does user/business care? | "It's technical debt" |
| **E**stimable | Can team size it? | "No idea how long" |
| **S**mall | Fits in one iteration? | "It's a 2-week story" |
| **T**estable | Can we verify done? | "We'll know when we see it" |

**Failing any criterion = story needs work.**

## Epic Template

```markdown
# Epic: [Name]

## Problem Statement
[What problem does this solve? Who has this problem?]

## Success Metrics
- [Measurable outcome 1]
- [Measurable outcome 2]

## Scope
### In Scope
- [Feature/capability]

### Out of Scope
- [Explicitly excluded]

## Stories
1. [Story 1 title]
2. [Story 2 title]

## Dependencies
- [External dependencies]

## Risks
- [Risk]: [Mitigation]
```

## Story Template

```markdown
# Story: [Title]

**As a** [role/persona],
**I want** [capability/feature],
**So that** [benefit/value].

## Acceptance Criteria

### Criterion 1: [Name]
**Given** [precondition]
**When** [action]
**Then** [expected result]

### Criterion 2: [Name]
**Given** [precondition]
**When** [action]
**Then** [expected result]

## Technical Notes
- [Implementation consideration]

## Story Points: [1/2/3/5/8]
```

## Breakdown Process

### Phase 1: Understand the Epic
1. Identify the user/persona
2. State the core problem
3. Define success metrics
4. List what's explicitly OUT of scope

### Phase 2: Slice by User Value
- What's the smallest valuable increment?
- Split by workflow, not by component
- Each story = one user capability

**Good splits:** By workflow step, user role, data type, happy path vs error
**Bad splits:** By technical layer, by file, by developer

### Phase 3: Apply INVEST
Run each story through all 6 criteria. Fix failures. Re-split if needed.

### Phase 4: Write Acceptance Criteria
1. Start with happy path
2. Add error states
3. Add edge cases
4. Each criterion = one test case

## Sizing Guide

| Points | Meaning | Example |
|--------|---------|---------|
| **1** | Trivial | Copy change, config toggle |
| **2** | Simple | Add field, simple validation |
| **3** | Moderate | New form, basic CRUD |
| **5** | Complex | Multi-step flow, integration |
| **8** | Too large | Needs to be split |

**If >5 points, split the story.**

## Red Flags — STOP

| Flag | Problem |
|------|---------|
| "Technical story" | No user value — attach to user story |
| "As a developer" | Wrong persona — find the actual user |
| No acceptance criteria | Not a story — it's a wish |
| Vague criteria | "Works correctly" — define what correct means |
| >5 points | Too big — split it |
| Implementation in story | "Using React" — describe WHAT not HOW |

## After Stories Are Complete

- Save to `docs/plans/YYYY-MM-DD-<feature>-stories.md`
- Commit
- Offer: "Ready for implementation planning?" → chains to `/turbocharge:plan`

## Workflow Position

```
brainstorm → story → plan → build → review → ship
```
