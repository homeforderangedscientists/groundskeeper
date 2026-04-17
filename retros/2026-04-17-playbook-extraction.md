# 2026-04-17 Retrospective — The One Where the "Redundant" Playbooks Weren't

## Or: How We Discovered That a Rubric Is Not a Tactic

It started with a simple-sounding question: *how do we take the agent-playbooks living in `docs/` and make them available across every project that uses Claude heavily?* We had fourteen rule-first playbooks sitting in a doc folder, quietly doing their job whenever someone remembered to load them. We wanted them installed, discoverable, and — the actual interesting part — we wanted to know which of them were already redundant with the `superpowers` plugin so we could stop duplicating work.

The honest answer took three acts, a research agent, a 404, and one quiet mystery involving a skill that briefly went missing.

## Act 1 — The Confident Hand-Wave

We started by blithely declaring that six playbooks overlapped with existing `superpowers` skills: `verification.md` ↔ `verification-before-completion`, `plan-quality.md` ↔ `writing-plans`, `the-loop.md` ↔ brainstorm+TDD+verify, `parallel-agents.md` ↔ `dispatching-parallel-agents`, `retros.md` ↔ the `retrospective` skill, `trust-boundaries.md` ↔ the system prompt. Six down, nine to go. It all fit in a tidy table.

Seth's response was, roughly, *is that completely true?*

(It was not completely true. It was not *any* true, really. We had named skills we had never read and declared them equivalent to playbooks we had only half-skimmed. The table was performative.)

## Act 2 — The Research Agent, or: Reading Both Sides Before Declaring Them Equal

So we dispatched an Explore agent to actually read every playbook and every arguably-overlapping `superpowers` skill, head-to-head, and report whether the overlap was real or confabulated. The verdict came back clear: **zero playbooks were fully redundant**. Five had partial overlap — but in those five, the `superpowers` skills were the *tactic* and the playbooks were the *rubric, reasoning, and topology* on top. Different kinds of objects entirely. Nine were fully unique — no tactical content in the skill ecosystem to outsource.

The distinction that finally landed: **`superpowers:writing-plans` tells you how to write a plan. `plan-quality.md` tells you whether the plan you wrote is good enough to execute.** Those are not competing artifacts. They are different questions on different days.

We retracted the hand-wave in writing. (Which is, it turns out, the correct move when the hand-wave got that much wrong.)

## Act 3 — The Layering, the Manifest, the Prereq

Armed with the real verdict, we restructured. The five partial-overlap playbooks got `**Prereq skill:**` headers pointing at the `superpowers` skills they depend on. `verification.md` lost its "evidence before assertions" rule body — that's literally the gate `superpowers:verification-before-completion` enforces — compressed to a one-paragraph pointer. A new `prereqs.md` manifest at the top of the playbook set became the single point of coupling: if a skill gets renamed upstream, one file updates and a quick grep fixes the rest.

Net change across seven files: **+66 insertions, -6 deletions**. The smallest refactor of the day, and probably the most important one.

## The Install Script, Or: The Homebrew Ritual Goes Private

Then the ambitious move: make the whole system curlable. We wrote `install.sh` in the idiom of the Homebrew one-liner — `/bin/bash -c "$(curl -fsSL <URL>)"` — with the three safety properties that matter: **additive** (never overwrites), **idempotent** (second run is a no-op), **detectable local checkout** (so testing doesn't have to round-trip through GitHub).

We scaffolded `claude-config/`: ten skill wrappers (nine new, plus a copy of Seth's beloved `retrospective` skill promoted into the repo), a `CLAUDE.md.fragment` that goes into a marker-delimited block, and a README that explains the whole thing without claiming more safety than the tests actually proved.

We ran it against a scratch directory. 16 playbooks installed. 10 skills installed. CLAUDE.md block appended cleanly. (We tested idempotency. We tested preserving a pre-existing custom `retrospective` skill. Both clean.) We declared victory.

We had not tested the curl path.

## The 404, Or: The Pipeline Works But Nobody Can Reach It

```
$ curl -fsSL https://raw.githubusercontent.com/homeforderangedscientists/groundskeeper/main/install.sh
curl: (56) The requested URL returned error: 404
```

The repo was private. The installer worked perfectly. The install script was beautiful. *Nobody unauthenticated could fetch it.*

This is the part where the verification playbook quietly vindicates itself. "Verify in the environment that matters" — and the environment that matters for a homebrew-style install is the *unauthenticated internet*. We had verified locally. The local path was pristine. The globally-reachable path was a 404.

Seth flipped the repo public. Second test: 200 OK. Then full end-to-end against a freshly cloned scratch: 16 playbooks, 10 skills, marker block, all in place. (*This* is the point where victory was appropriate.)

## The Missing Retrospective, Or: The Mystery With the Boring Answer

At some point — between `cp -r`-ing the retrospective skill into the repo and Seth's real install — the `retrospective` skill disappeared from `~/.claude/skills/`. Seth noticed. We scrambled. The `~/t/.claude` scratch copy also didn't have it. A stray `find` turned up nothing. The repo copy at `claude-config/skills/retrospective/` was safe, byte-identical to what we'd copied in at 13:37. Two backups of `.claude.json` existed in `~/.claude/backups/`, neither relevant.

We don't know what happened to the original. We know it was there at 11:15 and gone by 14:05. We know nothing in this session removed it on purpose, and nothing in the install script touches ~/.claude/skills in delete-mode. (The install is additive. The install is *only* additive.)

The boring answer: the installer put it back. The repo copy was fresh enough that the replacement is effectively a restore. Rest in the timestamp gap.

## By the Numbers

- **14** playbooks audited head-to-head against `superpowers` skills
- **0** fully redundant
- **5** partial-overlap (now layered on `superpowers` with Prereq headers)
- **9** fully unique (untouched)
- **10** skills in the install payload (9 new wrappers + `retrospective`)
- **16** files in `~/.claude/playbooks/` after install
- **185** lines of Seth's CLAUDE.md untouched
- **26** lines appended, all inside marker delimiters
- **7** commits to `main`
- **818** insertions in the installer commit
- **1** push blocked by main-branch protection (correctly)
- **1** curl 404 caught before anyone else hit it
- **1** retraction of a claim made without reading the sources
- **2** scratch install tests before touching real `~/.claude`
- **1** skill that briefly vanished and was quietly restored

## What we learned

- **Don't declare redundancy without reading both sides.** A table that assigns equivalence between named artifacts is a claim, not a summary. If the agent hasn't read both the skill and the playbook, the table is confabulation. Next time: read or delegate to a reader before drawing the table.
- **Additive installers need to be tested in the environment the user will actually use.** Local scratch installs prove the file operations. They don't prove the fetch layer. When the install is `curl | bash`, the `curl` step is part of the test.
- **The `Prereq:` pattern is the architecture.** Playbooks that carry only their unique layer (rubric, topology, reasoning) are shorter, clearer, and don't rot when the underlying skill evolves. The `prereqs.md` manifest is the single point of coupling that makes skill renames tractable.
- **Every "is this still here?" moment is a verification-before-completion test in disguise.** We don't know where the original `retrospective` skill went. But we had a repo copy. The repo copy existed because we'd treated the promotion-into-repo as a cycle-close move and committed it. A silent backup, retrospectively.

## What's next

Try the new skills on real tasks and see which ones fire at the right moment and which ones need sharper `description:` triggers. Write a retro about which skills need tuning. (Which is the only honest way to close a loop that begins with "we installed ten skills whose descriptions we've never stress-tested.")

The lesson the next loop should extract, in one sentence: **when you're about to call two things "the same," check first by reading both — the retraction is always more expensive than the extra five minutes.**

Rest in handwave.
