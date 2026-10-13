---
name: defects-review
tags: [defects]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Agent, Bash, Write, Edit]
---
Review my branch feature/order-report against SPEC.md before I merge it. List each defect you find with its file and line.
