# Linear → Plane Migration Runbook

**Owner:** Seth (Home For Deranged Scientists)
**Status:** Draft v1.0
**Last updated:** 2026-04-26

A migration runbook for moving issue tracking from Linear to Plane Cloud, including Claude Code MCP integration and ongoing session patterns. Modeled on the late-March 2026 Linear migration runbook so the same workflows carry over with minimal cognitive overhead.

---

## Goals

1. Move all active project backlogs from Linear to Plane Cloud with no data loss.
2. Keep Plane as the system of record for issues, priorities, and kanban work.
3. Wire Plane into Claude Code via MCP so issue creation, prioritization, and state transitions happen during dev sessions without context switching.
4. Establish session patterns analogous to the existing Linear-era ones (start/during/end loops).
5. Preserve the option to self-host later by treating Plane Cloud as the default but groundskeeper-syncable target.

## Non-goals (for this migration)

- Migrating Linear comments threading verbatim. Comments come over, but discussion archeology is not the priority.
- Building bidirectional sync. Linear becomes read-only, then is decommissioned.
- OmniFocus / FocusMiner integration with Plane. Future build, deferred.
- Per-machine MCP config sync — that's groundskeeper's job, not this runbook's.

---

## Preflight checklist

Before starting, confirm:

- [ ] Plane Cloud account is set up and you can reach `https://app.plane.so/<workspace-slug>/`
- [ ] Workspace slug is captured (visible in URL after sign-in)
- [ ] You're a workspace admin in both Linear and Plane (importer requires admin in Plane)
- [ ] Have ~30–60 minutes of uninterrupted time for the import + smoke test
- [ ] No active in-flight work that would be disrupted by issue ID renumbering

**Concept mapping you should internalize before importing:**

| Linear | Plane | Notes |
|---|---|---|
| Workspace | Workspace | 1:1 |
| Team | Project (or workspace, depending on your setup) | Linear teams aren't quite Plane projects. Most solo setups should map each Linear team → Plane project. |
| Project | Module | Linear projects are smaller-scoped initiatives within a team; Plane modules play that role inside a project. |
| Cycle | Cycle | 1:1, sprint-equivalent |
| Issue | Work item / Issue | 1:1 |
| Status | State | Configurable; importer asks for explicit mapping |
| Label | Label | 1:1, but de-duplication is your problem |
| Priority (0–4) | Priority (None/Urgent/High/Medium/Low) | Importer handles this automatically |
| Initiative | (no direct equivalent) | Use a label or a top-level Module if needed |

If your Linear setup followed the late-March runbook (one Linear team per software project, BACKLOG-style task tracking inside each), the **Linear team → Plane project** mapping is the cleanest path.

---

## Phase 1: Generate Linear Personal API key

Plane's importer authenticates against Linear using a Personal API Key (PAT-equivalent).

1. In Linear: **Settings → Account → API → Personal API keys**
2. Click **Create key**
3. Label it `plane-migration-2026-04`
4. Copy the key immediately — Linear will not show it again
5. Store it temporarily in a password manager or shell env var:
   ```bash
   export LINEAR_MIGRATION_KEY="lin_api_..."
   ```
6. Plan to revoke this key after the migration completes (Phase 9).

---

## Phase 2: Run the Plane Linear importer

Plane Cloud has a native Linear importer that brings over issues, states, labels, priorities, users, comments, attachments, and preserves authorship and timestamps. Cycles map to cycles; Linear projects map to Plane modules.

### Steps

1. In Plane: click the `∨` icon next to your workspace name in the sidebar → **Workspace settings**
2. In the right pane, select **Imports**
3. Find the **Linear** section, click **Import**
4. In the **Linear to Plane Migration Assistant**:
   - Paste your Linear Personal API key
   - Select the Linear team(s) to import
   - Map Linear states to Plane states (defaults are usually fine — see mapping below)
   - Confirm user mapping (you'll be the only entry; just confirm your email matches)
   - Review the migration summary
5. Click **Confirm** to start the import

### Recommended state mapping (Linear → Plane)

| Linear state | Plane state | Plane group |
|---|---|---|
| Backlog | Backlog | Backlog |
| Todo | Todo | Unstarted |
| In Progress | In Progress | Started |
| In Review | In Review | Started |
| Done | Done | Completed |
| Canceled | Cancelled | Cancelled |
| Duplicate | Cancelled | Cancelled |

If you used custom Linear states, map each to the closest Plane group. State **groups** are what matter for analytics/cycles; the display name within a group is cosmetic.

### Expected duration

A few minutes for typical solo workspaces. The importer reports progress per project. Keep the browser tab open until it finishes.

---

## Phase 3: Verify imported data

Before touching anything else, audit the import while it's still freshly comparable to Linear.

**Spot-check checklist (per project):**

- [ ] Total issue count matches Linear's count (Linear: project view → count; Plane: project work items → count)
- [ ] At least three random issues have correct title, description, state, priority, labels
- [ ] Comments came through on at least one heavily-discussed issue
- [ ] Cycles imported with correct start/end dates and issue assignments
- [ ] Modules (formerly Linear projects) have the right issues grouped under them
- [ ] Attachments on at least one issue are downloadable

**If something's missing or wrong:**

The importer supports incremental re-runs. Don't manually patch — fix the underlying Linear data or the state mapping, then go to **Workspace settings → Imports → Re-run**.

**Issue ID note:**

Plane re-numbers issues with its own scheme (PROJECT-1, PROJECT-2, …). Linear IDs are preserved as a custom field or in description metadata depending on importer version. Don't expect the old `ABC-123` IDs to work in cross-references — search by title instead.

---

## Phase 4: Workspace setup

Now that data is in, mirror the conventions established during the Linear migration.

### 4.1 Label taxonomy

Re-establish the same label taxonomy from the Linear runbook:

- **Type:** `type:bug`, `type:feature`, `type:chore`, `type:docs`, `type:research`
- **Area:** project-specific, e.g. `area:auth`, `area:api`, `area:ui`
- **Priority labels** are **not needed** — Plane has built-in priority. Drop any imported priority labels.
- **Status modifiers:** `blocked`, `needs-info`, `good-first-task` (kept minimal)

The importer brings Linear labels over directly. Spend ten minutes deduplicating and renaming to the taxonomy. Plane's label management is at **Workspace settings → Labels**.

### 4.2 Workflow states (per project)

Default Plane states cover the workflow from the Linear runbook. If you customized states in Linear (e.g. added `In Review` separately from `In Progress`), recreate that in **Project settings → States** for each project.

Recommended states per project:
- **Backlog** group: `Backlog`, `Triage`
- **Unstarted** group: `Todo`
- **Started** group: `In Progress`, `In Review`, `Blocked`
- **Completed** group: `Done`
- **Cancelled** group: `Cancelled`

### 4.3 Views to create

Same views as the Linear setup, ported over:

- **Active** — `state group ∈ {Started}` — daily working view, kanban layout
- **Up Next** — `state ∈ {Todo}` ordered by priority desc — what to pull next
- **Triage** — `state ∈ {Triage, Backlog}` — weekly review queue
- **Blocked** — `state = Blocked OR label = blocked` — friction tracker
- **This Cycle** — `cycle = active cycle` — sprint focus

Saved views are at the project level. Create them once per active project.

### 4.4 Cycles

If you were running cycles in Linear, the importer brought them over including past completed cycles. Verify the **active cycle** has correct start/end dates and issue assignments. Plane's cycle UI is at **Project → Cycles**.

If you weren't using cycles in Linear (BACKLOG.md era), now's the time to decide: cycles are valuable for the daily/weekly status reporting that FocusMiner generates. Consider running 1- or 2-week cycles per active project.

---

## Phase 5: Generate Plane Personal Access Token

For the Claude Code MCP integration, generate a PAT scoped to your user.

1. In Plane: profile menu → **Settings → API Tokens**
   *(path may vary slightly: alternative is **Workspace settings → API Tokens**)*
2. Click **Add API Token**
3. Label: `claude-code-mcp`
4. Expiration: choose a reasonable horizon (90 days, or "never" if you accept the risk)
5. Copy the token immediately — same as Linear, it won't be shown again
6. Store in shell env (add to `~/.zshrc` or equivalent):
   ```bash
   export PLANE_PAT="plane_api_..."
   export PLANE_WORKSPACE_SLUG="<your-workspace-slug>"
   ```
7. `source ~/.zshrc` to load into the current shell

**Security note:** This is a sensitive credential. Don't commit it. When groundskeeper picks up Plane MCP config, use its existing secret token substitution pattern (`${PLANE_PAT}` references resolved from env at runtime, never persisted in the canonical repo).

---

## Phase 6: Configure Claude Code MCP server

Plane ships an official MCP server (Python + FastMCP, maintained by the Plane team). For Plane Cloud, the recommended path is the hosted remote server with PAT auth — no local process to manage, no Node bridge required.

### 6.1 Add the server (user scope)

User scope means the server is available across all your projects, which matches your usage pattern. Run from a regular terminal (not inside a Claude Code session):

```bash
claude mcp add --transport http --scope user plane \
  https://mcp.plane.so/http/api-key/mcp \
  --header "Authorization: Bearer $PLANE_PAT" \
  --header "X-Workspace-slug: $PLANE_WORKSPACE_SLUG"
```

Note: env vars are resolved at the time the command runs and stored as literals in `~/.claude.json`. For groundskeeper-managed cross-machine sync, prefer the `.mcp.json`-style configuration with `${VAR}` references (see 6.3).

### 6.2 Verify the connection

```bash
claude mcp list
```

You should see `plane` with a `✓ connected` indicator. If you see `✗`:

- Confirm `PLANE_PAT` is set in your shell (`echo $PLANE_PAT`)
- Confirm the workspace slug is correct (no leading slash, lowercase)
- Try `claude mcp remove plane` and re-add
- Check `claude --verbose` output for the actual auth error

### 6.3 Groundskeeper-friendly version (optional, recommended for cross-machine)

Instead of the inline PAT approach, store the config with env var references. In `~/.claude.json` under user-level `mcpServers`:

```json
{
  "mcpServers": {
    "plane": {
      "type": "http",
      "url": "https://mcp.plane.so/http/api-key/mcp",
      "headers": {
        "Authorization": "Bearer ${PLANE_PAT}",
        "X-Workspace-slug": "${PLANE_WORKSPACE_SLUG}"
      }
    }
  }
}
```

Claude Code expands `${VAR}` references at load time, so the actual token never lives in the config file. This is the form groundskeeper should manage.

### 6.4 Alternative: OAuth via mcp-remote

If you'd rather not deal with PAT rotation, OAuth is supported via the `mcp-remote` bridge:

```bash
claude mcp add --scope user plane -- \
  npx -y mcp-remote@latest https://mcp.plane.so/http/mcp
```

First run prompts a browser flow to link your Plane workspace. Trade-off: adds a Node.js dependency layer and the `mcp-remote` process. PAT path is preferred for the groundskeeper-managed scenario.

---

## Phase 7: Smoke test with Claude Code

Open a new Claude Code session in any project directory (so the user-scoped server loads). Run the following prompts in order. All should succeed.

1. **Discovery:**
   > List my Plane projects.

   Expected: enumerates your projects (FocusMiner, groundskeeper, WFD, etc.).

2. **Read:**
   > Show open issues in FocusMiner sorted by priority, then state.

3. **Create:**
   > Create a test issue in FocusMiner titled "MCP smoke test — please delete" with description "Verifying Plane MCP integration." Set priority to Low.

4. **Update:**
   > Move that smoke-test issue to In Progress.

5. **Comment:**
   > Add a comment to that issue: "Smoke test passed."

6. **Close:**
   > Move the smoke-test issue to Cancelled.

If all six work, the integration is live. If any fail, check `/mcp` inside the session for connection status and look at the specific tool error message — most failures are auth/scope issues caught at this stage.

---

## Phase 8: Per-project CLAUDE.md updates

Each project's `CLAUDE.md` should document the Plane mapping so Claude Code knows where issues live for that project.

### Template addition (paste into each project's `CLAUDE.md`)

```markdown
## Issue tracking

- **System of record:** Plane Cloud (`https://app.plane.so/<workspace-slug>/`)
- **Project:** <PROJECT_NAME_IN_PLANE>
- **Active cycle:** see Plane → Cycles
- **MCP server:** `plane` (user-scoped, connect via PAT)

When asked to create, update, or query issues for this project, use the Plane MCP server. Default to:
- Creating issues in the **Triage** state unless context indicates otherwise
- Setting priority based on explicit cues in the request, otherwise leaving as None
- Adding `type:*` and `area:*` labels per the workspace label taxonomy
- Linking to relevant code paths in the issue description when known
```

### Session patterns (mirror the Linear-era loops)

**Session start (per project working session):**
> Pull the active cycle for <project> in Plane. Show me what's In Progress and what's Up Next sorted by priority.

**During work — capture incidental issues:**
> Add a Plane issue to <project>: <title>. Type: bug. Description: <what you noticed>. Priority: <P>. State: Triage.

**During work — close out completed work:**
> Mark Plane issue <PROJECT-N> as Done. Add a comment summarizing what shipped.

**Session end — status update:**
> Generate a session status update from Plane: list everything I moved to Done in <project> today, plus what's currently In Progress, plus any new issues I created.

This last pattern is the natural seam where FocusMiner-style daily/weekly reports could pull from Plane in the future. Logging it here for when that build comes up.

---

## Phase 9: Decommission Linear

**Don't rush this.** Run a 1–2 week cooling-off period where Plane is the source of truth but Linear remains read-only as a safety net.

### 9.1 Cooling-off (Day 0 to Day +7)

- Use Plane exclusively for new work
- If you find yourself in Linear, ask why — note the gap in this runbook
- Re-run the Plane importer once at end of week 1 to catch anything you accidentally created in Linear

### 9.2 Final export (Day +7)

Even after cutover, snapshot Linear data to cold storage:

1. Linear: **Settings → Workspace → Import/Export → Export data**
2. Save the CSV to your archives (recommend: a dated folder in your projects backup location)
3. Verify the CSV opens and has the columns you'd expect (`ID, Team, Title, Description, Status, …`)

### 9.3 Revoke and cancel (Day +7 to +14)

- [ ] Revoke the `plane-migration-2026-04` Linear API key
- [ ] Remove `LINEAR_MIGRATION_KEY` from your shell env
- [ ] Cancel/leave the Linear workspace (or downgrade to free if you want to keep it as a museum)
- [ ] Update the Linear migration runbook to mark it superseded by this document

### 9.4 Update groundskeeper

- [ ] Add Plane MCP config to the canonical repo (with `${PLANE_PAT}` reference, not the literal)
- [ ] Add `PLANE_PAT` and `PLANE_WORKSPACE_SLUG` to the secrets manifest
- [ ] Verify `groundskeeper sync` provisions Plane MCP correctly on a second machine
- [ ] Remove any Linear MCP config from the canonical repo

---

## Appendix A: Tool reference for Claude Code Plane sessions

These are the MCP tools the Plane server exposes (from the official `plane-mcp-server`). Useful for crafting precise prompts:

- `list_projects` — enumerate workspace projects
- `create_project` — new project
- `list_issues` — query work items with filters (project, state, priority, labels)
- `create_issue` — new work item
- `update_issue` — mutate state, priority, labels, description
- `add_issue_comment` — append comment
- `list_cycles`, `create_cycle` — sprint management
- `list_modules`, `add_module_issues` — group issues under a module

You don't need to invoke these by name; Claude will pick the right one from natural-language prompts. They're listed here for the inevitable moment of debugging "why didn't it find that issue."

---

## Appendix B: Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `claude mcp list` shows `plane ✗` | PAT missing or expired | Verify env var, regenerate token in Plane, re-add server |
| MCP tools work but return empty results | Wrong workspace slug | Check `X-Workspace-slug` header matches the URL slug |
| Importer reports auth error on Linear side | Linear API key revoked or wrong scope | Regenerate the personal API key in Linear |
| State mapping looks wrong post-import | Mapping config error during import | Re-run the importer with corrected mappings; existing issues are updated, not duplicated |
| Issues created via MCP land in wrong state | Default state in Plane project differs from expectation | Set the default state in **Project settings → States** |
| Tool calls timeout | Network or `mcp.plane.so` slow | Retry; if persistent, file with Plane support |
| Free plan suddenly shows seat warning | New collaborator added | Free tier supports 12 seats; should be fine for solo |

---

## Appendix C: What carries over from the Linear runbook

The following conventions established in the late-March 2026 Linear migration runbook apply unchanged in Plane:

- Label taxonomy (`type:*`, `area:*`, status modifiers)
- Workflow state structure (Backlog → Todo → In Progress → In Review → Done, with Blocked branch)
- Per-project saved views (Active, Up Next, Triage, Blocked, This Cycle)
- Session start/during/end patterns
- One-Plane-project-per-software-project structure (formerly one Linear team per project)

What changes:

- MCP server (Linear MCP → Plane MCP, this document Phase 6)
- Issue ID format (`ABC-123` → `PROJECT-N`, Plane numbering)
- "Linear team" terminology → "Plane project"
- "Linear project" terminology → "Plane module"
- GitHub linking: Plane has a native GitHub integration that syncs issues and PRs and auto-links branches/commits — set this up per project under **Project settings → Integrations**

---

## Open questions (for follow-up)

- [ ] Decide whether to enable Plane's GitHub integration immediately or defer (low cost; recommend enabling)
- [ ] Determine cycle length default — 1 week vs 2 weeks per active project
- [ ] Confirm whether FocusMiner v1 should pull Plane data, or whether that's a v2 build
- [ ] Evaluate whether to self-host Plane CE eventually (current answer: not yet, revisit at 6-month mark)
