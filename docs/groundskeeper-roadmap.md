# groundskeeper — Roadmap

Companion to `groundskeeper-prd.md`. The PRD describes *what the product is*; this roadmap describes *the order in which to build it and the decisions to make along the way.*

**Date:** 2026-04-17
**Status:** Draft — plan for review before execution

---

## Where we are today

What's shipped and working:

- **Bash installer** (`install.sh`) with `install` / `--update` / `--force` modes
- **SHA-based manifest** at `~/.claude/.groundskeeper-manifest` tracks shipped files so `--update` can preserve user edits and refresh unmodified files
- **Content distribution** from this repo's `claude-config/` (playbooks, skills, a CLAUDE.md fragment)
- **End-to-end tested** on a real machine against scratch installs and real `~/.claude/`

What it *doesn't* do (and the PRD wants):

- Manage a **user's own** canonical config repo (today it's hardwired to this repo)
- Handle secrets or `{{VAR}}` substitution
- Provide `status` / `diff` / `rollback` / `optimize` commands
- Auto-sync on a schedule
- Manage `settings.json`, MCP config, or slash commands

The PRD's Node/TS CLI design is ambitious and probably right *eventually.* What follows is the sequence I'd ship it in.

---

## The central architectural question (answer this first)

**Is `install.sh` a prototype to be replaced, or the keeper of one job (content distribution) while the TS CLI owns a different job (user-config management)?**

The two tools overlap in ~30% of behavior (pull from a git source, write to `~/.claude/`, track SHAs). They differ in:

- **install.sh** — single-source, content-fixed (groundskeeper's playbooks), one-way pull
- **PRD CLI** — multi-source (any user's private repo), multi-asset (includes settings/MCPs/secrets), with optimization

Three paths:

1. **Converge** — the TS CLI subsumes install.sh. Groundskeeper's playbooks become one source preset. Retire `install.sh`.
2. **Split** — keep `install.sh` for distributing groundskeeper content; build TS CLI for user-config management. The two can share a manifest format.
3. **Keep bash, extend upward** — add more commands to `install.sh` (status, diff, even secrets). Skip TS until the AI-optimization milestone forces it.

**My recommendation: (3) for Milestones 1–4, then (1) from Milestone 5 onward.** Bash is cheap to extend; TS is expensive to build. Delay the rewrite until there's a feature (AI optimization) that genuinely requires it.

---

## Milestones

Each milestone names its **goal**, **scope**, and **ship criteria** — what has to be true before moving to the next.

### M0 — Today's shipped state

Baseline. No work needed. Confirms the manifest-backed additive-install pattern works. Every subsequent milestone builds on this foundation.

### M1 — Read-only visibility: `status` and `diff`

**Goal:** prove the manifest is useful for drift detection before investing in more features.

**Scope:**
- `install.sh status` — list each tracked file in one of: `up-to-date`, `locally-modified`, `missing-upstream`, `new-upstream`
- `install.sh diff <file>` — show the upstream-vs-local diff for a single file
- Both commands are read-only. No writes. No risk.

**Ship criteria:**
- Running `status` on a clean `--force`d tree shows 100% up-to-date
- Edit a playbook → `status` reports `locally-modified` for just that file
- Upstream-only files appear under `new-upstream` until next `--update`

**Why first:** it's cheap (~half a day), it validates that the manifest is a genuinely useful primitive, and it lets us live with the tool for a week before deciding on the bigger investments.

### M2 — Discovery (no code)

**Goal:** close the PRD's open questions *before* architectural commitments. The PRD itself flags this: *"Before any code is written, run `find ~/.claude -type f` on a live machine to verify the exact file layout."*

**Scope:**
- Run inventory on Seth's real `~/.claude/`. Document what's actually there, not what the PRD assumes.
- Classify every asset: user-authored, plugin-managed, cache/runtime, harness-generated. Only user-authored assets are candidates for groundskeeper to manage.
- Map MCP servers to their secret requirements. Which ones have tokens? Which read from env vars today? Which read from files?
- Decide: is `settings.json` in scope? It contains permissions, hooks, model preferences — some of which are per-machine and shouldn't sync. Probably scope a *subset* of `settings.json` fields, not the whole file.

**Ship criteria:**
- `docs/asset-inventory.md` documenting real layout
- Updated PRD with concrete file lists (not illustrative ones)
- Answer to: "what fields of `settings.json` are safe to manage vs. per-machine?"
- Answer to: "do any of Seth's MCPs currently use secrets?"

**Why second:** every subsequent milestone depends on knowing what's actually there. An hour of `find` saves a week of wrong abstractions.

### M3 — User's own canonical repo (still bash)

**Goal:** generalize from "pulls groundskeeper's content" to "pulls any user's content."

**Scope:**
- `install.sh` reads `~/.groundskeeper.config` (or similar) for the canonical repo URL
- If the config names a user repo, that becomes the source; groundskeeper's own playbooks become an *optional* add-on source
- `install.sh init <repo-url>` — first-time setup writes the config
- Multi-source merge policy: if both groundskeeper playbooks AND user repo ship `playbooks/foo.md`, which wins? Recommend: user always wins. Groundskeeper content is a floor, not a ceiling.

**Ship criteria:**
- Seth creates a `claude-env` repo of his own, runs `install.sh init <his-repo>`, his config syncs
- His own MCP/skill/CLAUDE.md content lands in `~/.claude/`
- Groundskeeper playbooks still install from their preset (can be disabled)

**Why now:** this is the hinge from "groundskeeper is a project I consume" to "groundskeeper is the tool I use to manage my own config." Without this step, everything else is scaffolding for one repo.

### M4 — Secrets and MCP handling

**Goal:** manage MCP config with `{{VAR}}` substitution, without ever checking secrets in.

**Scope:**
- `mcps/servers.json` in canonical repo with `{{VAR}}` tokens
- `secrets.example.json` documents required keys
- `secrets.json` is `.gitignore`d and lives local-only
- `install.sh secrets` — interactive wizard walks the example, writes local secrets
- Apply-time: substitute tokens, write live MCP config
- **Hard refuse** if `secrets.json` isn't `.gitignore`d in the canonical repo

**Ship criteria:**
- One real MCP (pick the one Seth uses most) goes through the full flow: add to canonical repo with `{{GITHUB_TOKEN}}`, run secrets wizard, sync, verify MCP works
- A deliberate test: commit `secrets.json` to a test repo, confirm install.sh refuses to apply

**Why now:** this is the highest-value feature below the AI tier. Every other sync capability is cosmetic until secrets work.

### M5 — TypeScript CLI rewrite (the investment milestone)

**Goal:** replace bash with a TS CLI *only because* the next milestone's features (AI optimization) genuinely need a richer runtime.

**Scope:**
- `groundskeeper` CLI in TypeScript, esbuild-bundled to a single JS file
- Commands: `init`, `sync`, `status`, `diff`, `secrets`
- Feature parity with the bash version at M4
- Manifest format unchanged — old bash-installed manifests read correctly
- `install.sh` becomes a thin bootstrapper that installs the CLI binary (not the content)

**Ship criteria:**
- `groundskeeper sync` produces byte-identical output to `install.sh --update` on the same repo
- Old bash users can migrate with zero loss (run `groundskeeper init` with same config → same manifest → same state)

**Why now (and not earlier):** bash is cheap, TS is expensive. Delay the rewrite until the reason for it is concrete (next milestone).

**Alternate path:** if M1–M4 reveal bash is hitting real limits before M5 (e.g. Windows support becomes a goal, or JSON manipulation gets painful), pull M5 earlier. Don't pre-commit.

### M6 — AI-assisted optimization (PRD Phase 1)

**Goal:** the differentiating feature. Groundskeeper uses AI to prune, deduplicate, and rewrite config.

**Scope — three independently runnable sub-phases:**
- `groundskeeper optimize --prune` — dead MCP/skill detection (non-AI; just referential analysis)
- `groundskeeper optimize --conflicts` — AI identifies overlapping skills/commands/rules
- `groundskeeper optimize --rewrite` — AI proposes CLAUDE.md rewrite with diff review

Every destructive action:
- Runs in dry-run by default (show what would change)
- Requires explicit `--commit` to apply
- Commits changes to canonical repo with `CHANGELOG.md` entry
- Never touches secrets

**Ship criteria:**
- On Seth's real config, `--prune` correctly identifies at least one dead/unreferenced asset
- `--conflicts` surfaces at least one real overlap the user confirms
- `--rewrite` produces a CLAUDE.md rewrite the user accepts at least partially

**Why now:** this is the reason the TS CLI exists. Without it, groundskeeper is a fancy rsync. With it, groundskeeper becomes a config hygiene tool.

### M7 — Polish (PRD Phase 2)

**Goal:** close the loop with rollback, scheduling, and secret integrations.

**Scope:**
- `groundskeeper rollback <version>` — git checkout tag + sync
- Auto-sync via launchd (macOS) / cron (Linux) on a configurable interval
- `--keychain` / `--op` flags for macOS Keychain / 1Password CLI secret sources

**Ship criteria:**
- Rollback works through at least one real version transition
- Auto-sync runs unattended for a week without intervention
- One MCP reads its token from Keychain without secrets.json involvement

---

## Cross-cutting concerns

Applies across all milestones, not any single one:

- **Every milestone ends with a retro** under `retros/`. The retro either produces one rule for the next milestone or admits there was nothing new to learn.
- **Every milestone has end-to-end tests** against a scratch `CLAUDE_DIR`, not just unit tests.
- **Manifest schema evolves** — add a `schemaVersion` field now so we can migrate later without breaking old installs.
- **The `superpowers` dependency documented today** (in `prereqs.md`) is load-bearing for the playbook system; the tool should detect its presence and warn if missing, not break.

---

## Decisions to make before M1 starts

1. **Path question above** — converge, split, or extend-then-converge? *Recommendation: extend-then-converge.*
2. **Canonical repo location for Seth personally** — where does his `claude-env` live? Private GitHub? Self-hosted? Informs M3's testing target.
3. **Scope of `settings.json`** — whole file, subset, or not at all? Needs M2 discovery to answer.
4. **What MCPs Seth actually uses today** — resolves M4's "pick the first real one" choice.

---

## Risks worth flagging early

- **Multi-machine divergence:** PRD explicitly scopes this out of v1 (pull-only, no conflict resolution), but users *will* hit it. Name the limitation visibly in docs; don't pretend it's not a problem.
- **settings.json fragmentation:** some fields are global, some are per-machine, some get auto-written by Claude Code itself (model picks, hook ports). Managing `settings.json` without fighting the harness is harder than the PRD acknowledges.
- **AI rewrite rejection rate:** M6's `--rewrite` will only get used if users trust it. First few versions probably produce rewrites the user rejects. Build the confirmation UX *really* well, including cherry-pick.
- **Private repo auth in the curl one-liner:** today's install works because this repo is public. User repos will be private. The bootstrap story needs `gh auth` or a similar entry point that doesn't assume public anonymous curl works.
- **Manifest schema migration:** decided to version the manifest now. First time we actually migrate a real user's manifest through a schema bump is when the theory meets the road — design for it from the start.

---

## The one-sentence version

**Extend the bash installer through Milestones 1–4 (status, discovery, user-repo, secrets), then rewrite in TS at Milestone 5 so Milestone 6 (AI optimization) has a real runtime — and end every milestone with a retro.**
