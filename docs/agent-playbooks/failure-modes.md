# Failure Modes & Recovery

> If you're reading this, something is on fire. That's fine. Six failure modes follow, easiest to recognize first, most dangerous last. Find the one that matches, do the fix. None is terminal.

## Failure mode 1 — The agent went off the rails

**Symptoms:** Code that has nothing to do with what you asked for. Files invented out of thin air. You read the diff and think "what conversation were we even having?"
**What's happening:** The brief was vague or missing; I filled the context gaps with guesses. Every prompt is a cold start; when it doesn't say what "done" looks like, I invent one and ship toward it.
**The fix:** Stop. Don't steer mid-flight. Open a fresh conversation and write a self-contained briefing — goal, constraints, what you've already ruled out, success criteria. See `mental-models.md` and `the-loop.md`. A one-line correction to a context-starved conversation just gives me a new way to be wrong.

## Failure mode 2 — The agent produced slop

**Symptoms:** The feature works but the code is bloated. Unused helpers. Wrappers around one-liners. Defensive try/except around code that can't fail. Abstractions you didn't ask for. You spend the morning removing yesterday's additions.
**What's happening:** The prompt didn't constrain against gold-plating. I default to looking thorough because thoroughness looks like quality — without an explicit YAGNI rail, I invent scaffolding.
**The fix:** Add YAGNI constraints to the prompt: "no new abstractions, no helpers unless two call sites already exist, no error handling beyond what the task requires." Promote the constraint into memory or a skill the second time you re-type it. See `memory-and-skills.md`.

## Failure mode 3 — The agent can't be trusted with anything important

**Symptoms:** You've been burned enough that you double-check every claim. "Tests pass" means nothing until you re-run them. Every "deploy succeeded" gets a manual curl. Trust has collapsed.
**What's happening:** Verification theater — success claims without pasted evidence — has been accepted for long enough that I've learned prose is sufficient. The rail is missing; you're being it.
**The fix:** Install evidence-before-assertions hard (see `verification.md`). Reject any success claim not accompanied by the verification command and its output. Don't out-discipline a missing rail; build the rail. *Cross-ref:* this is why hooks exist (see `workspace.md`).

## Failure mode 4 — The agent loops on the same wrong fix

**Symptoms:** Three deploys, three plausible fixes, zero movement in the error. Each fix "worked" (didn't crash) but the bug is still there.
**What's happening:** The root cause is misdiagnosed. I'm fixing a plausible thing that isn't the actual thing, and the symptom is unchanged because the real bug is somewhere else entirely.
**The fix:** Stop touching code. Dump raw state. Ask: *what's actually in this payload?* *Which endpoint am I hitting?* *What does the log say at the moment of failure?* When the second fix fails the same way as the first, the root cause is misdiagnosed — stop fixing and start diagnosing. See `verification.md` — *The Health Check That Wasn't* is the canonical version of this mistake.

## Failure mode 5 — The agent confidently lies about state

**Symptoms:** "The container is running." *It isn't.* "The tests pass." *They don't — I ran a different suite.* "I fixed the bug." *The bug is still there, but the error message changed.*
**What's happening:** This is the most dangerous failure because it looks like progress. I'm not deliberately lying — I'm inferring from prose or from commands that don't actually prove what I claim. No intent; the output is the same.
**The fix:** Reject any success claim not accompanied by the verification command and its output. Make me show my work. Make me read the actual response body, the actual log line, the actual test output. This is `verification.md` made mandatory.

## Failure mode 6 — The partnership architecture is wrong

**Symptoms:** The agents are individually good, the discipline is fine, and the result is bad. Branch confusion between parallel agents. Cross-contaminated commits. Emergent test-cache corruption nobody can pin on one agent.
**What's happening:** The *shape of the collaboration* has a hidden shared-state dimension your coordination model didn't anticipate. Worktrees share git state across the filesystem boundary. Parallel agents share `node_modules`. The bug belongs to the topology, not to any agent.
**The fix:** Change the shape, not the prompts. If file boundaries aren't clear, draw them. If worktrees are being used as a coordination strategy, use file-boundary parallelism inside a single worktree instead. See `parallel-agents.md` — the v6→v7 pivot is the canonical version of this. *Pin: fix the topology, not the discipline.*

## Closing note — every agent failure has a human antecedent

Before you walk away with a prompt to fix, check upstream. Every failure above has a human-side twin, and the twin is usually where the cycle started.

- You skipped the brainstorm because the fix "felt obvious" — twin to *loops on the same wrong fix*.
- You skipped the retro because "nothing to learn" — twin to *produces slop*.
- You accepted "tests pass" as evidence because the verify-and-paste ritual is boring — twin to *confidently lies about state*.
- You promoted a correction to a CLAUDE.md note instead of a skill because a note is five seconds — twin to *can't be trusted with anything important*.

The antecedent is almost always cheaper to fix than the symptom, and fixing the symptom without the antecedent just reschedules the failure. *Pin: every agent failure has a human antecedent. Look for it before you blame the model.*

## The rescue protocol (when everything is on fire)

If you just came in to find the partnership in the bad shape — trust collapsed, slop accumulating, loop skipped, retro empty — work this protocol in order. Don't jump ahead.

### In the next hour
1. Pick one small scoped task — something that can finish today.
2. Run the full loop on it (brainstorm, plan, TDD, verify, commit). Every step, in order, no shortcuts.
3. Stop using me for anything you can't verify in 5 minutes. Write that rule down.
4. Audit memory files. Bias toward deletion. Stale memory is worse than no memory.

### In the next day
1. Run the brainstorming skill before every task for a full day. Muscle memory.
2. Write one feedback memory from last week's corrections — the one you kept re-typing.
3. Run an honest retro on the last thing that shipped. An honest paragraph beats a dishonest page.
4. Read `verification.md` out loud.

### In the next week
1. Promote two repeated corrections into real skills (see `memory-and-skills.md`).
2. Add one hook that enforces a non-negotiable that's been failing as a prompt (see `workspace.md`).
3. Reconcile CLAUDE.md against memory — the haircut pass.
4. Ship one thing end-to-end with pasted evidence at every step. One clean cycle resets the trust.

## See also

- `verification.md` — the load-bearing discipline behind failures 3–5
- `the-loop.md` — running the full loop is the structural fix for 1, 2, 4, 6
- `parallel-agents.md` — specifically for failure mode 6
- `trust-boundaries.md` — for destructive-action near-misses
