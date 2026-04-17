---
name: devops-pipeline-foundation
description: Use when bootstrapping a new project or inheriting one without a boring pipeline — git-flow, conventional commits, .gitignore/.dockerignore, a VERSION file, multi-stage Dockerfiles, compose parity with production. Makes the mechanics layer boring so the engineer+agent partnership can happen on top.
---

# DevOps Pipeline Foundation

Load `~/.claude/playbooks/pipeline-foundation.md` for the full checklist and reasoning.

## Apply when

- Bootstrapping a new project
- Inheriting a project without git-flow / conventional commits / a VERSION file
- Container work is about to start ("we'll Dockerize this")
- A partnership rule from the engineer+agent playbooks isn't working because the mechanics layer underneath is flaky

## Why this skill exists

Every rule in the engineer+agent playbooks silently assumes the pipeline is boring. If CI takes 40 minutes, "frequent commits" inverts. If the Dockerfile rebuilds everything on every change, "verify in CI" becomes too expensive to do. Fix the foundation first.

## Core elements

- **git-flow** with trunk-based development and protected `main`
- **Conventional commits** (`feat:`, `fix:`, `docs(scope):`, etc.) so commit history is grep-able and release tooling works
- **`.gitignore` and `.dockerignore`** — keep secrets and build artifacts out of version control *and* out of container images
- **`VERSION` file** at the repo root, single source of truth, read by CI and by the app at runtime so deploy verification can confirm SHA+version match
- **Multi-stage Dockerfile** — build stage, test stage, final minimal stage. Never ship the build toolchain.
- **compose parity** — `docker-compose.yml` runs the same stack as production (same service names, same network topology, same env vars) so local == CI == prod.

See the playbook for the full list, including pre-commit hooks, secret scanning, and the "fast pipeline is a pre-condition" rule.
