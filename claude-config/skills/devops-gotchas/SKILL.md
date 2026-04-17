---
name: devops-gotchas
description: Use when a DevOps problem has the smell of a specific known trap — bash script buffering, GitHub Actions token scope, Slack mrkdwn vs Markdown, docker port mappings, build-arg plumbing. These are the traps that burn hours if you don't recognize them immediately.
---

# DevOps Gotchas

Load `~/.claude/playbooks/devops-gotchas.md` for the full catalogue with worked fixes.

## Apply when

- A DevOps problem smells specific — a Slack message renders wrong, a GitHub Action fails authentication, a docker-compose build arg isn't taking, a bash pipeline swallows errors
- You've spent more than 15 minutes on a "weird" infrastructure issue
- Onboarding someone else and want to warn them about the local traps

## Greatest hits (see playbook for the full list and fixes)

- **Bash script buffering** — `set -euo pipefail` is the minimum. `set -x` for debugging. `PIPESTATUS` for pipeline error propagation. `exec` for log redirection.
- **GitHub Actions token scope** — `GITHUB_TOKEN` defaults to read-only for external PRs. Release automation and cross-repo actions need `permissions:` blocks or a PAT.
- **Slack `mrkdwn` ≠ Markdown** — `*bold*` not `**bold**`, `<url|text>` not `[text](url)`. Test in Slack's message builder, not in your editor.
- **Docker port mappings** — `-p 8080:80` means host:container, not the other way. `EXPOSE` in the Dockerfile is documentation, not a port-publish.
- **Docker build-arg plumbing** — `ARG` must appear *after* the `FROM` it scopes to. Values set in `docker-compose.yml` under `build.args` only reach `ARG` declarations, not `ENV`. To make a build-arg available at runtime, declare `ARG X` then `ENV X=$X`.
- **compose vs docker run parity** — `docker-compose` sets different defaults than `docker run` (hostnames, networks, restart policy). Test the compose path, not the docker-run path.
- **Secrets in env files** — `.env` files are tracked in `.gitignore` *and* `.dockerignore` *and* reviewed on every new repo.

## Pattern

Each gotcha in the playbook is named, shown with a minimal repro, diagnosed, and fixed. When you hit a new one, add it to the playbook with the same shape — the point of this file is accumulated scar tissue, and the accumulation only works if the next surprise gets written down.
