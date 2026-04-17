# Prereqs — Skills These Playbooks Depend On

Five playbooks reference skills that execute the tactical *how*. The playbooks carry the *why, when, and rubric* layer on top.

If any skill here is renamed, retired, or replaced upstream, update this manifest first, then grep the playbooks for the old name. This file is the single point of coupling.

## Dependencies

| Playbook | Depends on skill | Source | Playbook's unique layer |
|---|---|---|---|
| `the-loop.md` | `superpowers:brainstorming` | superpowers plugin | First-conversation discipline, pacing, drift correction, cycle nesting |
| `the-loop.md` | `superpowers:writing-plans` | superpowers plugin | (same — loop step integration) |
| `the-loop.md` | `superpowers:test-driven-development` | superpowers plugin | (same) |
| `the-loop.md` | `superpowers:verification-before-completion` | superpowers plugin | (same) |
| `plan-quality.md` | `superpowers:writing-plans` | superpowers plugin | Rubric for whether a plan is good enough to execute |
| `verification.md` | `superpowers:verification-before-completion` | superpowers plugin | Tests ≠ feature, environment-that-matters, health-check semantics, infra-migration gap |
| `retros.md` | `retrospective` | user-local skill (`~/.claude/skills/retrospective/`) | When to trigger, why skipping compounds, three audiences, five-part anatomy |
| `parallel-agents.md` | `superpowers:dispatching-parallel-agents` | superpowers plugin | File-boundary topology, interface-first, merge-point discipline, wave pattern |
| `parallel-agents.md` | `superpowers:using-git-worktrees` | superpowers plugin | (same) |
| `parallel-agents.md` | `superpowers:subagent-driven-development` | superpowers plugin | (same) |

## Playbooks with no skill dependency

These stand alone — no external skill duplicates their content:

- `mental-models.md`
- `workspace.md`
- `memory-and-skills.md`
- `trust-boundaries.md`
- `failure-modes.md`
- `pipeline-foundation.md`
- `ci-and-release.md`
- `deploy-and-health.md`
- `devops-gotchas.md`

## Installing the superpowers plugin

The superpowers plugin ships skills under the `superpowers:` namespace. On Claude Code it installs into `~/.claude/plugins/`. The plugin also provides `AGENTS.md`, `GEMINI.md`, and `CLAUDE.md` entry files, so the same skills are reachable from Gemini CLI, Copilot CLI, and any agent that honors `AGENTS.md`.

If you run these playbooks *without* the superpowers plugin, the partial-overlap playbooks still read standalone — the Prereq blocks degrade to a note, not a break. The content that lives in the skill (evidence-gate enforcement, brainstorm facilitation, etc.) will simply not be applied.

## Update protocol

When a superpowers skill is renamed:

1. Edit this file — change the skill name in the table.
2. `grep -rn <old-name> docs/agent-playbooks/` — find every Prereq block and inline reference.
3. Update references.
4. Commit with a message that names the upstream version bump.
