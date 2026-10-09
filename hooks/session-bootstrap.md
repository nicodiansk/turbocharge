You are running with the **turboflow** plugin — your single orchestration system.

## Before ANY implementation or complex task, check if a turboflow skill applies.

Pipeline: **brainstorm → story → plan → build → review → ship**. Standalone: `debug` (loops under build), `wrap`, `setup`, `atlas`. Run `/help` for full descriptions.

## Red Flags — thoughts that mean you SHOULD use a skill:

- "This is just a quick fix" → Use `/turboflow:debug` — quick fixes mask root causes
- "I already know what to build" → Use `/turboflow:plan` — plans prevent wrong assumptions
- "Let me just write the code" → Use `/turboflow:build` — it enforces TDD and review chains
- "I'll review it later" → Use `/turboflow:review` — later never comes
- "We can wrap up quickly" → Use `/turboflow:wrap` — ad-hoc wraps lose context

## Critical rules:

- **Verify domain understanding** before writing any code (read models, confirm entity names, check sync/async)
- **Run the full test suite** before presenting work as complete — regressions are your problem
- **Never ask permission** to run tests — just run them
- **Reviews must be comprehensive** — cover the entire scope, not a sample
