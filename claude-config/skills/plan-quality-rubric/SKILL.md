---
name: plan-quality-rubric
description: Use after writing a plan and before starting implementation — checks whether the plan is actually executable. Catches placeholders, oversized steps, spec-coverage gaps, and missing descope. Complements `superpowers:writing-plans` (which produces the plan) with a quality gate (which validates it).
---

# Plan Quality Rubric

Load `~/.claude/playbooks/plan-quality.md` for the full rubric and template. Apply these checks to the current plan before execution.

## The five checks

1. **No placeholders.** Every step contains actual content. No "TBD," no "similar to above," no "implement later," no "add appropriate error handling." A plan you can nod along to but couldn't execute yourself isn't specific enough.

2. **Each step is one action, 2–5 minutes long.** If a step would take longer, split it. *Qualifier:* when architecture hands you small blame radius for free (one-feature-per-directory, tight interface contract, self-contained package), a larger step can still satisfy the rule. Check the proxy against the goal.

3. **The plan covers the spec.** Walk every spec section and point at the task that implements it. A section with no task is not a gap in the plan — it's a gap in the feature.

4. **Cross-system order-of-operations is explicit.** For every task that depends on another system being in a particular state (secret in vault, DNS record, migration, dependency in manifest), add the prerequisite as its own earlier task.

5. **Descope is explicit with reasons.** Every plan has a "Descoped" section listing items considered and rejected, each with a named reason. A descope with a reason is a negotiable contract; a silent omission is scope-creep waiting to happen.

## What to do when a check fails

Surface the specific gap to the user before proceeding to execution. Don't fix it silently — the gap is information about scope, not a cleanup task.

## Anti-patterns to flag

- "Handle edge cases" → which ones, doing what?
- "Add appropriate error handling" → appropriate to what?
- "Wire up the integration" → wire what to what, with which contract?
- "Similar to the existing X" → similar how? Copy-paste, extract, or new variant?
- "We can figure that out during implementation" → if you can't figure it out at plan time, you can't figure it out with broken code in your lap.
