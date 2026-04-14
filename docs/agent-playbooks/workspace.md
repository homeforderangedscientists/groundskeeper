# The Workspace

> Where each kind of project knowledge belongs. Five layers, one failure mode: the wrong thing in the wrong layer, quietly rotting.

## The layers

| Surface | Purpose | Changes | Examples |
|---|---|---|---|
| **CLAUDE.md** | Stable project facts loaded on every cold start | Rarely (monthly) | Tech stack, architecture layers, agent routing, essential commands |
| **Memory** | Live state, corrections, preferences | Per conversation | Current sprint ID, "next time, please…", user prefs |
| **Skills** | Procedures to *execute* (not remember) | When the procedure changes | Release flow, retro writing, deploy, sprint refresh |
| **Hooks** | Non-negotiables the harness enforces | When the rule changes | Pre-commit checks, sound notifications, format-on-save |
| **settings.json** | What I *can* do — permissions, tool access | When tooling changes | Allowed-tool lists, hook registrations, permission modes |

Each row is a layer. The failure mode is always *the wrong thing in the wrong row*. Write a procedure as a CLAUDE.md paragraph and I'll read it and skip it. Write a permission rule in CLAUDE.md instead of `settings.json` and I can reinterpret it under pressure. Put live state in CLAUDE.md and it rots invisibly.

## Rules

### Your pipeline is a precondition, not a feature
**Why:** Every discipline in these playbooks silently assumes CI catches mechanical failures quickly and deploys are automated. When that breaks, the human gets pulled into the mechanics layer and the craft layer goes dark.
**How to apply:** If the pipeline is flaky, fix it before adopting the other disciplines. Health endpoints that report real dependencies + build SHA, blue-green deploys with automated rollback, lint/test/scan on every push, conventional commits, Docker parity dev↔prod. *You are done when the pipeline is boring.* See `pipeline-foundation.md` and `deploy-and-health.md`.

### CLAUDE.md is for facts that don't change. Memory is for facts that do
**Why:** CLAUDE.md is loaded every conversation. A stale line there is invisible — it looks like truth forever. A stale memory line is one update away from being fixed.
**How to apply:** Architecture, tech stack, conventions, file layout → CLAUDE.md. Sprint state, current cycle ID, the gotcha you learned this afternoon → memory.

### Skills are for procedures. CLAUDE.md is for facts
**Why:** A multi-step procedure buried in CLAUDE.md is ambient noise — I read it and then don't follow it because it wasn't invoked. Skills are executed on purpose, step by step.
**How to apply:** If you find yourself writing "always do X when Y" in CLAUDE.md more than twice, stop and promote it to a skill. Release flow, deploy flow, retro writing, sprint refresh — all skill material.

### Hooks make automation non-negotiable
**Why:** Anything you ask me to "remember to do" will fail at least once, and you won't notice when it does because I'll confidently proceed as if it happened.
**How to apply:** Sound notifications, pre-commit checks, format-on-save, post-response cleanup — hook material, not prompt material. If the rule is "this must happen every time," the harness must be the thing that makes it happen.

### `settings.json` configures the harness. CLAUDE.md configures the agent
**Why:** Settings determine what I *can* do. CLAUDE.md tells me what I *should* do. Mix them and you get behavioral rules the harness can't enforce and permission rules I can't read.
**How to apply:** Permission modes, allowed-tool lists, hook registrations, MCP server config → `settings.json`. Project context, conventions, behavioral norms → CLAUDE.md. Never put `"never run git push --force"` in CLAUDE.md — exclude it at the harness layer where "can't" is enforced by the tool, not by politeness.

## See also

- `memory-and-skills.md` — what goes in which memory type, when to promote to a skill
- `the-loop.md` — first conversation discipline
