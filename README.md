# Groundskeeper

The engineer + agent playbook for Claude Code — a field manual for partnering an engineer with a coding agent, distilled into rule-first playbooks and installable task-triggered skills.

## Install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/homeforderangedscientists/groundskeeper/main/install.sh)"
```

The installer is **additive**: it never overwrites existing playbooks, skills, or CLAUDE.md content. Run it twice and the second run is a no-op except for new files upstream.

After installing, restart Claude Code. Then read `~/.claude/playbooks/INDEX.md` for the task-to-playbook map.

## What it installs

**Playbooks** → `~/.claude/playbooks/` (14 field guides + 1 index + 1 prereq manifest):

- `mental-models.md`, `workspace.md`, `memory-and-skills.md` — how to work with a coding agent
- `the-loop.md`, `plan-quality.md`, `verification.md`, `retros.md` — the core development cycle
- `trust-boundaries.md`, `failure-modes.md`, `parallel-agents.md` — when things go wrong
- `pipeline-foundation.md`, `ci-and-release.md`, `deploy-and-health.md`, `devops-gotchas.md` — making the pipeline boring

**Skills** → `~/.claude/skills/`:

- `retrospective` — voice and narrative style for release retros
- `retro-discipline` — when to write a retro, the five-part anatomy
- `plan-quality-rubric` — quality gate for plans before execution
- `verification-semantics` — what to verify (tests ≠ feature, environment that matters, health checks)
- `parallel-agents-topology` — file-boundary ownership, merge points, wave pattern
- `failure-modes-diagnosis` — six failure shapes and the rescue protocol
- `devops-pipeline-foundation`, `devops-ci-and-release`, `devops-deploy-and-health`, `devops-gotchas`

**CLAUDE.md block** → appended to `~/.claude/CLAUDE.md` with marker lines. The installer only appends if the markers aren't already present; delete the block and re-run to refresh.

## Superpowers dependency

Five playbooks (`the-loop`, `plan-quality`, `verification`, `retros`, `parallel-agents`) layer on top of the [`superpowers`](https://github.com/anthropics/claude-plugins-official) plugin — they carry the *why, when, and rubric* that sits on top of the tactical *how* the plugin's skills enforce. If you don't have `superpowers` installed, those playbooks still read standalone, but the Prereq pointers will degrade to notes. See `~/.claude/playbooks/prereqs.md` after install.

## Override config

The installer honors these env vars:

- `GROUNDSKEEPER_REPO` — repo URL (default: upstream)
- `GROUNDSKEEPER_BRANCH` — branch (default: `main`)
- `CLAUDE_DIR` — install target (default: `$HOME/.claude`)

To preview the install against a scratch directory:

```bash
CLAUDE_DIR=/tmp/groundskeeper-preview ./install.sh
```

## Refreshing or removing

The installer never overwrites. To refresh a single file:

1. Delete it (`rm ~/.claude/playbooks/verification.md`)
2. Re-run the installer — it will reinstall what's missing

To refresh the CLAUDE.md block, delete the lines between `# <<< groundskeeper ...` and `# <<< end groundskeeper >>>` and re-run.

To uninstall, delete `~/.claude/playbooks/`, remove the installed skills from `~/.claude/skills/`, and delete the marker block in `~/.claude/CLAUDE.md`. There is no automated uninstall by design — removal should be deliberate.

## Repo layout

```
groundskeeper/
├── install.sh                           # homebrew-style installer
├── docs/
│   ├── engineer-agent-playbook-portable.md   # the full narrative playbook
│   └── agent-playbooks/                      # rule-first extracts (installed)
│       ├── INDEX.md                          # task-to-playbook map
│       ├── prereqs.md                        # superpowers skill manifest
│       └── *.md                              # 14 playbooks
└── claude-config/
    ├── CLAUDE.md.fragment                    # appended to ~/.claude/CLAUDE.md
    └── skills/                               # thin skill wrappers (installed)
        └── */SKILL.md
```

## License

See individual files. The playbook content is Seth's field notes; the installer is offered as-is for anyone who finds it useful.
