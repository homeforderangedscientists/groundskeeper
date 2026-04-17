---
name: verification-semantics
description: Use when about to claim a feature works, a deploy succeeded, a bug is fixed, or tests pass — adds tests-≠-feature reasoning, environment-that-matters check, health-check semantics, and the infrastructure-migration gap. Layers on top of `superpowers:verification-before-completion` (which enforces the gate) with the semantics of WHAT to verify.
---

# Verification Semantics

Load `~/.claude/playbooks/verification.md` for the full reasoning.

`superpowers:verification-before-completion` enforces the gate: run the command, paste the output, don't claim done without evidence. This skill adds the *semantics* — what counts as the right evidence for the claim you're making.

## The semantics layer

### "Tests pass" is not "feature works"
Tests verify the code under test, not the user-visible behavior of the system. A suite can be 100% green while the feature is broken because no test exercised the wire between the parts. For UI work, open a browser. For deploy work, hit the live endpoint. For data work, query the data. For API work, read the response *body*, not just the status code.

### Evidence of the *wrong claim* is still theater
A green check is only evidence for the specific claim it tests. "180 unit tests passed" is evidence that 180 unit tests passed — not that the feature works. Before accepting any successful output, name the claim the evidence actually supports. If that claim isn't "the feature works," you haven't verified the feature.

### Verify in the environment that matters
Local-passing + CI-failing is the single most expensive failure mode. Cache backends differ. Databases differ. Node versions differ. "Local green" only proves the code works against the specific lies your laptop tells. If the change touches anything that runs in CI or production, run it there before claiming done. If you can't reproduce CI's environment locally, that's the bug — fix the parity gap first.

### Health checks must check health
A 200 from `/health` doesn't mean the database is reachable — it means nginx is awake. Health checks must verify actual dependencies (DB ping, Redis ping, downstream reachability) and return them in the response body with the build SHA. Split status from health: lightweight `/health` for load balancers, full `/api/v1/health` for deploy verification.

### Infrastructure migrations need interaction-pipeline tests
When you swap a foundation layer (data layer, auth layer, router, state management), the test gap is always on the interaction side because the unit tests were written for the old substrate's assumptions. Run the user-visible path in a real environment after any foundation change.

## The checklist before claiming done

1. **Name the claim.** "I'm claiming that [specific user-visible behavior] works."
2. **Pick the evidence that actually tests that claim.** Unit tests? Integration tests? A real browser session? A curl against prod?
3. **Run it in the environment the claim is about.** Local for local, CI for CI, prod for prod.
4. **Paste the command and its output.** Not a summary. The actual output. (`superpowers:verification-before-completion` enforces this.)
5. **Compare the output to the claim.** Does it prove the claim, or something adjacent?
6. **If step 5 is "adjacent," go back to step 2.**
