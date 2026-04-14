# Verification Before Completion

> **Load-bearing.** Paired with `retros.md`. Every other discipline in these playbooks fails the same way when verification is sloppy: confidently, in production.

## Rules

### "Tests pass" is not "feature works." Verify the feature
**Why:** Tests verify the code under test, not the user-visible behavior of the system. A suite can be 100% green while the feature is broken because no test exercised the wire between the parts.
**How to apply:** For UI work, open a browser. For deploy work, hit the live endpoint. For data work, query the data. For API work, read the response *body*, not just the status code. If "done" lives behind a screen, look at the screen. **Infrastructure migrations** specifically need tests on the *interaction* pipeline, not just the *data* pipeline — when you swap a foundation layer (data layer, auth layer, router, state management), the test gap is always on the interaction side because the unit tests were written for the old substrate's assumptions.

### Evidence before assertions. Always
**Why:** An agent that confidently says "the build passes" without showing the output is an agent you cannot trust. Verification is a habit, not a claim. Accept "I ran the tests and they passed" as evidence and you've trained the agent that prose is sufficient — and prose is what hallucinations look like.
**How to apply:** Never claim success without producing the verification command *and* its actual output, pasted in. `pytest` plus the green dots is evidence. "Tests pass" is not. If I say "deploy succeeded," the next line had better be a `curl` against the live URL with the response body attached.

### Evidence of the *wrong claim* is still theater
**Why:** A green check is only evidence for the specific claim it tests. "180 unit tests passed" is evidence that 180 unit tests passed — not that the feature works, the component renders, the cache-hit path fires, or the touch event reaches the handler. Evidence that answers the wrong question is dangerous precisely because it *looks* authoritative.
**How to apply:** Before accepting any successful output, name the claim the evidence actually supports. If that claim isn't "the feature works," you haven't verified the feature. A unit test proving the data layer is correct is not proof that the cache-hit path fires; run the cache-hit path in a real browser.

### Verify in the environment that matters
**Why:** Local-passing + CI-failing is the single most expensive failure mode in most projects' histories. Cache backends differ. Databases differ. Node versions differ. Serialization paths differ. "Local green" only proves the code works against the specific lies your laptop tells.
**How to apply:** If the change touches anything that runs in CI or production, run it there before claiming done. If you can't reproduce CI's environment locally, that's the bug — fix the parity gap, then verify. This is the same rule the DevOps playbook pins as "dev == prod." See `deploy-and-health.md`.

### Health checks must check health, not "is the process running"
**Why:** A 200 from `/health` doesn't mean the database is reachable — it means nginx is awake. A health check that can't detect a downed dependency is a status check cosplaying as a health check, and the worst thing it can do is succeed during an outage.
**How to apply:** Health checks must verify actual dependencies (DB ping, Redis ping, downstream reachability) and return them in the response body, with the build SHA, so verifiers can confirm they hit the right endpoint and the right version. **Split status from health** — a lightweight `/health` for load balancers, a full `/api/v1/health` for deploy verification. See `deploy-and-health.md`.

## The verification checklist (before claiming done)

1. **Name the claim.** "I'm claiming that [specific user-visible behavior] works."
2. **Pick the evidence that actually tests that claim.** Unit tests? Integration tests? A real browser session? A curl against prod?
3. **Run it in the environment the claim is about.** Local for local claims, CI for CI claims, production for production claims.
4. **Paste the command and its output.** Not a summary. The actual output.
5. **Compare the output to the claim.** Does it prove the claim, or something adjacent?
6. **If step 5 is "adjacent," go back to step 2.**

## Pins

- *If you didn't open the thing and use it, you didn't verify it.*
- *The verification command and its output, pasted, or it didn't happen.*
- *If your local doesn't run what CI runs, your local green is a lie.*
- *If your health check can't say what's broken, it can't say anything's healthy.*
- *The right evidence for the wrong claim is still theater.*
- *When the second fix fails the same way as the first, stop fixing and start diagnosing.*

## See also

- `retros.md` — paired chapter; verification catches the failure, retros convert it into a rule
- `deploy-and-health.md` — health endpoint structure
- `failure-modes.md` — what to do when you notice the verification gap mid-loop
