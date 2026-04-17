---
name: failure-modes-diagnosis
description: Use when the agent-human partnership feels off — repeated wrong fixes, slop accumulating, drift, verification theater, or unexplained parallel-agent conflicts. Six failure shapes and a rescue protocol for when the partnership has broken.
---

# Failure Modes Diagnosis

Load `~/.claude/playbooks/failure-modes.md` for the full diagnosis and rescue protocol.

Every failure below has a human-side twin. **Check upstream before blaming the model.**

## The six failure shapes

### 1. Loops on the same wrong fix
**Shape:** two or more attempts at the same problem, each confidently asserted, each producing the same broken result. **Fix:** stop re-attempting; return to diagnosis. The premise is wrong, not the execution. *Human twin:* accepting each "I've fixed it" without running the thing.

### 2. Produces slop
**Shape:** code that compiles and tests pass but the shape is wrong — wrong abstraction, wrong file, wrong scope. **Fix:** shorten the leash. Small increments, tight checkpoints, re-align on what "done" looks like. *Human twin:* trust accumulated past the evidence window.

### 3. Can't be trusted with anything important
**Shape:** slop + silent drift have compounded; every output now gets audited line-by-line. **Fix:** reset scope. Give small, verifiable tasks. Rebuild trust through small wins before attempting the hard thing again. *Human twin:* skipped the retro that would have caught the drift earlier.

### 4. Confidently lies about state
**Shape:** "tests pass," "deploy succeeded," "bug fixed" — without the command output to back it up. **Fix:** reintroduce the evidence ritual. Every claim followed by the command and its output. `superpowers:verification-before-completion` enforces this. *Human twin:* accepted prose-summaries as evidence for long enough that the agent learned it was sufficient.

### 5. Drifts from intent mid-task
**Shape:** started doing X, now doing Y with no announcement. **Fix:** correct in message 2, not message 50. Every correction is nearly free when caught early and enormously expensive when caught late. *Human twin:* noticed the drift in message 3 and let it slide.

### 6. Partnership architecture is wrong
**Shape:** agents are good but the result is bad — merge conflicts, races, interleavings, shared-state bugs. **Fix:** change the shape, not the prompts. If file boundaries aren't clear, draw them. If worktrees are being used as a coordination strategy, use file-boundary parallelism inside a single worktree instead. See `parallel-agents-topology`. *Pin: fix the topology, not the discipline.*

## Every failure has a human antecedent

- You skipped the brainstorm because the fix "felt obvious" — twin to *loops on the same wrong fix*.
- You skipped the retro because "nothing to learn" — twin to *produces slop*.
- You accepted "tests pass" as evidence because the verify-and-paste ritual is boring — twin to *confidently lies about state*.
- You promoted a correction to a CLAUDE.md note instead of a skill because a note is five seconds — twin to *can't be trusted with anything important*.

The antecedent is almost always cheaper to fix than the symptom, and fixing the symptom without the antecedent just reschedules the failure.

## The rescue protocol

When the partnership is in the bad shape — trust collapsed, slop accumulating, loop skipped, retro empty — work the protocol in the playbook in order. Don't jump ahead. `~/.claude/playbooks/failure-modes.md` has the full sequence.
