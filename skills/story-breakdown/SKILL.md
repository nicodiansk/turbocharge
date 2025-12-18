---
name: story-breakdown
description: Use when transforming requirements, PRDs, or feature descriptions into actionable user stories with INVEST criteria and acceptance criteria
---

# Story Breakdown

## Overview

Transform vague requirements into INVEST-compliant user stories with testable acceptance criteria.

**Core principle:** A story without acceptance criteria is a wish, not a deliverable.

**Violating the letter of the rules is violating the spirit of the rules.**

## When to Use

**Always:**
- PRDs or feature descriptions
- "What should we build" discussions
- Backlog refinement
- Sprint planning
- Requirements handoff

**Keywords that trigger this skill:**
- epic, story, user story, feature
- breakdown, split, decompose
- requirements, backlog, sprint
- "as a user", acceptance criteria

**Relationship with other skills:**
- **brainstorming** = discovery ("what problem are we solving?")
- **story-breakdown** = refinement ("turn idea into actionable stories")

Don't confuse exploration with refinement. If requirements are unclear, use brainstorming first.

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

Every story must pass INVEST:

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
- [Feature/capability 1]
- [Feature/capability 2]

### Out of Scope
- [Explicitly excluded item 1]
- [Explicitly excluded item 2]

## Stories
1. [Story 1 title]
2. [Story 2 title]
...

## Dependencies
- [External dependency 1]
- [Prerequisite work]

## Risks
- [Risk 1]: [Mitigation]
```

## Story Template

```markdown
# Story: [Title]

## User Story
As a [role/persona],
I want [capability/feature],
So that [benefit/value].

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
- [API/data requirement]

## Story Points: [1/2/3/5/8]
```

## Acceptance Criteria Formats

### Given/When/Then (Preferred)
```
Given I am logged in as an admin
When I click "Delete User"
Then a confirmation dialog appears
And the dialog shows the user's name
```

### Checklist (Simple cases)
```
- [ ] Button visible on dashboard
- [ ] Button disabled when no selection
- [ ] Click triggers confirmation
- [ ] Success shows toast notification
```

**Rules:**
- Each criterion tests ONE behavior
- Criteria are independently verifiable
- No vague terms: "fast", "user-friendly", "intuitive"
- Include edge cases and error states

## Breakdown Process

### Phase 1: Understand the Epic
1. Identify the user/persona
2. State the core problem
3. Define success metrics
4. List what's explicitly OUT of scope

### Phase 2: Slice by User Value
1. What's the smallest valuable increment?
2. Can users do something NEW after this ships?
3. Split by workflow, not by component
4. Each story = one user capability

**Good splits:**
- By user workflow step
- By user role
- By data type
- By happy path vs error handling

**Bad splits:**
- By technical layer (UI, API, DB)
- By file/component
- By developer assignment

### Phase 3: Apply INVEST
For each story:
1. Run through all 6 criteria
2. Fix any failures
3. Re-split if needed

### Phase 4: Write Acceptance Criteria
1. Start with happy path
2. Add error states
3. Add edge cases
4. Each criterion = one test case

## Sizing Guide

| Points | Meaning | Example |
|--------|---------|---------|
| **1** | Trivial, <2 hours | Copy change, config toggle |
| **2** | Simple, half day | Add field, simple validation |
| **3** | Moderate, 1 day | New form, basic CRUD |
| **5** | Complex, 2-3 days | Multi-step flow, integration |
| **8** | Large, needs split | Too big - break it down |

**If >5 points, split the story.**

## Red Flags - STOP

| Flag | Problem |
|------|---------|
| "Technical story" | No user value - attach to user story or make it a task |
| "As a developer" | Wrong persona - find the actual user |
| No acceptance criteria | Not a story - it's a wish |
| Vague criteria | "Works correctly" - define what "correct" means |
| >5 points | Too big - split it |
| Compound criteria | "And" in criteria - split into multiple |
| Implementation in story | "Using React" - describe WHAT not HOW |
| Dependencies | "After story X" - not independent |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "We'll figure out criteria later" | Later = never. Define now. |
| "It's obvious what done means" | If obvious, write it down. Takes 2 minutes. |
| "Technical stories are different" | Technical work serves users. Find the user value. |
| "Can't split it smaller" | You can. Split by scenario, data type, or user type. |
| "We know what the user wants" | Assumptions kill projects. Write it down, validate. |
| "Acceptance criteria slow us down" | Unclear criteria slow you down more. |
| "8 points is fine" | 8 points = 8 ways to be wrong. Split it. |
| "This is just for internal use" | Internal users are still users. |

## Integration

### Workflow Position
```
brainstorming → story-breakdown → writing-plans → implementation
```

### Agents
- **story-writer**: Transforms requirements into INVEST stories
- **planner**: Takes stories and creates implementation plans

### Output
Story breakdown produces:
- Epic document (if scope warrants)
- Individual story files
- Acceptance criteria for each story

These feed into **writing-plans** skill for detailed implementation planning.

## Example: Login Feature

**Input:** "Users need to log in"

**Output:**

### Epic: User Authentication

**Problem:** Users cannot access personalized features without identity verification.

**Success Metrics:**
- 95% login success rate
- <3 second login flow
- <1% support tickets about login

### Story 1: Email/Password Login

**As a** registered user,
**I want** to log in with my email and password,
**So that** I can access my account.

**Acceptance Criteria:**

1. **Valid login**
   - Given valid credentials
   - When I submit the form
   - Then I'm redirected to dashboard

2. **Invalid password**
   - Given valid email, wrong password
   - When I submit
   - Then error "Invalid credentials" appears
   - And password field clears
   - And attempt is rate-limited after 5 tries

3. **Unknown email**
   - Given unregistered email
   - When I submit
   - Then error "Invalid credentials" appears
   - (Same message - don't leak user existence)

**Points:** 3

### Story 2: Password Reset Request

**As a** user who forgot my password,
**I want** to request a reset link,
**So that** I can regain access.

**Acceptance Criteria:**

1. **Valid email**
   - Given registered email
   - When I submit reset request
   - Then email sent within 60 seconds
   - And success message shown (same for all emails)

2. **Unknown email**
   - Given unregistered email
   - When I submit
   - Then same success message (security)
   - And no email sent

**Points:** 2

## Verification Checklist

Before declaring stories complete:

- [ ] Every story has a user persona (not "developer")
- [ ] Every story has a value statement (So that...)
- [ ] Every story has acceptance criteria
- [ ] Each criterion is independently testable
- [ ] No vague terms in criteria
- [ ] All stories pass INVEST
- [ ] No story >5 points
- [ ] Edge cases and errors covered
- [ ] Out of scope explicitly stated

Can't check all boxes? Stories aren't ready for implementation.
