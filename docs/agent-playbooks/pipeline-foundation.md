# Pipeline Foundation

> Git-flow, conventional commits, ignore files, version management, and local dev parity. Before any CI, any deploy, any release automation — this has to be in place. Track A (self-hosted VPS + Docker) and Track B (PaaS + BaaS) share this layer.

## The six pipeline rules (from the DevOps playbook)

Pin these above your desk:

1. **Catch bugs at the nearest wall.** A bug in CI is 10× cheaper than prod. A bug on your laptop is 10× cheaper than CI. Every new wall catches a class of bugs that's otherwise invisible.
2. **Every deploy must be answerable.** "What's in production right now?" must always have a precise answer: real git SHA in the health endpoint, deploy manifest on the server, a notification trail, a scripted rollback path.
3. **Fail loudly at known boundaries.** Silent failures are the enemy. If a step can't do its job, fail the whole pipeline with a clear error. Defensive retries and graceful degradation are for production behavior, not CI.
4. **The pipeline must also lint itself.** Workflows that don't parse, shell scripts with injection bugs, commit messages that break automation — these are bugs in your CI/CD *code*. Add a linter for them.
5. **Documentation is part of the build.** A runbook that points at a deleted script is worse than no runbook. Docs are checked, linked, and updated in the same PRs as the code they describe.
6. **Don't skip the boring work.** Conventional commits, SHA-pinning actions, writing retros, filing follow-up issues — every shortcut here is paid back with interest.

## Foundation checklist

### Git-flow branching
- **Two long-lived branches:** `develop` (default) and `main` (production).
- **Feature branches** off `develop`, merge back via PR.
- **`main` gets branch protection:** require PR, require status checks.
- **GitHub's default branch must be `develop`** if you're using git-flow. Otherwise release-please and other tools default to the wrong branch. Set this in Settings → Branches **before** wiring up release automation.

### Conventional commits
- Every commit message is `type(scope): subject` — `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `ci:`, `build:`, `perf:`.
- Subjects start with a lowercase letter (commitlint `subject-case` rule). Put issue IDs in parens at the end: `fix(ci): target main branch (JIRA-153)`, not `fix(ci): JIRA-153 target main branch`.
- Commitlint runs on PRs. `@commitlint/config-conventional` is the default rule set.
- *Why:* release-please reads commit messages to decide version bumps and changelog sections. Non-conforming commits are silently skipped.

### Ignore files
- **`.gitignore`** excludes `.env`, `__pycache__`, `node_modules`, `*.log`, `logs/`, build artifacts, editor junk, `.DS_Store`, coverage reports.
- **`.dockerignore`** is aggressive — default is not enough. Exclude `.git`, `node_modules`, `__pycache__`, tests, docs, CI config, `.env*`. Verify the build context stays small: `docker build` should report "Sending build context to Docker daemon X MB" and X should be well under ~50 MB for a small project.
- Add a CI step that verifies the built image doesn't contain `.git` or `node_modules` — regression protection.

### VERSION file
- Single `VERSION` file at repo root, one line, semver.
- **Everything else reads it.** Frontend footer, backend `/api/v1/health`, Docker label, changelog. A `scripts/sync-version.py` or equivalent updates any place that can't read it directly.
- *Anti-pattern:* scattering `version = "1.2.3"` across four files and remembering to update each. You won't remember.
- *Track B specifically:* do **not** rely on `import.meta.env.npm_package_version` — it's unreliable across npm/Vite combinations. Read `package.json` directly with `readFileSync` at config-eval time and inject via Vite's `define:`.

### Multi-stage Dockerfiles (Track A)
- **Stage 1 — dependencies:** install only what's needed for the build and test stages.
- **Stage 2 — test:** used by CI, not by prod. Runs the test suite inside the image.
- **Stage 3 — production:** the image that ships. Minimal, non-root user, healthcheck.
- Accept `--build-arg GIT_REV` so CI can stamp the image with git metadata. **Pass `--build-arg` directly on `docker compose build`; do not rely on compose YAML `${GIT_REV:-unknown}` substitution** — it's unreliable. See `devops-gotchas.md`.
- Run as non-root. `USER appuser` near the end of the production stage.

### Local dev compose parity
- `docker-compose.yml` starts the full stack locally — backend, frontend, DB, cache, any sidecars.
- **Local and CI and prod run the same image paths.** If local uses SQLite and CI uses Postgres, that's a parity gap waiting to ship you a "works on my machine" bug. See `verification.md` *Verify in the environment that matters.*
- `docker-compose.prod.yml` is the blue-green production variant — separate service names (`backend-blue`, `backend-green`), same image definitions.
- `.env.example` is committed with safe defaults. `.env` is **not** committed.

### First commit to `main`
- Once the foundation is in place, make one explicit commit to `main` establishing the repo structure. This is the anchor release-please will bootstrap from (see `ci-and-release.md` — release-please needs a Release anchor or it walks history to the beginning of the repo).

## Phase 0 verification (before moving on)

- [ ] `develop` and `main` exist; `develop` is the default branch
- [ ] `main` has branch protection
- [ ] `.gitignore` excludes the standard noise
- [ ] `.dockerignore` is aggressive; build context is small
- [ ] `VERSION` file exists and all places that display version read it
- [ ] Conventional commits enforced via commitlint
- [ ] Last 10 commits are actually conventional
- [ ] `docker compose up` starts the full stack locally
- [ ] `docker compose down` cleans up without errors
- [ ] Local `/health` endpoint responds

## See also

- `ci-and-release.md` — what runs on every push once the foundation exists
- `deploy-and-health.md` — the deploy script and health endpoints
- `devops-gotchas.md` — the traps that will bite you
- `workspace.md` — where project facts live (CLAUDE.md et al.)
