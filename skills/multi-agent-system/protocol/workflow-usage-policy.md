# Workflow Usage Policy (MAS-02)

Durable per-workflow telemetry in `.ai/context/memory.md` under `### Workflow Usage (MAS-02)`. Complements ephemeral [daily-changelog-policy.md](daily-changelog-policy.md): changelog = *what* changed today; workflow usage = *how* each approved workflow ran over time.

## File paths

| Artifact | Path | Lifetime |
|----------|------|----------|
| Durable bullets | `.ai/context/memory.md` → `### Workflow Usage (MAS-02)` → `## Entries` | Until trimmed (50 entries max) |
| Session scratch | `.ai/context/workflow-sessions/{TASK_ID}.json` | Workflow lifetime only; deleted on finalize or cancel |

Both under `.ai/` (gitignored). Session JSON is **never** copied verbatim to `memory.md`.

## Qualification

Finalize (write memory bullet) only when **all** of:

1. Reviewer output has `Approved: YES` (full or lite)
2. Workflow handoff chain had non-empty `FILES` (code changed)

Skip when:

- Planning-only chains (no source changes)
- Workflow cancelled before Reviewer approval
- Reviewer `Approved: NO` without later approval

Same gate as daily changelog. Coordinator runs `append-daily-changelog.ps1` **then** `finalize-workflow-usage.ps1`.

## Session JSON schema

Ephemeral file: `.ai/context/workflow-sessions/{TASK_ID}.json`

```json
{
  "task_id": "AUTH-12",
  "mode": "LITE",
  "tier": "M",
  "type": "feature",
  "started_at": "2026-07-10T08:14:00+05:30",
  "reviewer_loop_count": 0,
  "debate_used": false,
  "debate_round": 0,
  "steps": [
    {
      "agent": "general-dev",
      "model": "composer-2.5",
      "model_class": "normal",
      "tokens_in": null,
      "tokens_out": null,
      "tokens_source": "unknown",
      "spawn_index": 1
    }
  ]
}
```

| Field | Type | Notes |
|-------|------|-------|
| `mode` | `FULL` \| `LITE` | From handoff / coordinator |
| `tier` | `S` \| `M` \| `L` \| `L+` \| `none` | `none` for full `/mas` without tier |
| `type` | `feature` \| `bugfix` | `bugfix` if chain included bug-fix agent |
| `reviewer_loop_count` | int | Incremented by Coordinator on each Reviewer `Approved: NO` |
| `debate_used` | bool | `true` after debate-synthesizer spawn completes |
| `debate_round` | int | Debate persona rounds completed (max `MAX_DEBATE_ROUNDS`) |
| `steps[].agent` | slug | `planner`, `general-dev`, `reviewer`, etc. |
| `steps[].model` | string | Task `model` param or `default` |
| `steps[].model_class` | `normal` \| `fast` \| `thinking` | Derived — see below |
| `steps[].tokens_*` | int \| null | See token resolution |
| `steps[].tokens_source` | enum | `task_metadata` \| `usage_report` \| `unknown` \| `estimate` |

## Model class derivation

| Rule | `model_class` |
|------|----------------|
| slug contains `thinking` | `thinking` |
| slug contains `fast` | `fast` |
| `default` or no model param | `normal` |
| else | `normal` |

Scripts derive when `-ModelClass` omitted on `record-workflow-step.ps1`. Prefer explicit `-ModelClass` from [spawn-model-policy.md](spawn-model-policy.md) resolution at spawn time.

## Memory bullet format

Under `### Workflow Usage (MAS-02)` → `## Entries`:

```markdown
- **{TASK_ID}** ({yyyy-MM-dd}, {type}, {mode}/{tier}): chain={agent1→agent2→…}; models={model1},{model2},…; classes={class1},{class2},…; tokens={total|unknown|est~{tier}}
```

**Example:**

```markdown
- **MAS-02** (2026-07-10, feature, LITE/L): chain=planner→general-dev→reviewer; models=default,default,composer-2.5-fast; classes=normal,normal,fast; tokens=unknown
```

**Upsert:** replace line matching `**{TASK_ID}**` (same as daily-changelog). Reviewer rejection loops update the same line on re-finalize.

**Regex for upsert:** `^- \*\*{TASK_ID}\*\*`

Date in bullet: local `yyyy-MM-dd` at finalize time.

## Token resolution (Coordinator per step; finalize aggregates)

Per step, in order:

1. Task tool return metadata (if Cursor exposes `usage` / token fields — parse defensively; v1 may be absent)
2. Subagent `## Usage Report` `Tokens: in/out` (full `/mas` only)
3. Else `tokens_source: unknown` for that step

At finalize:

1. If all steps have `tokens_in` and `tokens_out` → `tokens={sum}` (total in+out)
2. If any step unknown and `mode=LITE` with known `tier` (not `none`) → `tokens=est~{tier}` (estimate label, not measured)
3. Else `tokens=unknown`

v1 must not fail finalize when tokens absent.

## Subagent `## Usage Report` (optional, full `/mas` only)

```
## Usage Report

Model: composer-2.5-fast
Class: fast
Tokens: 45000/1200 | unknown
```

Place before `DONE`. **MAS Lite subagents: do not emit** (Coordinator records model from spawn params only).

Coordinator treats Usage Report as **supplement** when Task metadata absent; never required for `DONE`.

## Single writer

**Coordinator only** (full `/mas` and `/mas-lite`). Specialists never write workflow usage bullets or session JSON directly.

| When | Action |
|------|--------|
| `TASK_ID` assigned, before first spawn | `init-workflow-session.ps1` |
| Each Task returns `DONE` | `record-workflow-step.ps1` (+ parse Usage Report / Task metadata) |
| Reviewer `Approved: YES` + qualified (`FILES` non-empty) | `append-daily-changelog.ps1` then `finalize-workflow-usage.ps1`; optional `token-auditor` spawn (full `/mas` only) |
| Reviewer `Approved: NO` (continue chain) | no finalize; session kept; re-record replaces step for same agent |
| Workflow cancelled / user abort | `cancel-workflow-session.ps1` |
| Planning-only (no `FILES`) | no finalize |
| `finalize` success | `trim-workflow-usage.ps1` then `trim-memory.ps1` if ≥280 lines |

### Summary resolution (finalize `-Summary`, optional ≤80 chars)

1. Reviewer `## Daily Summary` (truncate 80)
2. Else `FIX_SUMMARY`
3. Else `CHANGE_SUMMARY`
4. Else handoff `GOAL`

Summary is not stored in the bullet in v1 (bullet is telemetry-only); param reserved for future / logging.

## Trim / retention

| Layer | Limit | Behavior |
|-------|-------|----------|
| Workflow Usage entries | **50** max | Drop oldest bullet on finalize (`trim-workflow-usage.ps1`) |
| Workflow section lines | warn at **80** | Trim script stdout warning for Coordinator |
| `memory.md` total | **300** max | `trim-memory.ps1` unchanged |
| Session JSON | workflow lifetime | Delete on finalize or cancel |

Never auto-trim Architecture Decisions / Known Issues for workflow cap — workflow section only unless global cap forces manual Coordinator prune.

## Boundary vs other memory writes

| Source | Purpose |
|--------|---------|
| Workflow Usage | Telemetry: mode, tier, agent chain, models, token estimates |
| Reviewer `## Memory Update` | Durable project knowledge (architecture, bugs, conventions) |
| Daily changelog | Ephemeral same-day work log |

Both Workflow Usage and Memory Update may append on the same approval event — different sections, different purpose. Never merge changelog into Workflow Usage.

## Lite parity

| Concern | Full `/mas` | MAS Lite |
|---------|-------------|----------|
| Session init/record/finalize | yes | yes — identical scripts |
| Qualification gate | `Approved: YES` + `FILES` | same |
| Handoff `MODE` / `TIER` | `FULL` / `none` or N/A | `LITE` / `S\|M\|L\|L+` |
| Subagent Usage Report | optional | **skipped** |
| Token fallback | unknown or partial | `est~{tier}` when all steps unknown |
| Reviewer | full skill | reviewer-lite; still triggers finalize |
| Separate lite file | — | **no** — same `memory.md` section |

`MODE: LITE` does **not** skip usage tracking.

## Scripts

| Script | Purpose |
|--------|---------|
| `init-workflow-session.ps1` | Start ephemeral session JSON |
| `record-workflow-step.ps1` | Append/upsert agent step after each Task |
| `finalize-workflow-usage.ps1` | Write memory.md bullet, trim, delete session |
| `cancel-workflow-session.ps1` | Drop session without memory write |
| `trim-workflow-usage.ps1` | Cap `## Entries` under Workflow Usage |

## Edge cases

| Case | Behavior |
|------|----------|
| Reviewer loop (`Approved: NO` → dev → reviewer) | Session kept; same agent step replaced on re-record; finalize upserts bullet |
| Missing session at record | Script errors; Coordinator logs warning, continues workflow |
| Missing session at finalize | Script errors; Coordinator logs warning |
| Script failure | Coordinator logs warning; workflow continues |
| Re-spawn same agent after Reviewer NO | Replace last step for that agent slug |
| Orphan session (abort) | `cancel-workflow-session.ps1`; optional future: purge sessions >7 days |

## Consumer note

Coordinator and future analytics read workflow bullets by `TASK_ID`. Do not paste full Workflow Usage section in handoffs — reference `memory.md` → `### Workflow Usage (MAS-02)`.
