# Groundskeeper

The engineer + agent playbook for Claude Code — a field manual for partnering an engineer with a coding agent, distilled into rule-first playbooks and installable task-triggered skills.

## Install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/homeforderangedscientists/groundskeeper/main/install.sh)"
```

The installer is **additive by default**: it never overwrites existing playbooks, skills, or CLAUDE.md content. Run it twice and the second run is a no-op except for new files upstream.

After installing, restart Claude Code. Then read `~/.claude/playbooks/INDEX.md` for the task-to-playbook map.

### Update to latest upstream

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/homeforderangedscientists/groundskeeper/main/install.sh)" _ --update
```

Update mode refreshes only the shipped files you haven't modified. The installer tracks each file's SHA256 at install time in `~/.claude/.groundskeeper-manifest`. On `--update`, for each shipped file:

- If your on-disk copy matches the recorded SHA (you haven't edited it) → refresh to upstream.
- If your on-disk copy differs (you edited it) → preserve your copy, report it.
- If the file is new upstream (not in your manifest) → install fresh.

Preserved files are listed explicitly at the end so you can decide whether to merge upstream changes manually or re-run with `--force`.

### Force overwrite (destructive)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/homeforderangedscientists/groundskeeper/main/install.sh)" _ --force
```

Force mode overwrites every shipped file regardless of local modifications. Use only when you want to discard your local changes and reset to upstream.

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

**CLAUDE.md block** → appended to `~/.claude/CLAUDE.md` between marker lines. On `--update`, the block is refreshed if you haven't edited it; preserved if you have.

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

Three ways to refresh, from safest to most destructive:

1. **`./install.sh --update`** — refresh files you haven't modified; preserve files you have. The normal update path. Requires the `.groundskeeper-manifest` file to know what "unmodified" means, which the installer writes on first install.
2. **Delete then re-run** — `rm ~/.claude/playbooks/verification.md` then re-run `./install.sh`. Reinstalls just the file you removed. Useful for a targeted reset without `--force`.
3. **`./install.sh --force`** — overwrite every shipped file. Destructive. Use when you want to reset to upstream and discard local edits.

To uninstall, delete `~/.claude/playbooks/`, remove the installed skills from `~/.claude/skills/`, delete the marker block in `~/.claude/CLAUDE.md`, and remove `~/.claude/.groundskeeper-manifest`. There is no automated uninstall by design — removal should be deliberate.

## Repo layout

```
groundskeeper/
├── install.sh                           # homebrew-style installer
├── claude-config/                       # install payload (everything here ships)
│   ├── CLAUDE.md.fragment                    # appended to ~/.claude/CLAUDE.md
│   ├── playbooks/                            # rule-first extracts (installed)
│   │   ├── INDEX.md                          # task-to-playbook map
│   │   ├── prereqs.md                        # superpowers skill manifest
│   │   └── *.md                              # 14 playbooks
│   └── skills/                               # thin skill wrappers (installed)
│       └── */SKILL.md
├── docs/                                # human-readable narrative docs
│   ├── engineer-agent-playbook-portable.md   # the full narrative playbook
│   └── DEVOPS-PLAYBOOK-portable.md           # the full DevOps playbook
└── retros/                              # release retrospectives
```

## License

See individual files. The playbook content is Seth's field notes; the installer is offered as-is for anyone who finds it useful.
