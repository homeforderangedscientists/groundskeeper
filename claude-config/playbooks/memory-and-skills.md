# Memory and Skills

> Persistence. Memory is what makes the loop stick from Tuesday to Thursday. Skills are where repeated corrections live as executed procedures instead of hoped-for habits.

## Memory hygiene

### Memory has four types. Use the right one or it rots
**Why:** User facts, feedback, project state, and reference pointers have different staleness profiles. Mixing them produces a junk drawer where nothing is trusted because some of it is always wrong.
**How to apply:** User preferences → **user memory**. Corrections from past conversations → **feedback memory**. Sprint cycle, current version, live project state → **project memory**. Pointers to Linear/Slack/external docs → **reference memory**. Write the type at the top of every memory file.

### Stale memory is worse than no memory
**Why:** An agent with no memory asks. An agent with stale memory acts — confidently, on last quarter's facts, with no tell that anything's wrong. The lookup the first agent would do is the one the second agent skips.
**How to apply:** When you read a memory line and it's wrong, fix or delete it in the same turn. Not "I'll clean that up later." Later is the bug. Budget a memory pass at the end of every release, with a bias toward deletion.

### Save the why, not just the rule
**Why:** A year from now, "always use X" is unfollowable when X conflicts with the new architecture. "Always use X because Y bit us in v4.0" lets future-you decide whether the rule still applies or whether the world moved on.
**How to apply:** Every feedback memory needs a **Why** line and a **How to apply** line. Always. If you can't write the why, you don't understand the rule well enough to save it.

### Don't memorize what the code already says
**Why:** File paths, function names, module boundaries, route registrations — all one grep away. Duplicating what the code says is how memory silently disagrees with reality the moment someone renames a file.
**How to apply:** If you can find it with one grep, don't put it in memory. If it lives in `git log`, don't put it in memory. If a test asserts it, double-don't — the test is already the source of truth.

## Skills

### Skills are procedures with discipline. CLAUDE.md notes are facts you hope get followed
**Why:** A procedure buried in CLAUDE.md is ambient noise — I read it and don't follow it because it wasn't invoked. Skills are executed on purpose, step by step.
**How to apply:** If a thing must happen reliably, it needs a host other than my attention. Promote "remember to do X" from CLAUDE.md to a skill that executes X.

### Rigid skills exist for a reason. Don't adapt the discipline away
**Why:** Rigid skills (TDD, systematic debugging, verification-before-completion) feel like overkill in exactly the moments they're needed most — when you're tired, when you're sure, when the fix is "obvious."
**How to apply:** When a skill says "do this exact sequence," do the exact sequence. If you're thinking "I'll skip step 3 because I already know," that's the thought the skill exists to interrupt.

### Write a skill after the third correction
**Why:** The first correction is a one-off. The second is a pattern. The third is the moment "I keep saying this" becomes "the system should enforce this." Promoting earlier wastes a skill slot on a fluke; promoting later means you've spent a week re-typing the same sentence. Three is the elbow of the curve.
**How to apply:** Count your corrections. When you catch yourself typing the same correction into a fresh conversation for the third time, stop — that's the promotion line. Decide: skill, hook, or infrastructure change (rip out the thing that makes the old mistake possible).

## When to promote vs when to duplicate

Promotion has a cost: a shared abstraction is code every consumer becomes coupled to. Abstractions over code that isn't *actually* duplicated yet are worse than the duplication they claim to fix.

- **Extract when the pattern has stabilized** across callers and nobody is inventing new variants.
- **Don't extract while the second caller is still finding its shape** — duplicate for now, revisit later.
- **Extract regardless of stability if duplicates are drifting silently.** Drift is the more dangerous failure — when one copy forgets an edge case the others handle, the bug appears only on the path nobody tested.

The test has two parts: (1) is the logic still finding its shape (duplicate) or has it stabilized across callers (extract); and (2) are the copies drifting silently (extract regardless).

## See also

- `workspace.md` — the five layers (memory is one of them)
- `the-loop.md` — correct drift early, budget a memory pass per release
