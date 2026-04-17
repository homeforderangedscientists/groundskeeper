# CI and Release Automation

> What runs on every push, every PR, and every release. CI catches the bugs your laptop doesn't; the release system turns green main into a live URL without anyone remembering a command.

## CI rules

### Workflow lint is the first job
**Why:** Workflows that don't parse, shell snippets with injection bugs, unpinned actions, invalid YAML — these are bugs in your CI/CD *code*. If the first job doesn't catch them, you find out by way of a deploy that failed in a confusing way on a Friday.
**How to apply:** `actionlint` as the first job in every CI workflow. Pin the action. Fail the pipeline on any finding. `shellcheck`-style rules fire on shell steps too — fix every `SC` finding, don't suppress them.

### SHA-pin every third-party action
**Why:** `@v4` or `@main` is a supply-chain vulnerability — the author can push a new commit under that tag and your CI will run it silently. SHA pins can't be rewritten.
**How to apply:** Every `uses:` line points to a 40-char SHA with a comment recording the human version: `uses: actions/checkout@abc1234... # v4.1.1`. Use `dependabot` to bump the SHAs with PRs you can review.

### Tests run against real dependencies, not mocks
**Why:** Integration tests with mocked databases pass locally and fail in prod when the migration behavior diverges. The case study's "Cache That Lied In CI" burned a release on exactly this gap — local used an in-memory cache that skipped serialization; CI used real Redis. See `verification.md` *Verify in the environment that matters.*
**How to apply:** CI spins up real Postgres, real Redis, real whatever-you-use. Tests run against those services, not mocks. If a gap exists (local runs SQLite, CI runs Postgres), that gap is the bug — fix the parity, then run the test.

### Secrets scanning runs on every push
**Why:** Leaked secrets in git history are forever. A scan on every push catches them at the wall closest to the author; a scan on a schedule catches them after someone's already cloned the repo.
**How to apply:** `trufflehog` or equivalent on every push *and* against the full git history. Fail on CRITICAL findings. Rotate any key that gets flagged immediately, before asking "was it really exposed?"

### Vulnerability scans on dependencies and images
**Why:** Your dependency tree has known CVEs you don't know about. An image scanner catches the ones that made it into the final layer. Finding them in CI is free; finding them in the security audit mailbox is not.
**How to apply:** `pip-audit` / `npm audit` / equivalent on dependency installs, failing on CRITICAL. `trivy` on the built Docker image, failing on CRITICAL+HIGH. Pin `--ignore-unfixed` off — an unfixed CVE is still a CVE.

### Docker build validation
**Why:** A build that succeeds doesn't mean the image does what you think. The case study's "Docker Port Mappings That Weren't" shipped four releases before anyone noticed the container was unreachable — CI had validated the image *built*, not that it *answered*.
**How to apply:** After the build, verify: (1) the image doesn't contain things it shouldn't (`.git`, `node_modules`, `__pycache__`) — fail if they're present; (2) the image actually starts and responds to a basic healthcheck before CI passes.

### Bundle size, performance, and accessibility budgets (frontend)
**Why:** Bundle sizes grow silently. Lighthouse scores degrade silently. Accessibility violations slip past visual review. Each is a gate you either install or get bitten by later.
**How to apply:** A bundle-size assertion on every frontend build, failing if the main bundle exceeds a budget. Lighthouse CI with explicit score thresholds (performance, accessibility, best-practices, SEO). `axe-core` accessibility tests in the E2E suite, failing on violations. `@testing-library/user-event` for interaction tests, Playwright for cross-device E2E, at least one touch-device profile.

### Rate limits and body-size limits on every public endpoint
**Why:** Unauthenticated rate limits protect against abuse before auth is even invoked. Body size limits protect against DoS via large uploads. Neither matters until it matters, at which point you wish you'd installed them weeks ago.
**How to apply:** Rate-limit every public endpoint, not just the authenticated ones. Body size limits on POST/PUT. These are middleware at the framework layer, not application-level checks.

## The CI job graph (what runs when)

```
push → workflow-lint → commitlint → backend-tests → docker-build → image-scan → secrets-scan
                   ↘ frontend-tests → bundle-size → lighthouse → a11y-tests → e2e-tests
```

All jobs run in parallel where dependencies allow. **`workflow-lint` must be first and must block everything.** A broken workflow can't be trusted to run the other jobs correctly.

## CI notifications

- **CI failures on `main` notify the team channel** (Slack, Discord, equivalent). Use Block Kit JSON with explicit fields, not raw markdown. Slack's `mrkdwn` is not standard Markdown — see `devops-gotchas.md`.
- Use `jq -n --arg` to build notification payloads involving any dynamic content. **Never** use `sed` substitution on user input — it's an injection vector. See `devops-gotchas.md`.

## Release automation (release-please)

### Setup
- **Pick a release tool** that reads conventional commits and opens Release PRs automatically: `release-please-action` is the reference.
- **Config file (`release-please-config.json`)** lives at repo root. It controls changelog generation and version-bumping rules.
- **`target-branch` is an action input, not a config-file key.** Passing it in the config file is silently ignored. Set it in the `with:` block of the release-please-action step in the workflow YAML.
- **Create a Release anchor.** With no prior Release, release-please walks commit history back to the beginning of the repo and can surface ancient `BREAKING CHANGE:` markers, producing wildly wrong version proposals. Options: full 40-char SHA for `bootstrap-sha`, or create an anchor Release manually with `gh release create`, or use a one-shot `release-as: X.Y.Z`.

### The critical token gotcha
- **Releases created with the default `GITHUB_TOKEN` do NOT trigger downstream workflows.** This is intentional GitHub security to prevent workflow loops. Result: release-please creates a real GitHub Release, and your `deploy.yml` wired to `release: [published]` never fires.
- **Fix:** create a Personal Access Token with `contents: write` scope, add it as `RELEASE_PAT`, and pass `token: ${{ secrets.RELEASE_PAT }}` to the release-please action. PAT-created releases DO fire downstream workflow triggers.
- **Workaround if you haven't set up the PAT yet:** manually dispatch `deploy-only.yml` via `workflow_dispatch` after the Release appears.

### The release flow end-to-end
```
feature commit → develop → main (merged) → release-please opens Release PR (bumps VERSION, regens CHANGELOG)
                → human merges Release PR → GitHub Release published (by PAT) → deploy.yml triggers on release event
                → deploy script runs → smoke tests pass → nginx flip → notifications
```

### Emergency dispatch
- `deploy-only.yml` exists as a `workflow_dispatch` workflow for the case when the release event didn't fire and you need to deploy the current `main` immediately. One-button recovery path.

## Phase 2–3 + Phase 5 verification

- [ ] `workflow-lint` is the first job and passes
- [ ] All actions SHA-pinned with version comments
- [ ] `commitlint` runs on PRs
- [ ] Tests run against real Postgres/Redis (not mocks)
- [ ] Bundle size, Lighthouse, axe-core checks run on frontend
- [ ] `pip-audit` / `npm audit` / `trivy` / `trufflehog` configured
- [ ] Docker build validates exclusions
- [ ] CI failure on `main` notifies the team channel
- [ ] `release-please-config.json` exists without `target-branch` at root
- [ ] `release.yml` passes `target-branch: main` as action input
- [ ] release-please uses `secrets.RELEASE_PAT`, not `GITHUB_TOKEN`
- [ ] GitHub setting "Allow GitHub Actions to create and approve PRs" is enabled
- [ ] `deploy.yml` triggers on `release: [published]`
- [ ] `deploy-only.yml` exists for emergency manual dispatch
- [ ] End-to-end test: commit → develop → main → Release PR → merge → Release → deploy

## See also

- `pipeline-foundation.md` — what has to be in place before CI matters
- `deploy-and-health.md` — what `deploy.yml` triggers
- `devops-gotchas.md` — the release-please + token traps
- `verification.md` — the "verify in the environment that matters" rule
