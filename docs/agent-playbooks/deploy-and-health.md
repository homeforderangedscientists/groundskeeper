# Deploy and Health

> Blue-green deploy (Track A) or atomic platform deploy (Track B), plus the health endpoints that make every deploy *answerable*. The deploy script is the single most-used piece of infrastructure you'll ever write. Boring is the goal.

## Blue-green deploy rules (Track A)

### The shape
Two stacks (`blue`, `green`) running side by side. Only one is live at a time, routed by nginx. Deploy builds the inactive color, health-checks it, smoke-tests it, flips nginx, and leaves the old color running as rollback insurance until the next deploy.

### The deploy script must be idempotent and re-entrant
**Why:** A deploy that fails halfway and can't be safely re-run is worse than one that fails entirely — you end up in a state nobody has a recipe for.
**How to apply:** Every step is safe to re-run. The script acquires a `flock` lock to prevent concurrent manual + CI deploys. If any step fails, the script rolls back to the previously-active color and exits non-zero.

### Self-reexec after `git pull`
**Why:** Bash buffers scripts into memory when they start executing. `git pull` updates the file on disk but the running shell keeps executing its in-memory copy of the old file. Any fix you just pulled will not take effect on the run that pulled it. This is how the case study burned a release on a footer that kept reading `rev unknown` — see `devops-gotchas.md`.
**How to apply:**
```bash
if [ -z "${DEPLOY_REEXEC:-}" ]; then
    export DEPLOY_REEXEC=1
    exec bash "$0" "$@"
fi
```
This goes **right after** `git pull`, **before** any substantive work.

### Pass `GIT_REV` via `--build-arg`, not just env file
**Why:** `docker compose --env-file` does not reliably propagate values into `ARG` substitutions. The case study chased `git_sha: unknown` through three deploys of env-file fixes before finally passing `--build-arg` directly. See `devops-gotchas.md`.
**How to apply:** On the build command: `docker compose -f docker-compose.prod.yml build --build-arg GIT_REV="$GIT_REV" backend-${color}`. Belt and suspenders: also write it to the env file for runtime, but the build arg is the authoritative source.

### Health-check the new color before smoke-testing, smoke-test before flipping
**Why:** The colors go live in order. A container that starts but fails its first smoke test never touches user traffic. The window between "started" and "verified" is where every deploy either builds or loses trust.
**How to apply:**
1. Build the inactive color.
2. `docker compose up -d` the new color.
3. **Loop on the container's own health endpoint** until it returns 200 or the loop times out (retry budget, not infinite).
4. Run the **pre-flip smoke test** against the new color directly (`localhost:8001`), not through nginx. This exercises the full application stack without routing.
5. **Only then flip nginx** to the new upstream.
6. Run the **post-flip smoke test** against the public URL, through nginx, with the real forwarded headers. This verifies the user-facing path.
7. On any smoke-test failure, **auto-rollback**: flip nginx back, stop the new color, exit non-zero.

### The smoke test creates a real resource
**Why:** A smoke test that only hits `/health` tests nginx and the framework, not your application. Creating a resource exercises the database, the cache, the serialization layer, and your auth middleware in one shot.
**How to apply:** Create a test resource (a temp timer, a fake entity, whatever's cheap and easy to roll back), read it back, compare the response body to what you wrote, delete it. Fail on any mismatch. The smoke test is the last line of defense before users see the new code.

### Write a deploy manifest on success
**Why:** "What's in production right now?" must always have a precise answer. The deploy manifest is that answer: a JSON file on the server with the active color, the git SHA, the deploy timestamp, and the user/workflow that ran it.
**How to apply:**
```bash
cat > /opt/myapp/deploy-manifest.json <<EOF
{
  "git_sha": "$GIT_REV",
  "active_color": "$NEW_COLOR",
  "deployed_at": "$(date -Iseconds)",
  "deployed_by": "${GITHUB_ACTOR:-manual}"
}
EOF
python3 -m json.tool /opt/myapp/deploy-manifest.json > /dev/null || exit 1
```
**Always validate the manifest parses as JSON** — if a heredoc produced garbage from a shell-quoting bug, fail the deploy so the existing rollback path triggers.

### Preflight before starting
**Why:** The worst time to find out Docker isn't running is after you've killed the active color. Preflight catches environment problems before they matter.
**How to apply:** Before any substantive work, verify: Docker is running; disk space above a threshold (5 GB minimum); env file exists and has required vars (**read the list of required vars from the compose file itself**, so the list is always current — a hardcoded checklist goes stale). Exit non-zero with a clear message on any failure.

## Health endpoints (both tracks)

### The two-endpoint split
**Why:** A single `/health` can't serve both load balancers and humans. Load balancers need a lightweight check that nginx is up; humans and deploy verifiers need the full dependency-status + git SHA payload. Conflating them means either the load balancer is slow or the deploy verification is thin. The case study's "Health Check That Wasn't" chased `git_sha: unknown` through three deploys of a producer that was never broken, because the verification curl was hitting the lightweight endpoint.
**How to apply:**
- **`/health`** — public, no auth, lightweight. Returns `{"status":"ok"}` in <100 ms. Used by nginx, load balancers, uptime monitors.
- **`/api/v1/health`** — authenticated, full payload. Returns git SHA, build timestamp, dependency status (DB ping, Redis ping, downstream reachability), version string. Used by deploy verification and the humans reading it during an incident.
- **Your deploy verification must hit `/api/v1/health`**, with the API key and whatever forwarded headers your middleware requires. Hitting `/health` and checking for `git_sha` is a three-deploy mistake waiting to happen.

### The full-payload endpoint must actually check
**Why:** A `/api/v1/health` that returns `{"status": "ok", "git_sha": "..."}` without pinging its dependencies is a status check cosplaying as a health check. The worst thing it can do is succeed during an outage. See `verification.md` *Health checks must check health.*
**How to apply:** The full health endpoint pings the DB, pings Redis, queries downstream services, and reports each dependency's status in the response body. The endpoint still returns 200 if dependencies are up; it returns 503 if any are down. The response body is the diagnosis, not just a status.

### Frontend footer shows version + git SHA
**Why:** When a user reports a bug, "what version are you on?" is the first question. A visible build stamp saves half the conversation.
**How to apply:** Read `VERSION` (or `package.json`) at build time, stamp the git SHA via build arg or env injection, render both in the footer. Format: `v5.11.0 (abc1234)`. A click-to-copy is nice but not required.

## Atomic platform deploy (Track B)

Track B hands the deploy mechanics to the platform (Netlify, Vercel, Cloudflare Pages). The script you write is thinner; the gotchas shift shape.

- **The platform owns blue-green.** You get atomic deploys and dashboard rollback for free.
- **BaaS migrations must run before the frontend deploys.** Order: (1) run schema migrations, (2) deploy edge functions, (3) deploy the frontend. Migrations that touch column names must ship before the frontend code that reads them — otherwise the frontend goes live against a schema it doesn't understand. Pin this ordering in the release workflow.
- **Post-deploy verification is visual + automated**, not `curl /health`. Hit the live URL with Playwright, check a few user flows, check the console for errors, verify the Lighthouse score didn't regress.
- **Edge function deployment has a propagation window.** `supabase functions deploy` reports success when the code is *uploaded*, not live. Verification curls that hit the function immediately can hit the old version. Include a build marker (version constant, SHA in a header) and wait for the new marker before calling the deploy verified.
- **"The Guard That Came Before the Secret"** — atomic platform deploys give you *less* recovery window than self-managed blue-green. A new startup check against an unset env var bricks the deploy instantly. **Walk cross-system ordering before every non-code deploy** (see `plan-quality.md`): the secret, the migration, the DNS entry, the third-party config — has each one landed in the target environment *before* the code that assumes it does?

## Deploy verification checklist

Before calling any deploy done:

1. **Hit the public URL** (not the container directly, not the platform API, not the CI logs) with a real request.
2. **Read the response body** for `git_sha` and compare to what you just built.
3. **Verify the active color/deploy ID** matches what the script wrote to the manifest.
4. **Run a real user flow** — create a resource, read it, delete it.
5. **Check the error monitor** (Sentry or equivalent) for new errors in the last N minutes.
6. **Paste the commands and outputs** into the deploy record. Prose is not evidence. See `verification.md`.

## Phase 4 + Phase 7 verification

- [ ] `deploy/deploy-bluegreen.sh` exists with a flock lock
- [ ] `deploy/smoke-test.sh` creates and reads a real resource
- [ ] `deploy/preflight.sh` checks Docker, disk, env file
- [ ] Self-reexec pattern runs after `git pull`
- [ ] `GIT_REV` passed via `--build-arg`, not just env file
- [ ] Manifest validated with `python3 -m json.tool` after write
- [ ] Post-deploy verification hits `/api/v1/health` with headers
- [ ] Auto-rollback tested (break smoke test on purpose, confirm rollback)
- [ ] `/health` responds in <100 ms with `{"status":"ok"}`
- [ ] `/api/v1/health` returns full JSON with real `git_sha` and dependency status
- [ ] Frontend footer shows version + git SHA
- [ ] UptimeRobot or equivalent monitors `/health`
- [ ] Error monitor is configured with `release=<git_sha>`

## See also

- `devops-gotchas.md` — every gotcha in this playbook has an entry there
- `verification.md` — the general rule behind the deploy verification discipline
- `ci-and-release.md` — what `deploy.yml` was triggered by
- `plan-quality.md` — cross-system ordering ("The Guard That Came Before the Secret")
