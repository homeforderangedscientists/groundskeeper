---
name: parallel-agents-topology
description: Use before dispatching 2+ agents in parallel — topology decisions that make parallel work survivable. File-boundary ownership, interface-first design, merge-point discipline, wave pattern. Complements `superpowers:dispatching-parallel-agents` (which handles dispatch mechanics) with architecture that prevents coordination failures.
---

# Parallel Agents Topology

Load `~/.claude/playbooks/parallel-agents.md` for the full playbook.

`superpowers:dispatching-parallel-agents` is the dispatch mechanic. This skill is the topology decision — **you can't out-discipline a bad topology**.

## Before fan-out

1. **Group by file overlap, not issue priority.** Two high-priority issues that both touch the same test file are not a parallel pair — they are a serialization point. If task B needs task A's output, they are sequential *even if the files don't overlap*.

2. **Design the interface first.** When every agent can only produce code that conforms to a narrow contract, conflicts become impossible by construction — not by discipline, not by review, but because the interface refuses to permit them.

3. **Designate merge points explicitly and update them last.** The shared touchpoints every agent would otherwise edit (config, main, integration tests, dependency manifests) become a dedicated phase-2 pass by a single agent.

4. **Two-phase plan.**
   - **Phase 1:** parallel work touching only each agent's own files.
   - **Phase 2:** single-threaded pass that integrates every agent's output into the merge-point files.
   
   The file map becomes a contract with two columns: *owned by agent X* and *merge point*. No file in both columns.

5. **Worktrees isolate filesystems, not git state.** Five agents in five worktrees on five branches share the underlying git database. Without an explicit coordination layer they step on each other's branches. **For parallel-agent work, use file-boundary parallelism inside a single worktree**, not worktree-per-agent.

## The wave pattern

When parallelizing N agents across M similar tasks:

1. **Trivial first** — fifty lines of stdlib, fits in a single read.
2. **Moderate next** — state machines, security, non-trivial I/O.
3. **Complex last** — multi-phase protocols, novel infrastructure.

The trivial wave is a load-test for the build system, config registration, and test harness. The expensive work runs on a harness you've already debugged.

## Subagent accountability

A subagent that writes 5,000 lines you don't read is a liability — you outsourced the work and the accountability at the same time. Dispatch when the output is small but the process is large. *Qualifier:* at high parallelism (4+ agents), "reading" can be mechanized into automated gates *when the domain supports it* — CI running build+test+vet+race, integration tests covering every adapter, coverage-matrix tests. That depends on the pipeline being boring. When gates are trustworthy, dispatch broadly and audit narrowly. When they aren't, parallel agent work outruns supervision and the whole pattern collapses.

## Fan-out checklist

1. File map first — every file assigned to exactly one writer.
2. Merge points listed separately — owned by nobody during phase 1.
3. Interface frozen — written before fan-out, immutable during phase 1.
4. Wave order set — trivial → moderate → complex.
5. Re-entry plan — if an agent reports "I couldn't do X," who picks that up?
6. Gate list — which automated gates run on the merged result? If "none," reduce fan-out until a human can read everything.
