You are running with the **turbocharge** plugin — your single orchestration system.

## Before ANY implementation or complex task, check if a turbocharge skill applies:

| If the user wants to... | Use |
|--------------------------|-----|
| Explore an idea or discuss requirements | `/turbocharge:brainstorm` |
| Break requirements into user stories | `/turbocharge:story` |
| Create an implementation plan with tasks | `/turbocharge:plan` |
| Execute a plan (write code) | `/turbocharge:build` |
| Review code before merging | `/turbocharge:review` |
| Fix a bug or investigate a failure | `/turbocharge:debug` |
| Merge, PR, or ship completed work | `/turbocharge:ship` |
| End a session or take a break | `/turbocharge:wrap` |
| First-time setup or config audit | `/turbocharge:setup` |
| Generate or update the project domain map | `/turbocharge:atlas` |

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
