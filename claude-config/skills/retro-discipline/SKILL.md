---
name: retro-discipline
description: Use when deciding whether to write a retro, after a release, or right after a surprise (incident, near-miss, "huh" moment, sideways debugging session). Covers WHEN to write a retro, WHY skipping compounds, and the five-part anatomy. Pairs with the `retrospective` skill — discipline here, voice there.
---

# Retro Discipline

Load `~/.claude/playbooks/retros.md` for the full reasoning. Apply these rules.

## When to write a retro

Three triggers — any one is enough:

1. **Cycle close with a shippable boundary** — task-level (3 sentences + a lesson is fine), release-level, or project-level.
2. **Any unit of work that took more than a day**, even if no one calls it a release.
3. **Immediately after a surprise** — incident, near-miss, rolled-back deploy, test that failed in a way that made you say "huh," a debugging session that went sideways. Catch it while the context is hot.

Do **not** write retros on calendar intervals divorced from the work. A weekly retro with nothing to say teaches the team that retros are performance, not learning.

## Why this matters

Skipped retros compound. Every cycle that ships without a retro re-discovers the same mistake on the next cycle. The retro is the latch between cycles.

## Five-part anatomy

Use as a scaffold, not a template. Scale to what the cycle actually produced.

1. **Mission** — what you were trying to do, why, what "done" looked like.
2. **What happened** — execution narrative, in voice. Nicknamed bugs. Surprises. Use the `retrospective` skill for style.
3. **The numbers** — counts, times, sizes, test results.
4. **What we learned** — one sentence per lesson, imperative first, context second. This is what future-you Ctrl-Fs for.
5. **What's next** — one line pointing to the next cycle's opening move.

## The extractable lesson rule

Every retro ends with one explicit sentence — "what we'd do differently." Not implied by the narrative. Stated. That sentence is what the agent extracts and what future-you searches for.

## Complementary skill

`retrospective` handles the *voice* once you've decided to write one. This skill handles the *decision*.
