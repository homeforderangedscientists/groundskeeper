# Plan Quality

**Prereq skill:** `superpowers:writing-plans` covers *how* to write a plan. This playbook is the *rubric* for whether the plan you wrote is good enough to execute. See `prereqs.md`.

> A plan is a contract you write with future-you. Future-you will be context-deprived, possibly stressed, definitely without the reasoning you had during planning. The plan either carries that reasoning forward or it doesn't — and if it doesn't, future-you will fill the gaps with whatever seems plausible.

## Rules

### A plan with placeholders is a wish list
**Why:** "TODO: handle errors later" is the engineer outsourcing the hard part to future-them. Future-them will be confused, stressed, and without context. The hard part has to be done *at plan time*, not at implementation time.
**How to apply:** Every step contains the actual content. No "TBD," no "similar to above," no "implement later," no "add appropriate error handling." If you can't say what the error handling is, you're not ready to plan it yet — go back to brainstorming. A plan you can read and nod along to but couldn't execute yourself isn't specific enough.

### Each step is one action, two to five minutes long
**Why:** Bigger steps hide complexity and break the TDD rhythm. "Implement the feature" is a chapter, not a step. Small steps also mean small blame radius — when a step fails you know exactly where.
**How to apply:** "Write the failing test" is a step. "Run the test and verify it fails" is a step. "Write the minimal implementation" is a step. If a step would take longer than five minutes, split it. *Qualifier:* the five-minute rule is a *proxy* for "small blame radius." When architecture hands you small blame radius for free (a one-feature-per-directory layout, a tight interface contract, a self-contained package with its own test file), a single step can be larger than five minutes and still satisfy the rule. Check the proxy against the goal.

### The plan must cover the spec
**Why:** A plan that drifts from the spec produces a feature that drifts from the requirement. Every section of the spec without a corresponding task is not a gap in the plan — it is a gap in the feature.
**How to apply:** After writing the plan, walk every spec section and point at the task that implements it. If a section has no task, you have a hole — not a feature, a hole. *Qualifier — cross-system ordering:* when a plan touches more than one system (code + infrastructure, code + migrations, code + secrets vault, code + DNS), the *order of operations* is part of the spec, even when the spec doesn't say so out loud. For every task, ask: "what must already be true in some other system before this task can run?" and add the prerequisite as its own earlier task.

### Descope explicitly. Name what's out, and name why
**Why:** A plan that only names what's *in* silently hopes everyone agrees on what's *out*. They won't. The items you silently omit will come back as surprise asks during implementation, as scope creep during review, or as "wait, I thought we were doing that" at the retro.
**How to apply:** In every plan, write a dedicated "Descoped" section. List every item the plan considered and decided not to do. Give each a named reason — "hardware-dependent, untestable in CI," "dependency too large for this release," "spec evolves faster than we can keep up," "low value for the complexity cost." A descope with a reason is a negotiable contract. A descope without a reason is an argument waiting to happen.

## Plan template

```md
# Plan: [one-line description]

## Goal
[1-2 sentences: what this achieves, why it matters, what "done" looks like.]

## Spec coverage
[Walk the spec. Each requirement → which step satisfies it.]
- Requirement A → Step 3
- Requirement B → Step 5, Step 7
- Requirement C → Step 1 (prerequisite)

## Steps
1. [Atomic action, 2-5 minutes] — including the actual command/test/file
2. [Atomic action, 2-5 minutes]
3. ...

## Cross-system order-of-operations
[If the plan touches more than one system, the prerequisites in each system, in order.]
- Before Step 5: set SECRET in vault
- Before Step 7: DNS entry for new domain exists
- Before deploy: migration M123 has run

## Descoped (with reasons)
- [Thing not in this plan] — [reason it's out]
- [Another thing not in this plan] — [reason it's out]

## Verification
[How you'll prove the feature works at the end. Commands, expected outputs, environment.]
```

## Anti-patterns

- **"Handle edge cases"** — which edge cases? What do they do?
- **"Add appropriate error handling"** — appropriate to what?
- **"Wire up the integration"** — wire what to what, with which contract?
- **"Similar to the existing X"** — similar how? Copy-paste? Extract and share? New variant?
- **"We can figure that out during implementation"** — if you can't figure it out at plan time, you definitely can't figure it out when you're elbow-deep in broken code.

## Pins

- *If you can't fill in the step right now, you can't implement it right now.*
- *If a step takes longer than five minutes, split it.*
- *Walk every spec section and name the task that implements it.*
- *Every plan has a descoped section. Every descoped item has a reason.*
- *When a task assumes another system is in a particular state, the assumption is part of the spec — and the step that gets the system into that state is part of the plan.*

## See also

- `the-loop.md` — where planning sits in the cycle (after brainstorm, before TDD)
- `verification.md` — the verification section is where the plan cashes in
- `parallel-agents.md` — the file map is the plan for parallel work
