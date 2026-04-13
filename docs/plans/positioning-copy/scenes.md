## Five Scenes

### The 11 PM Skip

_(Before)_ Feature works. You know you should review. You're tired. You don't. Two days later, your teammate finds the bug you'd have caught.

_(After)_ `/turbocharge:build` won't mark the task complete until the spec-reviewer and quality-reviewer have run. It isn't a button you remember to press — it's the only way the pipeline lets you exit.

![scene: 11pm-skip](images/scenes/11pm-skip.gif)

### The Agent Graveyard

_(Before)_ `code-reviewer.md`, `code-reviewer-v2.md`, `tdd-guide.md`, `tdd-guide-strict.md`, `planner.md`, `planner-actually-good.md`. Claude picks one at random. You can't remember which one is current.

_(After)_ One plugin. Ten skills. Six agents. `/turbocharge:setup` audits `~/.claude/agents/` on first run and offers to delete the graveyard. The only orchestration you install is the one you stop maintaining.

![scene: agent-graveyard](images/scenes/agent-graveyard.gif)

### The Monday Re-explain

_(Before)_ Monday morning. You explain it again — immutable patterns, tests live in `__tests__/`, files stay under 400 lines. The exact speech you gave Friday afternoon to a Claude that has since forgotten you exist.

_(After)_ `/wrap` wrote it all to memory Friday at 5 PM — preferences, conventions, the corrections you made that week. Monday's Claude read it before you sat down. You open the laptop and skip the speech.

![scene: monday-reexplain](images/scenes/monday-reexplain.gif)

### The Context Amnesia

_(Before)_ "Where was I?" Scroll terminal history. Re-read your own commits. Open three files to rebuild the mental model. Twenty minutes gone before you write a line.

_(After)_ `/wrap` captured the state — open question, current file, last decision, what's next. The fresh session reads the resume prompt and you're typing code in ninety seconds.

![scene: context-amnesia](images/scenes/context-amnesia.gif)

### The Guess-and-Check Debug

_(Before)_ TODO

_(After)_ TODO

![scene: guess-and-check](images/scenes/guess-and-check.gif)
