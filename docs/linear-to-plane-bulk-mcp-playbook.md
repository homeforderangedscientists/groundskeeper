# Linear → Plane Bulk Migration via MCP Playbook

**Owner:** Seth (Home For Deranged Scientists)
**Status:** v1.0 (validated 2026-04-30, dear-tuesday project)
**Companion to:** `linear-to-plane-migration-runbook.md`

The agent-facing operational playbook for finishing a Linear → Plane migration when the native Plane importer leaves a gap. The runbook covers the human-driven Phases 1–5 (PAT generation, importer run, workspace setup); this playbook covers what an agent does when the importer's output is incomplete and you need to bulk-create the missing items via MCP.

If the importer brought everything cleanly, you don't need this playbook. Read Phase 0 first to confirm.

---

## When to use this playbook

Use it when:

- You've run the runbook through Phase 6 (Plane MCP server is connected, `claude mcp list` shows `plane ✓`).
- The Plane Linear importer has run, but a survey of both sides shows the Plane project has materially fewer items than the Linear source.
- You have working access to **both** Linear and Plane MCP servers in the same Claude Code session.

Don't use it when:

- The Plane importer has not yet been run — the runbook's Phase 2 covers that, and re-running the importer is cheaper than bulk MCP creation.
- You only need to migrate one or two items — just create them by hand.
- You're trying to migrate completed/cancelled work — focus on the active backlog. Closed Linear issues stay in Linear archives; bringing them over manually is rarely worth the effort.

---

## Phase 0: Verify the gap is real

Before doing any creation work, confirm the importer actually missed things. Two MCP calls in parallel:

```
mcp__linear__list_issues(project: "<linear-project>", includeArchived: false, limit: 250)
mcp__claude_ai_Plane__list_work_items(project_id: "<plane-project-uuid>", per_page: 100, expand: "state,labels")
```

Both responses are typically large (tens of thousands of characters) and will exceed the model's response budget. Tool results are auto-saved to disk; the calls return file paths. Dispatch two parallel general-purpose subagents to slice the JSON and return compact summaries.

**Subagent A — Linear survey** asks for a CSV: `identifier, state, priority, labels (pipe-joined), parent, title, desc_chars`. Plus top-line counts (total, by state, by priority, distinct labels) and the identifier range.

**Subagent B — Plane survey** asks for: `seq, state, priority, parent (8-char prefix), title, desc_chars`. Plus top-line counts, sequence ID range, whether **any** item has labels populated, and whether **any** item has `external_source` / `external_id` populated. The `external_id` field is critical — the importer stamps it on items it created, which is your only reliable way to dedup against the Linear source UUID.

**Important caveat:** Linear's `list_issues` truncates every description to ~500 characters and appends a `(truncated, use get_issue for full description)` marker. The CSV's `desc_chars` field will report 500 for every row. Don't trust it as the true length — fetch full descriptions per-issue later when actually creating.

Read both summaries and identify:

- Items in Linear but missing from Plane (the migration target list).
- Items in Plane that map to Linear via `external_id` (the importer's bookkeeping — do not duplicate).
- Items in Plane created freshly post-import (no `external_id`) — these are also do-not-duplicate, dedupable by normalized title.

If the gap is empty or trivial, stop here. If it's real, continue.

---

## Phase 1: Configure Plane workspace

Before bulk-creating items, set up the Plane project's metadata. These are one-time operations.

### 1.1 Project description

Plane's `update_project` exposes a `description` field (plain text or markdown). Pull the Linear project's description verbatim and write it back:

```
mcp__linear__get_project(query: "<linear-project>")
mcp__claude_ai_Plane__update_project(project_id: "<plane-uuid>", description: "<linear-description>")
```

Plane's UI renders the description as markdown in most views. No conversion needed.

### 1.2 Label taxonomy

The importer **drops most labels**. After the importer runs, the Plane project usually has zero labels. You need to recreate the taxonomy before bulk-creating items so each new work item can attach the right labels.

Pull the label list from Linear (`list_issue_labels`), then create each in Plane via `create_label`. The full schema needs: `project_id`, `name`, `color` (hex). Decide colors by category (type=blue/red/green, origin=purples, area=greys/cyan, etc.) — the choices are cosmetic, not load-bearing.

**Critical Plane gotcha:** Plane reserves capitalized `Feature` and `Bug` as built-in work-item type names at the workspace level, even when `is_issue_type_enabled: false` on the project. `create_label` with those names returns **HTTP 400 Bad Request** with no descriptive error.

Workaround: use lowercase `feature` and `bug`. Recommend lowercase for all type labels (`improvement` too) for consistency. When you migrate items whose Linear labels were `Feature` / `Bug`, map them to `feature` / `bug` at create time.

**Race condition note:** Creating 16+ labels in a single parallel batch occasionally produces HTTP 400 on the first one or two calls — looks like Plane's label-create endpoint has a small window of contention. Retry the failed ones serially after the parallel batch settles.

Save the resulting `name → UUID` map; you'll need it for every subsequent `create_work_item` call.

### 1.3 States (optional)

The runbook's Phase 4.2 recommends adding `Triage` / `In Review` / `Blocked` states beyond the defaults (`Backlog` / `Todo` / `In Progress` / `Done` / `Cancelled`). For the bulk migration, the **default Backlog state is sufficient** — Linear's open backlog all maps to Plane Backlog, so you can omit the `state` field on `create_work_item` and items land in the project default.

If you want the additional states, add them via `mcp__claude_ai_Plane__create_state` before Phase 2. Include `name`, `group` (one of `backlog`, `unstarted`, `started`, `completed`, `cancelled`), and a `color`.

---

## Phase 2: Bulk-create the missing items

This is the heavy lift. Order is non-negotiable: parents before children.

### 2.1 Tier the items

Sort the missing-from-Plane list into tiers:

- **Tier 1 — Top-level / parentless / epics.** No `parent` UUID on creation. Created first.
- **Tier 2 — Children of Tier 1.** Need the Tier 1 Plane UUIDs to fill `parent`. Created second.
- **Tier 3 — Standalone items not part of any epic** (e.g., V1.1 / future-bet ideas). No parent. Order doesn't matter; bundle them at the end so the parent-resolution logic in Tier 2 has nothing else to compete with.

If your Linear hierarchy is more than two levels deep (sub-sub-issues), extend tiering accordingly. In practice for solo / small-team backlogs, two levels is usual.

### 2.2 Delegate to a subagent

The full bulk-create operation involves:

- 1 `get_issue` per Linear issue (to fetch the un-truncated description).
- 1 markdown→HTML conversion per issue.
- 1 `create_work_item` per Linear issue.
- Tracking the Linear-ID → Plane-UUID map for parent resolution.

For 40+ issues that's 80+ MCP calls plus conversion logic. Doing this in the main session burns context and tool turns. Dispatch a single general-purpose subagent with a complete prompt and let it run end-to-end. The subagent returns only a compact mapping summary.

The subagent prompt needs:

1. **Plane project ID and the label name → UUID map** (so the agent doesn't have to re-discover them).
2. **Linear → Plane priority map**: `No priority` → omit, `Low` → `"low"`, `Medium` → `"medium"`, `High` → `"high"`, `Urgent` → `"urgent"`.
3. **Linear → Plane label name map** (handle the `Feature`/`Bug` lowercase translation explicitly).
4. **The full tiered list of Linear IDs** with parent assignments and any non-default priorities.
5. **Markdown → HTML conversion guidance**: prefer Python's `markdown` library (`pip install --user markdown`); fall back to a regex-based converter if unavailable. The output goes in `description_html`.
6. **Provenance footer to append to every description**:

   ```html
   <p><em>Migrated from Linear HOM-N — original: https://linear.app/&lt;workspace&gt;/issue/HOM-N</em></p>
   ```

   This is the historical paper trail; without it, future readers can't trace a Plane item back to its Linear origin.

7. **A verification step**: after creating, call `list_work_items` with `fields: "id,name,sequence_id"` and confirm the count matches `existing + created`. List the Linear → Plane sequence_id mapping.

8. **Reporting format**: ID-only mapping table + failures + oddities, under ~1500 chars.

A reference subagent prompt is in Appendix B.

### 2.3 Parallelism

For both `get_issue` and `create_work_item`, batch in groups of 8–10 parallel calls. Plane's `create_label` showed contention at 16 parallel; assume similar limits on `create_work_item`. The subagent should serialize batches, not run all 40+ calls at once.

### 2.4 Known content failure modes

Two content patterns will be rejected by Plane's edge (Cloudflare WAF), even though they're benign in context:

- **Shell command snippets that reference secrets**, e.g. `${{ secrets.SUPABASE_DB_URL }}`, `curl -fsSL ... | grep -q "${SHA}"`. The WAF flags these as command-injection / secret-exfiltration patterns and returns HTTP 400 from the create call.
- **Complex code blocks containing template-like syntax** that the WAF can't statically validate.

Workaround: paraphrase the offending content into prose. ("Run a curl health check on the homepage and grep for the rev SHA.") The substantive intent is preserved; the verbatim shell strings are lost. **Note in the migration report which Linear issues had this happen** so a human can reconcile against the original Linear bodies if the verbatim commands matter later.

Other content quirks to watch for and strip before send:

- Linear's `<issue id="..."` cross-reference HTML tags (the rich-text Linear-specific markup). Strip to plain `HOM-N` text — it'll still be searchable.
- Indented fenced code blocks under list items. Python's `markdown` library renders these inconsistently; rewrite as a separate top-level code block if accuracy matters.

### 2.5 What you can't preserve

The Plane MCP's `create_work_item` does not accept `created_at` or `created_by`. Every migrated item will show today's date and the migrating user's name as creator. This is irreversible. The provenance footer (above) is your only mechanism for preserving original creation context — make sure the subagent appends it without exception.

Comments and attachments are also not part of this playbook's scope. Plane's `create_work_item_comment` exists, but porting Linear comment threads is a separate exercise (rarely worth it for a solo backlog).

---

## Phase 3: Verify

After the subagent reports success, do a top-level count check from the main session:

```
mcp__claude_ai_Plane__list_work_items(project_id: "<plane-uuid>", per_page: 100, fields: "id,name,sequence_id")
```

Expected count: `(items already in Plane before bulk-create) + (items created by subagent)`. If the count matches and the sequence IDs are contiguous, the migration succeeded structurally.

For tonal / content verification, spot-check 3–5 items in the Plane UI: rich text rendering, label attachment, parent relationship, priority. Open one of the items the subagent flagged as "sanitized" (Phase 2.4) and confirm the prose version is clear enough to act on.

---

## Phase 4: Documentation tail

After the items are migrated, three things drift out of sync and need updating in the same session — otherwise they cause real friction the next time an agent works in the project.

### 4.1 Per-project CLAUDE.md

Add an `## Issue tracking` section. The runbook's Phase 8 has a template; tailor it to the actual Plane project state. Specifically:

- Project name as it appears in Plane (may differ from the Linear name).
- Project identifier (the 10-char truncated form Plane assigns — e.g., `DEARTUESDA`, not `DEAR`).
- Default state (Backlog if you didn't add Triage in Phase 1.3).
- The lowercase-label gotcha for `feature` / `bug` / `improvement`.
- A migration note: old `<LINEAR-PREFIX>-N` references in PR descriptions, code comments, and migrated work-item bodies are historical and won't resolve as live links. Tell future agents to search by title.

Place the section near other workflow-mechanics sections (commits, branches, file conventions). Don't bury it under philosophy / corpus / classifier discussion.

### 4.2 Auto-memory

The auto-memory system has typed entries that may reference Linear by name or carry Linear IDs. After migration:

- **Replace `feedback_*_linear*` files with `feedback_*_plane*`** (write new, delete old, update `MEMORY.md` index pointer). The behavioral lesson is preserved ("backlog goes in tracker, not scratch files"); only the tracker name changes.
- **Replace `reference_linear_project*` with `reference_plane_project*`**. The new file should record: project UUID, workspace UUID, MCP server name, the state UUIDs, the label name → UUID map, and the **Plane gotchas section** (the lowercase-label rule, the WAF rejection patterns, the importer-drops-labels behavior). This becomes the operational reference next time an agent files an issue.
- Update the `MEMORY.md` index lines to point at the new files.

### 4.3 Provenance memory (optional)

Consider writing a short `project_plane_migration.md` memory entry noting the migration date and the HOM-N → DEARTUESDA-N mapping. Helps future agents resolve cross-references in commit messages, PRs, and code comments. Skip if the mapping is short (< 10 items) or if the project's Linear references are sparse.

---

## Phase 5: Decommission posture

The runbook's Phase 9 covers Linear decommission proper (cooling-off, final export, PAT revocation). This playbook's contribution is making sure nothing in the Plane state is ambiguous about which system is now authoritative:

- Plane is read-write. Linear is functionally read-only.
- The two `reference_*` and `feedback_*` memory files now point at Plane.
- The CLAUDE.md `## Issue tracking` section names Plane explicitly.
- Migrated work-item descriptions carry the "Migrated from Linear HOM-N" footer.

If those four things are all true, the project is in a clean post-migration state and Phase 9 of the runbook can proceed on its 1–2 week cooling-off timeline.

---

## Appendix A: Plane MCP gotchas

A consolidated list of behaviors that surprised this playbook's first run. Future agents: add to this list when you discover new ones.

| Gotcha | Symptom | Workaround |
|---|---|---|
| Capitalized `Feature` / `Bug` reserved | `create_label` returns HTTP 400 | Use lowercase `feature` / `bug` |
| Importer drops most labels | Plane labels list near-empty post-import | Recreate taxonomy via `create_label` before bulk-create |
| Importer drops most items | Plane work items count << Linear count | This entire playbook |
| Project identifier truncated to 10 chars | "Dear Tuesday" → `DEARTUESDA` not `DEAR` | Don't pattern-match issue IDs based on first letters |
| WAF blocks shell-snippet descriptions | `create_work_item` returns HTTP 400 on items with `${{ secrets.X }}`, certain `curl`/`grep` lines | Paraphrase to prose; note in migration report |
| `created_at` / `created_by` not settable | All migrated items show today's date and your name | Provenance footer + the migration is one-shot |
| Parallel `create_label` race | First 1–2 of a 16-parallel batch return HTTP 400 | Retry serially |
| `list_issues` truncates descriptions | Every row's description appears 500 chars | Use `get_issue` per item for true content |
| Linear issue cross-reference HTML tags | `<issue id="...">` markup in descriptions | Strip to plain text before markdown conversion |
| Default project state is Backlog | New items land in Backlog, not Triage | Either add Triage state explicitly or accept Backlog |
| Plane editor preserves `description_html` rich content | Sending `description_stripped` only loses formatting | Always send `description_html` for migrated content |

---

## Appendix B: Reference subagent prompt

Adapt for your project. The literal values in `<angle brackets>` are placeholders.

```
You are migrating <N> issues from Linear into a Plane Cloud workspace via MCP tools. Both MCP servers are connected and working — you just need to load schemas and call them.

## What you need to do

For each of the <N> Linear issues listed below:
1. Fetch the full description via mcp__linear__get_issue (the saved list-output truncates to ~500 chars)
2. Convert the description from markdown to HTML
3. Create a corresponding work item in the Plane <PROJECT_NAME> project via mcp__claude_ai_Plane__create_work_item, with proper parent linkage, labels, and priority

Order matters: create the Tier 1 items FIRST (top-level, no parent), then the children (which need parent UUIDs from step 1), then the standalone items.

## Plane target project

- project_id: <UUID>
- Default state is Backlog — omit `state` and items land there.

## Label name → UUID map (Plane)

<paste full table>

Linear's label "Feature" maps to Plane's "feature" (lowercase); same for "Bug" → "bug", "Improvement" → "improvement". Plane reserves capitalized "Feature"/"Bug" as built-in work-item types. Other label names preserve case.

## Priority map

Linear `No priority` → omit / `none`; `Low` → `"low"`; `Medium` → `"medium"`; `High` → `"high"`; `Urgent` → `"urgent"`.

## The <N> Linear issues, in creation order

### Tier 1 — Top-level / epics (no parent, create FIRST, capture UUIDs)
<list>

### Tier 2 — Children of Tier 1 (use Plane UUIDs from Tier 1 as `parent`)
<list with parent assignments>

### Tier 3 — Standalone items (no parent)
<list with priority + label notes per item>

## Markdown → HTML conversion

Use python's `markdown` module if available; if not, install it first (`python3 -m pip install --user markdown`). Pseudocode:

  import markdown
  html = markdown.markdown(linear_description, extensions=['fenced_code', 'tables'])

Pass the result to `description_html` on `create_work_item`.

If `markdown` is unavailable and you can't install, fall back to a basic regex converter that handles: **X** → <strong>, * X lines → <ul><li>, 1. X lines → <ol><li>, `X` → <code>, blank-line paragraphs → <p>, [text](url) → <a>, ## H → <h2>. Don't spend more than 10 minutes on this — basic readability is the bar.

## Footer to append to every issue's description

Append (after a blank line) literally:

  <p><em>Migrated from Linear <ID> — original: <URL></em></p>

…with the actual ID and URL substituted in. This preserves provenance.

## Order of operations

1. Use ToolSearch to load schemas:
   select:mcp__linear__get_issue,mcp__claude_ai_Plane__create_work_item
2. Fetch the Tier 1 descriptions in parallel.
3. Convert + create the Tier 1 items in parallel; record `linear_id → plane_uuid` mapping.
4. Fetch Tier 2 descriptions in parallel batches of 8–10.
5. Convert + create each child with the right `parent` UUID and labels.
6. Fetch + convert + create the Tier 3 items.
7. Verify final count via list_work_items (per_page 100, fields: "id,name,sequence_id"). Confirm titles match.
8. Report back.

## Reporting

Compact summary under 1500 chars:
- Total mapping count (created, failed)
- The full <SOURCE-ID> → <PLANE-ID> table
- Any failures with error messages
- Any oddities encountered (markdown that didn't convert cleanly, parent-link issues, label issues, content rejected by WAF)

Don't include descriptions in the summary. Just the mapping + failures.

## Constraints

- Don't recreate items already in Plane.
- Don't modify labels or project description (handled by the orchestrator).
- Don't archive/cancel/delete anything in Linear.
- If you hit auth errors or HTTP 400s, retry once. If still failing, log and continue with the rest.
- Parallel batch size: 8 at a time (the labels endpoint showed contention at 16+).

Begin.
```

---

## Appendix C: Markdown → HTML conversion notes

Linear's API returns descriptions as markdown. Plane's `create_work_item.description_html` expects HTML. The cleanest conversion is Python's standard `markdown` library:

```python
import markdown
html = markdown.markdown(
    body,
    extensions=['fenced_code', 'tables', 'nl2br'],
)
```

The `nl2br` extension preserves Linear's bare line breaks inside paragraphs. `fenced_code` handles triple-backtick blocks. `tables` handles the rare GitHub-style markdown table.

If the environment lacks the `markdown` package and `pip install --user markdown` is blocked (sandboxed CI, e.g.), a regex-based fallback handles 90% of typical issue bodies:

```python
import re

def md_to_html(text):
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    text = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', text)
    text = re.sub(r'^## (.+)$', r'<h2>\1</h2>', text, flags=re.M)
    text = re.sub(r'^### (.+)$', r'<h3>\1</h3>', text, flags=re.M)
    # crude list handling
    text = re.sub(r'(?:^[*-] .+\n?)+', lambda m: '<ul>' + ''.join(
        f'<li>{line[2:].strip()}</li>' for line in m.group(0).splitlines()
    ) + '</ul>', text, flags=re.M)
    # crude paragraph wrapping
    parts = [p.strip() for p in text.split('\n\n') if p.strip()]
    return '\n'.join(p if p.startswith('<') else f'<p>{p}</p>' for p in parts)
```

The fallback misses nested lists, footnotes, definition lists, and most edge cases. It's good enough for migration-grade fidelity but not pretty. Always prefer the real `markdown` library.

---

## Appendix D: Validation checklist

A run is successful when all of the following are true:

- [ ] Plane work item count = (pre-migration count) + (Linear active backlog count)
- [ ] All migrated items have the provenance footer in their description
- [ ] All Tier 2 items have the correct parent UUID
- [ ] All migrated items have at least one label where the source had labels
- [ ] All migrated items have priority matching the Linear priority (mapped per the table)
- [ ] Spot-check of 3–5 items in the Plane UI: descriptions render readably, labels visible, parent relationship correct
- [ ] Migration report lists every item that needed sanitization (WAF rejection paraphrasing, cross-reference stripping, etc.)
- [ ] Per-project `CLAUDE.md` has an `## Issue tracking` section pointing at Plane
- [ ] Auto-memory `feedback_*_linear*` and `reference_linear_*` files are replaced with Plane equivalents
- [ ] `MEMORY.md` index lines updated

If any are false, the migration is incomplete. Don't claim done until all eight check.
