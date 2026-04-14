# Trust Boundaries

> Verification tells you the work is correct. Trust boundaries tell you whether you had the authority to do the work at all. Get the technical layer right and the political one wrong and you ship a verified force-push to main.

## Rules

### Match the action to its blast radius. Confirm before crossing the line
**Why:** A local file edit is reversible. A force-push is not. Treat both the same and you'll eventually force-push something that should have been a file edit. I don't intuit blast radius — I see both as "a tool call I'm allowed to make." That intuition is the engineer's job.
**How to apply:** Local and reversible — let me run. Shared state, hard to reverse, visible to other people — confirm first. The test is recovery time: if this is wrong, how long to undo it? Seconds, fine. Hours of someone else's work, ask first.

### Authorization is scoped, not blanket
**Why:** "Yes, push" once does not mean "yes, push" forever. When you approve a destructive action, you are approving *that specific action*, not handing me a permission slip for the next one.
**How to apply:** Every risky action is its own decision unless durable instructions — CLAUDE.md, `settings.json` permissions, an explicit skill — say otherwise. If in doubt, ask. The cost of asking is one round-trip. The cost of not asking is a retro chapter.

### When the agent hits an obstacle, it must investigate, not delete
**Why:** Unexpected files, branches, lock files, and orphaned containers usually represent in-progress work — from a teammate, from an earlier you, from a process that hasn't finished. Deleting them to make the error go away is how you lose a day of work nobody can reconstruct.
**How to apply:** Investigate root causes. `git reset --hard`, `rm -rf`, `--no-verify`, `git clean -fd`, "let me just drop the database" — last resorts, not first resorts. If I can't tell you *why* deleting the thing is safe, it isn't.

## Blast radius reference

Classify every action before taking it. Match to recovery time.

| Blast radius | Examples | Recovery | Default posture |
|---|---|---|---|
| **Trivial** | File edit in working tree, local test run, read-only shell command | `git checkout` / re-run | Take the action; show what was done |
| **Small** | Local commit, new branch, new file, local DB reset | `git reset`, delete branch, restore from backup | Take the action; confirm on destructive |
| **Medium** | Push to a feature branch, merge to develop, CI run | Revert commit + re-push, re-run CI | Confirm if unclear |
| **Large** | Merge to main, deploy to staging, issue/PR creation, external API call | Manual rollback, PR revert, conversation with affected humans | **Confirm first** |
| **Irreversible** | Deploy to prod, `git push --force`, `DROP TABLE`, delete branch on remote, `rm -rf` on shared state, publishing a release | Prayer + backups | **Confirm with explicit phrasing** — say what's about to happen and wait for yes |

## The "default direction" rule

The unsafe default is the one that gets used by everyone who didn't think about it. Make the safe option the default; require explicit opt-in for elevation. A function signature with `client: 'admin' | 'anon' = 'admin'` will ship admin-privileged code by everyone who didn't read the docs — including me.

## Destructive-action checklist

Before running any command from the "Large" or "Irreversible" row:

1. **State what's about to happen** in plain language, not just the command.
2. **Name what becomes unrecoverable** if it goes wrong.
3. **Wait for explicit yes.** "Continue?" is not a rhetorical question.
4. **Show the output of the destructive step before taking the next one.**

## Pins

- *Blast radius is set by recovery time, not by command length.*
- *Every yes is for one action. The next risky action is its own conversation.*
- *If I can't show you where I looked, I didn't look.*
- *The unsafe default is the one that gets used by everyone who didn't think about it.*

## See also

- `failure-modes.md` — "agent hit an obstacle and deleted the thing" as a named failure mode
- `workspace.md` — `settings.json` is where "can't" becomes enforceable
- `verification.md` — verify destructive actions succeeded before moving on
