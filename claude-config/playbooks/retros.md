# The Retro Habit

**Prereq skill:** `retrospective` covers the voice and narrative style for retros. This playbook adds the *discipline*: when to trigger (cycle close or surprise), why skipping compounds, three audiences, and the five-part anatomy. See `prereqs.md`.

> **Second load-bearing chapter.** Paired with `verification.md`. Verification catches the failure; retros convert it into a rule. Skip verification and the failure ships. Skip the retro and the failure re-ships, forever.

## Rules

### Write retros in voice, not in bullet points
**Why:** A dry changelog is forgotten in a week. A story is remembered in a year. The retrospective's job is to be *rediscoverable* — and humans rediscover stories, not checklists. If a retro reads like a status report, it gets treated like one: filed, ignored, auto-archived.
**How to apply:** Write like a person. If you spent three deploys fixing a bug that turned out not to exist, say it that way. Nickname the bugs. Describe what it felt like. Admit what surprised you. Titles earn their clicks: *"The One Where We Solved The Wrong Bug For Three Rounds"* is something someone will click in two years; *"Release 5.11 CI/CD Cleanup Summary"* is not.

### Retros are how the loop learns
**Why:** Without a retro, every cycle re-discovers the same mistakes. The lesson in retro N becomes the rule in loop N+1 — but only if retro N gets written. Skipped retros compound.
**How to apply:** A retro is mandatory at the end of every release, even small ones. It doesn't have to be long. It has to be honest. An honest paragraph beats a dishonest page — and a missing retro is the most dishonest thing you can write, because its absence implies nothing went wrong, and something always went wrong.

### Write a retro at the end of every themed cycle, and right after every surprise
**Why:** "End of every release" is a useful default only when your work has releases. When it doesn't — or when "release" is blurry — the default collapses and retros get skipped for the wrong reasons. The rule that works across contexts: cycle close *or* surprise.
**How to apply:** Retro at three triggers.
- **At the end of any themed cycle with a shippable boundary.** Task-level, release-level, and project-level cycles each deserve a retro at their own scale. A task-level retro can be three sentences and a lesson.
- **At the end of any unit of work that took more than a day**, even if nobody calls it a release.
- **Immediately after any surprise** — a major incident, a near-miss, a debugging session that went sideways, a deploy that rolled back, a test that failed in a way that made you say "huh." Catch it while the context is hot.

Do **not** write retros on calendar intervals divorced from the work ("weekly retros regardless of whether anything happened"). A retro with nothing to say is worse than no retro — it teaches the team that retros are performance, not learning.

### A retro has an anatomy. Use it as a scaffold, not a template
**Why:** "Write in voice, name what broke, end with one extractable sentence" is a *posture*, not a *structure*. A reader who hasn't seen a good retro has nothing to start from. The scaffold is what lets the voice happen: when structure is handled, attention goes to the prose.
**How to apply:** Five parts, scaled to what the cycle actually produced.

1. **The mission.** One paragraph on what you were trying to do, why it mattered, and what "done" was going to look like.
2. **What happened — the execution narrative.** The story of the cycle. Nicknamed bugs. Surprises. Near-misses. Written in voice, not bullet points.
3. **The numbers.** Dry metrics for people who came for them: counts, times, sizes, test results, lines added/removed.
4. **What we learned — the extractable lessons.** One sentence per lesson, lesson first, context second. This is what future-you and I will Ctrl-F for.
5. **What's next.** The handoff to the next cycle. One line is enough; the point is to make the lesson actionable on the very next cycle.

Not every retro needs all five. A one-day hotfix might be three sentences and a lesson. A release retro wants all five.

### A retro has three audiences: you next month, your team, and the agent next time
**Why:** All three need different things — future-you needs the full story, teammates need the context they missed, the agent needs a clean extractable lesson. All three can get what they need from the same document if you include the lesson explicitly, not just as something implied by the narrative.
**How to apply:** Every retro ends with "what we'd do differently" — a sentence, not a section. That sentence is what I extract. That's what you'll Ctrl-F for next month. It doesn't have to be long, it has to be explicit. The story is for humans; the explicit lesson is for everyone, including the agent that hasn't read the story.

## Retro template

```md
# Retro — [Cycle name / release version] — [nickname]

## Mission
[1 paragraph: what we set out to do, why, what "done" was going to look like.]

## What happened
[The execution narrative, in voice. Nicknamed bugs. Surprises. The parts harder than expected.]

## The numbers
- [Count, time, size, tests, …]

## What we learned
- **[Lesson 1, imperative first]** — [one-sentence context]
- **[Lesson 2]** — [one-sentence context]

## What's next
[One line pointing to the next cycle's opening move.]
```

## Pins

- *"The One Where We Solved The Wrong Bug For Three Rounds" is a title someone will click in two years. "Release 5.11 CI/CD Cleanup Summary" is not.*
- *Skipped retros compound.*
- *The retro is the latch between cycles. No retro, no latch, no cumulative learning.*
- *The anatomy is the scaffold that frees the voice.*
- *Every retro ends with one sentence the agent can extract.*

## See also

- `verification.md` — paired chapter
- `the-loop.md` — the retro is the last step of the loop
- `memory-and-skills.md` — the extracted lesson is what gets promoted into memory or a skill
