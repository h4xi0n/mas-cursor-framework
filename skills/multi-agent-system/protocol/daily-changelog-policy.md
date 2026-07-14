# Daily Changelog Policy

Ephemeral per-project work log at `.ai/context/daily-changelog.md`. Records concise summaries of MAS work completed each **local calendar day**.

## File path

`.ai/context/daily-changelog.md` (gitignored via `.ai/`)

## Format

```markdown
# Daily Changelog — {yyyy-MM-dd}

> Ephemeral MAS work log for this local calendar day. Reset on first /mas or /mas-lite trigger of a new day. Not copied to memory.md.

## Entries

- **{TASK_ID}** ({type}): {summary}
```

- `{type}` — `feature` | `bugfix` (lowercase)
- `{summary}` — plain text, no newlines, max 120 characters
- Header date: `# Daily Changelog — yyyy-MM-dd` (en-dash `—`)
- Entries listed in append order (newest last); upsert replaces line matching `**{TASK_ID}**`
- Empty day: `## Entries` present with zero bullets

## Rollover rule

- Use **local machine date** (`yyyy-MM-dd`)
- On first `/mas` or `/mas-lite` trigger of a new day, Coordinator runs `ensure-daily-changelog.ps1`
- If file missing or header date ≠ today → rewrite from template (prior day entries discarded)
- No background scheduler; rollover only on MAS session start
- Cross-timezone drift acceptable for v1

## Single writer

**Coordinator only** (full `/mas` and `/mas-lite`). Specialists never write the changelog.

| When | Action |
|------|--------|
| Coordinator Startup (after `memory.md`) | `ensure-daily-changelog.ps1` |
| Reviewer `Approved: YES` + non-empty `FILES` in chain | `append-daily-changelog.ps1` |
| Reviewer `Approved: NO` or planning-only (no `FILES`) | no append |
| Normal chat (no `/mas`) | no change |

## Qualification

Append only when **all** of:

1. Reviewer output has `Approved: YES` (full or lite)
2. Workflow handoff chain had non-empty `FILES` (code changed)

Skip when:

- Planning-only chains (architect/planner/reviewer with no source changes)
- Workflow cancelled before Reviewer
- Documenter-only with no source changes

Reviewer rejection loops: upsert by `TASK_ID` — one line per task per day.

## Summary resolution (Coordinator)

Before calling append, resolve `-Summary` in order:

1. Reviewer `## Daily Summary` (≤120 chars) if present
2. Else `FIX_SUMMARY` (bug-fix chain)
3. Else `CHANGE_SUMMARY` (dev/documenter chain)
4. Else handoff `GOAL` (truncate to 120 chars)

**Type:** `bugfix` if chain included bug-fix agent; else `feature`.

## Token budget

- Max **30 entries** per day (append script drops oldest)
- Summaries max **120 chars** (script truncates with `…`)
- Bug-fix reads file once at startup; cite at most 2–3 relevant `TASK_ID`s — never paste full file

## Memory boundary

Daily changelog content is **ephemeral**. Never copy entries to `memory.md`. See [memory-policy.md](memory-policy.md).

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/ensure-daily-changelog.ps1` | Create or rollover on new day |
| `scripts/append-daily-changelog.ps1` | Upsert entry after Reviewer approval |
| `scripts/init-mas-context.ps1` | Seed changelog on new project bootstrap |

## Lite parity

`MODE: LITE` does **not** skip changelog. Same ensure on startup and append after reviewer-lite `Approved: YES`. No separate lite file or path.

## Edge cases

| Case | Behavior |
|------|----------|
| Missing file mid-day | ensure or append creates fresh today file |
| Corrupt / unparseable header | ensure treats as stale → `ROLLOVER` |
| ensure script failure | Coordinator logs warning; workflow continues |
| Summary >120 chars | append truncates |
| Existing projects without init | First `/mas` ensure creates file |
