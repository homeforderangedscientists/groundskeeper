# Agent Playbooks — Index

Rule-first extracts from the engineer-agent and DevOps playbooks, sized for agent context windows. Load the topic you need, not the whole book. Each playbook is 30–80 lines of imperatives with a `Why` and `How to apply`; no narrative, no field notes.

**If you are an agent:** read this index, pick the playbooks that apply to your task, and load them. Cross-references between playbooks are fine — follow them when the task straddles topics.

**Skill dependencies:** Five playbooks (`the-loop`, `plan-quality`, `verification`, `retros`, `parallel-agents`) assume the `superpowers` plugin is installed. See `prereqs.md` for the full manifest and update protocol. The other nine playbooks stand alone.

## Engineer + agent (how to work with me)

- [mental-models.md](mental-models.md) — How to think about me: cold-start briefing, delegate the task not the understanding, where my judgment is strong vs weak.
- [workspace.md](workspace.md) — CLAUDE.md vs memory vs skills vs hooks vs settings.json: which layer each kind of knowledge belongs in.
- [the-loop.md](the-loop.md) — First conversation + the core loop: brainstorm → plan → TDD → verify → commit → retro. Nested cycles.
- [memory-and-skills.md](memory-and-skills.md) — Memory hygiene (four types, stale-is-worse-than-none) and when to promote a correction into a skill.
- [verification.md](verification.md) — Load-bearing. "Tests pass" ≠ "feature works." Evidence before assertions. Verify in the environment that matters.
- [trust-boundaries.md](trust-boundaries.md) — Blast radius, scoped authorization, investigate-not-delete.
- [failure-modes.md](failure-modes.md) — Six failure shapes (plus the human-antecedent closing note) + the rescue protocol when the partnership is broken.
- [parallel-agents.md](parallel-agents.md) — Fan-out rules, worktrees, merge points, subagent accountability.
- [plan-quality.md](plan-quality.md) — No placeholders, 5-minute steps, cover the spec, descope explicitly.
- [retros.md](retros.md) — Second load-bearing chapter, paired with verification. Write them in voice, at cycle close and after surprises, with an extractable lesson.

## DevOps (making the pipeline boring)

- [pipeline-foundation.md](pipeline-foundation.md) — Git-flow, conventional commits, `.gitignore`/`.dockerignore`, VERSION file, multi-stage Dockerfiles, compose parity.
- [ci-and-release.md](ci-and-release.md) — CI skeleton, test/lint/scan gates, actionlint, Docker build validation, release-please.
- [deploy-and-health.md](deploy-and-health.md) — Blue-green deploy, preflight, health endpoints (the `/health` vs `/api/v1/health` split), deploy manifest, smoke tests.
- [devops-gotchas.md](devops-gotchas.md) — Cross-cutting traps: bash script buffering, GitHub Actions token scope, Slack mrkdwn ≠ Markdown, docker port mappings, build-arg plumbing.

## When multiple playbooks apply

Task-to-playbook map for common situations:

| Task | Load these |
|---|---|
| Implementing a feature | `the-loop.md`, `plan-quality.md`, `verification.md` |
| Debugging an unexpected bug | `verification.md`, `failure-modes.md` |
| Running parallel agents | `parallel-agents.md`, `plan-quality.md` |
| Writing a retro | `retros.md` |
| Something destructive (delete, force-push, drop) | `trust-boundaries.md`, `failure-modes.md` |
| Setting up a new project | `pipeline-foundation.md`, `workspace.md`, `ci-and-release.md` |
| Deploying | `deploy-and-health.md`, `devops-gotchas.md`, `verification.md` |
| Fixing CI | `ci-and-release.md`, `devops-gotchas.md` |
| Correcting drift mid-session | `the-loop.md`, `memory-and-skills.md` |

## Conflict resolution

If a playbook conflicts with the project's `CLAUDE.md`, a skill the user invoked, or a direct user instruction — **the user wins, always.** These playbooks are defaults, not overrides.
