# groundskeeper — PRD v0.1

**Project:** groundskeeper  
**Owner:** Home For Deranged Scientists  
**Date:** 2026-04-17  
**Status:** Pre-implementation / Brainstorm

---

## Overview

`groundskeeper` is a CLI tool that manages a developer's global Claude Code environment across multiple machines. It provides pull-based synchronization from a canonical git repository, secret handling, and an AI-assisted optimization pipeline for pruning, deduplication, and rewriting of Claude configuration assets.

---

## Problem Statement

Claude Code's global environment — instructions, MCP configs, skills, slash commands, and preferences — is scattered across `~/.claude/` with no native mechanism for keeping it consistent across machines, versioning it, or improving it over time. This means environment drift, manual re-setup on new machines, and no systematic way to improve the quality of instructions or detect dead/conflicting configuration.

---

## Goals

- One canonical source of truth (a private git repo) for all Claude Code global configuration.
- Any machine can sync to that repo with a single command after initial setup.
- Secrets are never stored in git.
- An optimization pipeline uses AI to prune, deduplicate, and rewrite configuration assets.
- Install experience mirrors Homebrew: a single `curl | bash` command.

---

## Non-Goals (v1)

- Push/pull bidirectional sync or conflict resolution between machines.
- Per-project Claude environments (this is global config only).
- GUI or web interface.
- Integration with cloud secret managers (1Password, Keychain) — planned for v2.

---

## Assets Under Management

> **Note:** Before any code is written, run `find ~/.claude -type f` on a live machine to verify the exact file layout. The following is the expected structure.

| Asset | Path | Notes |
|---|---|---|
| Global instructions | `~/.claude/CLAUDE.md` | Primary optimization target |
| Settings / preferences | `~/.claude/settings.json` | Model choice, permissions, etc. |
| MCP config | `~/.claude/claude_desktop_config.json` | Contains secrets — never committed raw |
| Skills | `~/.claude/skills/` | Directories of files |
| Slash commands | `~/.claude/commands/` | Markdown files |

---

## Canonical Repo Structure

The user maintains a private GitHub/GitLab repo with this layout:

```
claude-env/
├── CLAUDE.md
├── settings.json
├── mcps/
│   ├── servers.json            # MCP definitions; secrets replaced with {{VAR}} tokens
│   └── secrets.example.json    # lists required secret keys with descriptions
├── skills/
│   └── <skill-name>/
│       ├── SKILL.md
│       └── ...
├── commands/
│   └── *.md
├── .claude-env.json            # manifest: version, schema version, metadata
└── CHANGELOG.md                # auto-appended by optimize pipeline
```

`secrets.json` is always `.gitignored`. At apply-time, the CLI merges `servers.json` + `secrets.json` to produce the live MCP config.

---

## CLI Design

**Install:**
```bash
curl -fsSL https://raw.githubusercontent.com/<user>/groundskeeper/main/install.sh | bash
```

**Commands:**

| Command | Description |
|---|---|
| `groundskeeper init <repo>` | First-time setup: clone repo, configure secrets, apply |
| `groundskeeper sync` | Pull latest from repo and apply to `~/.claude` |
| `groundskeeper status` | Show drift between repo and local state |
| `groundskeeper diff` | Preview what `sync` would change |
| `groundskeeper secrets` | Interactive wizard to set/update secrets |
| `groundskeeper optimize` | Run the full optimization pipeline |
| `groundskeeper rollback <version>` | Check out a previous version and apply |

---

## Installer Script

The `install.sh` script:

1. Checks for `git`, `node` (>=18), and `claude` CLI — warns if missing.
2. Prompts for the canonical repo URL.
3. Clones the repo to `~/.claude-env-repo/`.
4. Installs the `groundskeeper` CLI globally (npm link or copy to `/usr/local/bin`).
5. Runs `groundskeeper secrets` to interactively populate `secrets.json`.
6. Runs `groundskeeper sync` to apply the environment.
7. Optionally registers a cron/launchd entry for periodic auto-sync.

---

## Sync Mechanics

**Pull → Validate → Backup → Apply**

1. `git pull origin main` in the repo directory.
2. Validate `.claude-env.json` manifest against schema (using `zod`).
3. Back up current `~/.claude` to `~/.claude.bak.<timestamp>`.
4. Merge `mcps/secrets.json` + `mcps/servers.json` → live MCP config file.
5. Copy each managed file to `~/.claude/`.
6. Write applied commit hash to `~/.claude-env-state.json`.
7. Report what changed.

`status` and `diff` compare current repo HEAD against the hash in `~/.claude-env-state.json`.

**Copy vs. symlink:** Copy for v1. Symlinks are a future preference option.

---

## Secret Handling

Secrets never touch git, ever.

- `mcps/servers.json` uses `{{VAR_NAME}}` tokens for all sensitive values.
- `secrets.example.json` documents every required token: `{ "GITHUB_TOKEN": "GitHub PAT for MCP server" }`.
- `secrets.json` (gitignored) holds actual values on each machine.
- `groundskeeper secrets` walks through `secrets.example.json` and populates `secrets.json` interactively.
- **v2:** `--keychain` flag to read from macOS Keychain or 1Password CLI.

---

## Optimization Pipeline

Three phases, each independently runnable. All destructive actions require confirmation.

### Phase 1 — Prune Dead MCPs and Skills

- For each MCP in `servers.json`: check whether the server binary/package exists; attempt a health ping if one is available.
- For each skill: check whether it is referenced in `CLAUDE.md` or any command file; flag unreferenced skills.
- Produce a report; prompt for confirmation before removing anything.

### Phase 2 — Conflict and Redundancy Detection

- Parse all `SKILL.md` files and extract capability descriptions.
- Send to Claude API: *"Here are N skill descriptions. Identify overlapping or redundant capabilities."*
- Present flagged pairs to the user; user decides what to merge or remove.

### Phase 3 — AI-Assisted CLAUDE.md Rewrite

- Send current `CLAUDE.md` to Claude with a structured prompt requesting a clearer, more concise, internally consistent rewrite with contradiction flags.
- Present a diff of original vs. suggested rewrite.
- User approves, rejects, or cherry-picks sections.
- Approved changes are committed to the repo with a `CHANGELOG.md` entry.

---

## Versioning and Rollback

Git history is the version store for v1. The `.claude-env.json` manifest carries a semver-style version tag (e.g. `1.4.2`), bumped manually or via `groundskeeper optimize --commit`. `CHANGELOG.md` is auto-appended by the optimize pipeline.

Rollback: `groundskeeper rollback <version>` wraps `git checkout <tag>` + `groundskeeper sync`.

---

## Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Installer | Bash | Universal, no dependencies |
| CLI runtime | Node.js + TypeScript | Ecosystem fit, good Anthropic SDK support |
| Bundling | `esbuild` → single JS file | Fast, portable |
| Schema validation | `zod` | Validate manifest and settings at apply-time |
| AI calls | `@anthropic-ai/sdk` | First-party |
| Git operations | Shell out to `git` | Simpler than a git library for v1 |

---

## Phased Scope

**Phase 0 — Foundation**
- Repo schema and `.claude-env.json` manifest design.
- `init`, `sync`, `status`, `diff` commands.
- Secret handling (`secrets` command, token substitution).
- Bash installer.

**Phase 1 — Optimization**
- Dead MCP/skill pruning.
- CLAUDE.md AI rewrite with diff review.
- Conflict/redundancy detection across skills.

**Phase 2 — Polish**
- `rollback` command.
- Auto-sync via cron/launchd.
- `optimize --commit` for clean repo history.
- Keychain/1Password integration for secrets.

---

## Open Questions

- What is the exact file layout of `~/.claude/` on a live machine? (Verify before Phase 0.)
- Should skills with their own `package.json` trigger a post-sync `npm install`? Likely yes — needs a lifecycle hook.
- Should `sync` refuse to run if secrets are missing, or warn and continue? Probably warn-and-continue for non-MCP assets, block for MCP if the server requires them.
- Is there a lock-file story for concurrent syncs across machines? Probably not needed for v1 given pull-only model.
