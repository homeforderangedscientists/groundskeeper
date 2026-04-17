# DevOps Gotchas

> Twenty-five traps from the DevOps playbook's Hall of Fame. Severity legend: 🟥 will ship you, 🟧 will burn an afternoon, 🟨 good to know.

## Most likely to ship you (🟥) — read these first

### 1. `GITHUB_TOKEN`-created releases don't trigger downstream workflows 🟥
This is intentional GitHub security — it prevents workflow loops. But it means release-please running with `GITHUB_TOKEN` creates a real GitHub Release that never fires `release: [published]`, so your `deploy.yml` never runs.
**Fix:** create a PAT with `contents: write`, add it as `RELEASE_PAT`, pass `token: ${{ secrets.RELEASE_PAT }}` to the release-please action. PAT-created releases DO fire downstream workflow triggers.
**Workaround if you haven't set up the PAT yet:** dispatch `deploy-only.yml` manually via `workflow_dispatch` after the Release appears.

### 2. `/health` vs `/api/v1/health` 🟥
Have two endpoints. `/health` is lightweight status for nginx/load balancers. `/api/v1/health` is the full authenticated version with `git_sha`. **Your deploy verification must hit the authenticated one** and pass the API key + forwarded headers your middleware requires. Three deploys were once burned chasing a producer that was never broken because the verifier was hitting `/health`.

### 3. Bash self-reexec after `git pull` 🟥
When your deploy script does `git pull origin main`, any subsequent changes to the script itself are on disk but NOT in the running bash process's memory. Bash buffers scripts. Without `exec bash "$0"` after the pull, you're still running the OLD script.
```bash
if [ -z "${DEPLOY_REEXEC:-}" ]; then
    export DEPLOY_REEXEC=1
    exec bash "$0" "$@"
fi
```

### 4. `docker compose --env-file` doesn't reliably propagate to build args 🟥
Compose's `${GIT_REV:-unknown}` substitution for build arg values is inconsistent. The reliable fix is to pass `--build-arg GIT_REV=...` directly on the `docker compose build` command.

### 5. Publishable vs. service-role keys on BaaS (Track B) 🟥
- **`anon` / publishable key** — client-safe, goes in the bundle. Protected by RLS on every table. **RLS is your authorization boundary; the key is just an entry token.**
- **`service_role` / secret key** — bypasses RLS. Full admin. Must NEVER appear in client code, CI logs, git, or anywhere a user could see it.
- Never commit the service role key "just for local dev." Local dev uses `supabase start` (or equivalent), which generates local keys that are safe by definition.
- If you need to bypass RLS for one query, use a `SECURITY DEFINER` RPC function, not a leaked key.
- If you see a key in a client bundle and panic: check which one it is. Publishable = fine (RLS protects you). Service role = active incident, rotate immediately.

### 6. Default-to-admin in BaaS handler signatures (Track B) 🟥
A shared handler that takes `client: 'admin' | 'anon'` must default to **anon**, not admin. The unsafe default is the one everyone uses when they don't think about the field. The case study shipped a refactor where the default was `admin` and two public endpoints silently ran with admin keys for a full release. The fix was one line. See `trust-boundaries.md` *The default direction also matters.*

### 7. PostgREST `.or()` is an injection vector with user input (Track B) 🟥
Passing user input into PostgREST's `.or(...)` string opens an injection path. Entity names with commas, dots, or parentheses break out of the intended filter.
**Fix:** never interpolate user input into `.or()` strings. Use multiple `.eq()` queries in parallel and merge results client-side, or use a database function with explicit parameters.

### 8. Supabase admin checks must read `app_metadata.role`, not `user_metadata.role` (Track B) 🟥
`user_metadata` is writable by the user themselves via `supabase.auth.updateUser()`. An admin check that reads `user_metadata.role` lets any user grant themselves admin.
```ts
// WRONG — user-writable, trivially escalatable
const isAdmin = session.user.user_metadata?.role === 'admin'
// RIGHT — only the service role can write this field
const isAdmin = session.user.app_metadata?.role === 'admin'
```
Audit every admin check in your codebase the day you add the first one.

## Will burn an afternoon (🟧)

### 9. GitHub default branch vs git-flow 🟧
If you're using `develop` + `main` git-flow, GitHub's default branch must be `develop`. Otherwise release-please and various tools default to the wrong branch. Set this in Settings → Branches **before** wiring up release-please.

### 10. Docker build context is everything in the build dir 🟧
A default `.dockerignore` doesn't exclude enough. Audit yours regularly. Add a CI step that verifies exclusions (`.git`, `node_modules` not present in the built image).

### 11. `target-branch` in `release-please-config.json` is silently ignored 🟧
release-please v16+ takes `target-branch` as an **action input** in the workflow YAML, not as a root-level key in the config file. The config file silently accepts it but the value is never used. If release-please opens PRs against the wrong branch, this is almost certainly why.
**Fix:** set `target-branch: main` in the `with:` block of the release-please-action step.

### 12. release-please needs a Release anchor 🟧
With no prior Release, release-please walks commit history back to the beginning of the repo, often surfacing old `BREAKING CHANGE:` markers and producing wildly wrong version proposals.
**Workarounds:**
- Full 40-char SHA for `bootstrap-sha`
- Manually create an anchor with `gh release create`
- One-shot `release-as: X.Y.Z` in the config, removed immediately after ship

### 13. Commitlint `subject-case` rule 🟧
`@commitlint/config-conventional` disallows sentence-case subjects. Start subjects with a lowercase letter. Don't paste issue IDs at the start — put them in parens at the end:
- ❌ `fix(ci): JIRA-153 target main branch`
- ✅ `fix(ci): target main branch (JIRA-153)`

### 14. Squash-merge divergence 🟧
Squash-merging into develop, then merging develop → main, then making main-only hotfix commits creates a reconciliation debt on develop. The next `git merge main` into develop will conflict on files both sides touched. Resolve by taking main's version wholesale; this is git-flow's known cost of squash.

### 15. "Evil merges" 🟧
Git's 3-way merge can produce surprising results where a line removed on one side silently reappears on the other after merge, because the base commit didn't have the line. **Always review merge results line-by-line before committing.** One case-study project nearly shipped a `release-as: X.Y.Z` line that had been removed on `main` but reappeared after a `main`-to-`develop` merge.

### 16. `bash -c` + `export VAR=$(...)` + `set -e` interactions 🟧
`set -e` does NOT abort on failures in command substitution inside variable assignment. `FOO=$(failing-command)` succeeds if the assignment succeeds, even if the subshell failed. Use explicit checks: `FOO=$(cmd) || exit 1`.

### 17. Vite + `import.meta.env.npm_package_version` is unreliable (Track B) 🟧
The value depends on which npm version invoked the build and on the surrounding Vite configuration. A case-study project shipped a release where the live footer displayed `v1.0.0` long after they were on v5.0.
**Fix:** read `package.json` directly with `readFileSync` at config-evaluation time, inject via Vite's `define:`. Deterministic. Always works.

### 18. The Guard That Came Before the Secret (both tracks, bites Track B more) 🟧
A deploy that adds a startup check for a new env var / secret / config / database row must include the step that creates the prerequisite, executed **before** the deploy lands. A case study shipped a startup check for `IP_SALT` that wasn't in the production secrets vault; the container exited, auto-rollback caught it after two retries. Fix was thirty seconds, outage was thirty minutes. See `plan-quality.md` *cross-system ordering.*

### 19. Netlify Edge Function sandbox restrictions (Track B) 🟧
Netlify Edge Functions run in a Deno sandbox stricter than `deno run` locally. **`Deno.readFile()` is blocked.** Code that loads fonts, static assets, or JSON config from the function's own filesystem will fail in production with no clear error — the function crashes silently or returns an opaque 500.
**Fix:** fetch fonts and static assets from a CDN URL at runtime instead of bundling them with the function. Same restriction applies to Cloudflare Workers and Vercel Edge Functions.

## Good to know (🟨)

### 20. Slack `mrkdwn` is not standard Markdown 🟨
`##` headers, `-` bullets, blockquotes — all render as literal text in Slack. Use Block Kit JSON with `header`/`section`/`context`/`fields` blocks and `*bold*` for emphasis. Links are `<url|text>`, not `[text](url)`.

### 21. `sed` delimiter injection on user input 🟨
Any workflow that takes a `workflow_dispatch` input and passes it into a `sed` substitution is vulnerable — a user typing the delimiter character breaks the sub. Pipe is the classic: `inputs.reason="foo | bar"` breaks `sed "s|REPLACE|${{ inputs.reason }}|"`. Use `jq -n --arg` for any JSON construction involving user input.

### 22. Hyphens in wordlists become phrase separators 🟨
If your code does `"-".join(random.choices(words, k=3))` and the wordlist contains hyphenated words like `"drop-down"`, your "three-word phrase" splits into 4 parts instead of 3. Audit any wordlist used for string composition where the join character also appears inside items.

### 23. Supabase edge function deployment latency (Track B) 🟨
`supabase functions deploy` reports success when the code is *uploaded*, not live. A post-deploy verification hitting the function immediately can hit the old version.
**Fix:** include a marker in the new build (version constant, SHA in a header, build timestamp in a JSON response); have the verification wait until the response includes the new marker before declaring the deploy verified.

### 24. `deno.lock` v5 vs Supabase CLI version mismatch (Track B) 🟨
Toolchain version drift between local and CI is the quiet killer. A newer local toolchain produces lockfiles an older CI tool can't parse. Pin the toolchain version explicitly in CI (`actions/setup-node`, `actions/setup-python`, `denoland/setup-deno` with fixed versions); pin it locally too (`.nvmrc`, `.python-version`, `rust-toolchain.toml`); make CI fail loudly if local doesn't match.

### 25. Vitest version sensitivity to Node version (Track B, applies anywhere) 🟨
Your test runner has version sensitivities. One case-study project saw 159 tests go from 7 seconds to 7 minutes after a Node bump, because Vitest 1.6.1 had a 57× slowdown on Node 25. **When CI starts feeling slow, audit toolchain versions *before* refactoring tests.** The runner-vs-runtime compatibility matrix is the first place to look.

## How to use this file

- **Before touching the relevant phase**, read the 🟥 entries for that phase.
- **When a deploy behaves weirdly**, grep this file for the symptom before assuming you have a new bug.
- **After a surprise ships**, add a new entry here and renumber nothing — numbers are stable across the playbook.

## See also

- `pipeline-foundation.md` — the gotchas around git-flow, .dockerignore, VERSION
- `ci-and-release.md` — the gotchas around release-please + tokens
- `deploy-and-health.md` — the gotchas around the deploy script and health endpoints
- `trust-boundaries.md` — the "default direction" rule behind #6
