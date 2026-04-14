# Parallel Agents & Worktrees

> Dispatching multiple agents is a force multiplier — and a coordination minefield. The rules that hold across projects are about *architecture*, not discipline. You can't out-discipline a bad topology.

## Rules

### Fan out only when tasks are independent
**Why:** Parallel agents on dependent tasks produce merge conflicts, races, and subtle interleavings you'll spend longer debugging than the parallelism ever saved you. Two agents that both need to edit `services/timer_service.py` will produce a conflict. Two agents that need each other's types but don't wait for them will ship two incompatible halves of a feature.
**How to apply:** Group by **file overlap**, not by issue priority. Two high-priority issues that both touch the same test file are not a parallel pair — they are a serialization point. If task B needs task A's output, they are sequential *even if the files don't overlap*. "B uses the interface A defines" is a handoff.

### Interface-first design is the strongest coordination protocol
**Why:** When every agent can only produce code that conforms to a narrow contract, conflicts become impossible by construction — not by discipline, not by review, not by merge ceremony, but because the interface refuses to permit them.
**How to apply:** Before fan-out, design the interface. Make it explicit, make it narrow, make it the only shape the parallel work can produce. Agents can then build in total isolation and merge without conflict because the only thing each implementation can *do* is satisfy that interface.

### Designate merge points explicitly; update them last
**Why:** The hardest part of parallel agent work isn't the parallel code — it's the few shared files every agent has to touch: the config registry, the main entrypoint, the integration test, the dependency manifest. If every agent edits those in parallel, you get conflicts by construction.
**How to apply:** Two-phase plan. **Phase 1:** parallel work that touches *only* each agent's own files. **Phase 2:** a single-threaded pass that updates each merge-point file with every agent's integration. The file map becomes a contract with two columns: *owned by an agent* and *merge point*. No file can be in both. Phase 1 is fan-out; phase 2 is the merge-point pass. Mixing them is where conflicts come from.

### Worktrees are workspaces, not stashes — and they are not a coordination strategy
**Why:** Worktrees rot when they outlive their task. Worse, they look like they isolate parallel agents but the git state underneath them is *shared* — they isolate the filesystem, not branches, refs, HEAD, or merge state. Five agents in five worktrees on five feature branches are all operating against the same underlying git database, and without an explicit coordination layer they will step on each other's branches, cross-contaminate commits, and produce orphaned refs.
**How to apply:** Every worktree should have a definite end (merged, deleted, or explicitly reopened) within days. If you can't name what it's for, close it. **For parallel-agent work specifically:** use file-boundary parallelism inside a single worktree, with a team or dispatch layer that assigns non-overlapping files to each agent. Don't reach for worktree-per-agent as the isolation mechanism.

### Subagents protect your context window; they don't hide work from you
**Why:** The point of a subagent is to do a large-process task and return a small output — a decision, a summary, a short report. A subagent that writes 5,000 lines you don't read is a liability: you've outsourced the work and the accountability at the same time.
**How to apply:** Dispatch when the *output* you need is small but the *process* is large. Research, analysis, searching, reading — good subagent work. If the subagent's job is to write code, you still have to read the code. Context-window savings don't transfer to accountability. *Qualifier:* at high parallelism (4+ agents), "reading" can be mechanized into automated gates *when the domain supports it* — CI running build+test+vet+race, integration tests covering every adapter, coverage-matrix tests pinning feature coverage. This depends entirely on the pipeline being boring (see `pipeline-foundation.md`). When gates are trustworthy, dispatch broadly and audit narrowly. When they aren't, parallel agent work outruns supervision and the whole pattern collapses.

## The wave pattern (for fan-outs over many similar items)

When parallelizing N agents across M similar tasks, do them in waves:

1. **Trivial first** — the items that are fifty lines of stdlib and fit in a single read.
2. **Moderate next** — the ones with state machines, security, or non-trivial I/O.
3. **Complex last** — the ones with multi-phase protocols, hand-rolled state machines, or novel infrastructure.

The trivial wave validates that the build system, config registration, and test harness are all working before you commit agents to 150-line state machines. When you parallelize work, schedule the cheapest items first as a load test for the harness. The expensive work runs on a harness you've already debugged.

## The fan-out checklist

Before dispatching more than one agent:

1. **File map first.** Every file an agent will touch, assigned to exactly one writer. No file in two columns.
2. **Merge points listed separately.** Config, main, integration tests, dependency manifests — in the merge-point column, owned by nobody during phase 1.
3. **Interface frozen.** If agents produce implementations of a shared contract, the contract is written before fan-out and does not change during phase 1.
4. **Wave order set.** Trivial → moderate → complex, explicitly.
5. **Re-entry plan.** If an agent reports back with "I couldn't do X," who picks that up? (Usually: back to the human, not redispatched.)
6. **Gate list.** Which automated gates are running on the merged result? If the answer is "none," reduce fan-out until the human can read everything.

## Pins

- *Group by file overlap, not by issue priority.*
- *Parallel work is a two-phase plan. Phase 1 is the fan-out; phase 2 is the merge-point pass.*
- *Isolate context with worktrees; isolate work with file boundaries.*
- *Dispatch to compress process, not to avoid reading the result.*
- *The interface you design before the parallel work begins is the coordination protocol the parallel work runs on.*

## See also

- `failure-modes.md` — failure mode 6 (partnership architecture wrong)
- `plan-quality.md` — the file map is part of the plan
- `the-loop.md` — nested cycles around parallel releases
