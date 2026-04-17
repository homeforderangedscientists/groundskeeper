# The Loop

**Prereq skills:** `superpowers:brainstorming`, `superpowers:writing-plans`, `superpowers:test-driven-development`, `superpowers:verification-before-completion`. Those skills execute the individual steps. This playbook is about *how the loop fits together*: first-conversation discipline, pacing, drift correction, and cycle nesting. See `prereqs.md`.

> The core development cycle — **brainstorm → plan → TDD → verify → commit → retro** — plus first-conversation discipline. Every rule in the other playbooks hangs off this.

## First conversation

### Bootstrap with the smallest context that contains the answer
**Why:** Dumping the whole repo into the window dilutes the signal. Token budget is attention budget.
**How to apply:** Hand me the load-bearing files — CLAUDE.md or the relevant doc, the file you're editing, the test that pins its behavior. Let me pull more if I ask. Don't preload "just in case."

### Correct drift in message 2, not message 50
**Why:** Corrections early are nearly free. Corrections late mean rewriting ten turns built on top of the drift.
**How to apply:** The moment I do something you don't want — naming, tone, pattern, where I put the file — stop and say so. Then ask whether the correction should become a memory entry so the next conversation starts already corrected.

### If the agent doesn't know something, tell it. Don't let it guess
**Why:** Hallucination is most likely when I'm confidently filling a gap. "It should know that" is the engineer's fault, not mine — I only know what's in the window.
**How to apply:** Any time you catch yourself thinking "well it should know" — stop and write it down. Feed it in. Then put it in CLAUDE.md or memory so the next session starts with it.

## The loop (six steps)

Brainstorm → Plan → TDD → Verify → Commit → Retro. Each step catches a class of failure the others can't. Skip a step out loud or pay for it silently.

### Run the whole loop. Skip a step out loud or pay for it silently
**Why:** Each step catches a different class of failure that the others can't: scope drift, missing files, wrong implementation, "tests green / feature broken," irreversibility, and the mistake you're about to repeat.
**How to apply:** Run all six for every non-trivial task. Each step has its own superpowers skill that enforces the discipline — load the one you need at that step. If you skip a step, say which and why. "I'm skipping TDD because this is a doc-only change" is fine. Silently skipping is how you get surprise regressions on Thursday.

### Brainstorm before planning. Plan before code
**Why:** A plan written from a vague idea is a wish list. Code written from a vague plan is a mess you rewrite. Out of order, the bounds are hallucinated.
**How to apply:** Even for a one-day task, brainstorm first (`superpowers:brainstorming` sets the discipline). Then plan (`superpowers:writing-plans` + the `plan-quality.md` rubric). Then code. *Qualifier:* the brainstorm amortizes across cycles when the work is repetitive and the upfront thinking was rigorous (e.g., a single PRD feeding ten releases). The test: are the current cycle's decisions pinned by the earlier brainstorm, or being reinvented each release? If reinventing, the brainstorm is stale; redo it.

### Frequent commits are not optional
**Why:** Agents introduce subtle bugs across many files at once. Bisecting only works if commits are small enough to bisect against. One giant commit is an unbisectable wall.
**How to apply:** One logical change, one commit. If you can't summarize the diff in one sentence, split it. *Precondition:* the pipeline must be fast enough to support this cadence. If CI takes 40 minutes per push, the rule inverts — batch changes, fix the pipeline first. See `pipeline-foundation.md`.

### Retros feed the next loop
**Why:** The lesson learned in retro N becomes the rule applied in loop N+1. Without retros, the loop forgets — and a loop with no memory is a hamster wheel that compiles.
**How to apply:** A retro is mandatory at the end of every release, even small ones. An honest paragraph beats a dishonest page. See `retros.md` for the full discipline.

### Cycles nest. Each level needs a theme, a boundary, and all three phases
**Why:** A loop at the wrong scale is either too small to ship anything meaningful or too big to retro honestly. Cycles without themes get named by date and forgotten.
**How to apply:** The task-level loop is the six steps as written. The release-level loop is the same shape on a larger canvas: a themed slice of the roadmap, an upfront plan (often a file map for parallel work), execution (often in waves), validation in the environment that matters, and a retro written in voice with a nickname. The project level is the same again: a PRD that sets the arc, a roadmap, a final retro. Each level needs a name you could say in one sentence and a boundary someone outside the work would recognize as shippable.

## See also

- `plan-quality.md` — what makes a plan executable
- `verification.md` — the "verify" step
- `retros.md` — the "retro" step (load-bearing)
- `memory-and-skills.md` — what to do with a correction that keeps coming up
