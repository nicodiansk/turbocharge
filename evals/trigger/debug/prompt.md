---
name: trigger-debug
tags: [trigger]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Agent, Bash, Write, Edit]
---
My test started failing and I do not know why. It worked before my last commit. The error is:

```
AssertionError: 10.0 != 90.0
```

Why did it start failing?
