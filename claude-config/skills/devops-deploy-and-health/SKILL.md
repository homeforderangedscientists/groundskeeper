---
name: devops-deploy-and-health
description: Use when wiring up deploys, writing health endpoints, or verifying a release in production — blue-green deploy, preflight checks, the /health vs /api/v1/health split, deploy manifest, smoke tests. Makes deploys verifiable rather than hopeful.
---

# DevOps Deploy and Health

Load `~/.claude/playbooks/deploy-and-health.md` for the full playbook.

## Apply when

- Setting up a deploy pipeline for the first time
- Writing or fixing a health endpoint
- A deploy succeeded but the feature is broken
- You need to verify a specific version is running in production

## Two-endpoint health split

Load-balancers and deploy verification have different needs. Give them different endpoints:

- **`/health`** — lightweight liveness. Returns 200 if the process is up. Used by load balancers and orchestrators for routing decisions. Cheap, fast, called every second.
- **`/api/v1/health`** — full health. Returns DB ping, Redis ping, downstream reachability, **build SHA**, **VERSION**. Used by deploy verification to confirm the right code is running against working dependencies. Called by humans and CI.

A single endpoint that tries to serve both loses in both directions — too heavy for the load balancer, too light for the deploy check.

## Blue-green deploy pattern

1. **Preflight** — verify the new image runs, env vars exist, secrets resolve, migrations are ready. Fail here before taking traffic.
2. **Deploy green alongside blue** — both versions running, only blue gets traffic.
3. **Health-check green** — hit `/api/v1/health` on green directly. Verify build SHA matches what you just deployed. Verify dependencies are reachable.
4. **Cut traffic to green** — load balancer flip.
5. **Smoke test from outside** — hit the public URL with a known-good request. Read the response *body*. Verify user-visible behavior.
6. **Drain and remove blue** — only after smoke test passes.

A deploy that skips step 5 is a deploy that claims success based on internal evidence. See `verification-semantics`.

## Deploy manifest

Every deploy produces a manifest: the image SHA, the VERSION, the commit SHA, the env target, the timestamp, and the user who deployed. Written to a known location (S3, git tag, release artifact). Without it, "what's running in prod" is a guess.

## Smoke tests

A smoke test is one or two requests that exercise the golden path end-to-end. Not a full suite — just enough to catch "the deploy succeeded but the wire is disconnected." Run them after every deploy, against the real URL, in the real environment.
