You are running with the **turbocharge** plugin — your single orchestration system.

## Before ANY implementation or complex task, check if a turbocharge skill applies.

Pipeline: **brainstorm → story → plan → build → review → ship**. Standalone: `debug` (loops under build), `wrap`, `setup`, `atlas`. Run `/help` for full descriptions.

## Red Flags — thoughts that mean you SHOULD use a skill:

- "This is just a quick fix" → Use `/turbocharge:debug` — quick fixes mask root causes
- "I already know what to build" → Use `/turbocharge:plan` — plans prevent wrong assumptions
- "Let me just write the code" → Use `/turbocharge:build` — it enforces TDD and review chains
- "I'll review it later" → Use `/turbocharge:review` — later never comes
- "We can wrap up quickly" → Use `/turbocharge:wrap` — ad-hoc wraps lose context

## Critical rules:

- **Verify domain understanding** before writing any code (read models, confirm entity names, check sync/async)
- **Run the full test suite** before presenting work as complete — regressions are your problem
- **Never ask permission** to run tests — just run them
- **Reviews must be comprehensive** — cover the entire scope, not a sample
