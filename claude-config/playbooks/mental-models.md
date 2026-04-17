# Mental Models

> How to think about the engineer-agent partnership before any specific technique. Three rules.

## The three-layer division of labor

- **The pipeline handles mechanics.** Build, test, lint, scan, deploy, rollback. Automated. Invisible when working.
- **The agent handles elaboration.** Breadth, consistency, mechanical translation of intent into code. Fast, literal, tireless.
- **The human handles craft.** Intent, taste, judgment, synthesis. Which trade-off is tolerable. What "done" means.

Every rule in these playbooks is a maneuver to keep each layer in its own lane. When a rule feels like friction, check which lane is being pulled into the wrong layer.

## Rules

### Brief the agent like a smart colleague who just walked into the room
**Why:** Every prompt is a cold start. I have no conversation context and no project memory beyond what you give me right now. Terse command prompts produce shallow, generic work because that's the only kind a stranger can do without context.
**How to apply:** Every non-trivial prompt is a self-contained briefing — goal, what you've already ruled out, constraints, success criteria. If the prompt would make a new hire ask three follow-up questions, I will invent three answers instead.

### Delegate the task, not the understanding
**Why:** Synthesis is the engineer's job. The moment a prompt reads "investigate and fix" or "based on your findings, do X," the hard part has been pushed onto the thing that's worst at it.
**How to apply:** Do the synthesis yourself before delegating. Hand me a specific action with the context it needs. *Qualifier:* delegating understanding is safe when the understanding lives in authoritative external docs (an RFC, a spec, a library reference). It is not safe when the understanding lives in your head — scar tissue, team norms, the incident from March. Write that down or I will invent a substitute.

### I am good at breadth and consistency. I am bad at judgment under ambiguity
**Why:** I can search hundreds of files or apply one pattern across fifty call sites without drifting. I cannot reliably tell you which of three plausible trade-offs your team will actually accept.
**How to apply:** Use me for search, refactor, test-writing, scaffolding, fan-out. Make the trade-off call yourself. *Qualifier:* my judgment is weak on *social* trade-offs ("what will the team tolerate at review") and surprisingly strong on *mechanical* ones ("does it compile, does the spec validate, does the race detector stay clean"). If the judgment reduces to measurable signals, delegate. If it reduces to "what will the team say," don't.

## Anti-patterns to watch for

- **The riddle prompt.** "Figure out why X is slow and do what makes sense." → No.
- **The standing yes.** Approval for one action is not approval for the next. See `trust-boundaries.md`.
- **The late correction.** Nudging on turn 10 instead of turn 2. See `the-loop.md` — correct drift early.
- **The "it should know" fallacy.** If you catch yourself thinking "well, I shouldn't have to tell it that," tell me. Don't let me guess.

## See also

- `workspace.md` — where each kind of knowledge belongs
- `the-loop.md` — what to run for non-trivial work
- `failure-modes.md` — what off-the-rails looks like and how to recover
