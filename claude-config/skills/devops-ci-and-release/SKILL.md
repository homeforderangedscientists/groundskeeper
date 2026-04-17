---
name: devops-ci-and-release
description: Use when setting up CI, fixing CI failures, or wiring up release automation — test/lint/scan gates, actionlint, Docker build validation, release-please or similar. Turns CI into a gate that blocks bad merges rather than theater that rubber-stamps them.
---

# DevOps CI and Release

Load `~/.claude/playbooks/ci-and-release.md` for the full skeleton and rules.

## Apply when

- Setting up CI for a new project
- A CI job is failing and you need to diagnose / fix
- Release automation isn't wired up (manual version bumps, manual changelogs)
- Someone says "just merge it, the CI check is flaky"

## CI as a gate, not theater

Every gate in CI must answer a specific claim and fail loudly when the claim breaks:

- **test** — unit + integration, ideally with race detection if the language supports it
- **lint** — code style, dead code, obvious bugs
- **scan** — secrets, vulnerable dependencies, license violations
- **actionlint** — validates the CI workflow files themselves (catches bash-in-yaml bugs before they hit main)
- **docker build** — if the project ships a container, CI builds it. A Dockerfile that doesn't build is the same as code that doesn't compile.

If a gate is flaky, fix the gate or remove it. A gate people ignore is worse than no gate — it teaches the team that CI is advisory.

## Release automation

- **release-please** (or equivalent) reads conventional commits, generates a release PR, writes the changelog. Merging the release PR cuts the tag.
- **VERSION file** updated automatically on release merge. The app reads it at runtime so deploy verification can confirm it's running the version you just released.
- **Release notes come from commit messages** — which is why `feat:`/`fix:` discipline matters.

## Common traps

- Pinning `actions/*` versions to tags (floating) instead of SHAs (reproducible)
- Running `docker build` in CI but not pushing — the image ran, but the registry doesn't have it
- Release-please can't create PRs without write permissions — `GITHUB_TOKEN` scope is a silent failure mode. See `devops-gotchas` for the full list.
