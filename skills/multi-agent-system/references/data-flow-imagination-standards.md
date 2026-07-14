# Data Flow Imagination Standards

Reference for the **Imaginer** agent (`mas-imaginer`). Defines how to trace user-action data flow through code for debugging without patching.

## Purpose & boundaries

| In scope | Out of scope |
|----------|--------------|
| Simulate user journey from action to symptom | Writing or editing production code |
| Map data/state/events per layer | Root-cause fix or patch |
| Identify suspected failure hops | Refactoring or architecture redesign |
| Regression lens via daily changelog | Spawning agents or routing workflows |
| Brief at `.ai/context/imaginations/{TASK_ID}.md` | Replacing Bug Fix analysis entirely |

Imaginer **narrows the search space** for Bug Fix. Bug Fix may confirm, refute, or extend the imagination brief.

## Inputs

Coordinator handoff should include:

| Field | Required | Notes |
|-------|----------|-------|
| `SYMPTOM` | Yes | User-visible problem or stack trace summary |
| `USER_ACTION` | Yes | What the user did before the failure |
| `REPRO_STEPS` | Preferred | Ordered steps to reproduce |
| `FILES` | Optional | Seed files — stack trace, ViewModel, repo, API client |
| `TRACE_ONLY` | Optional | `true` → deliver brief only; no bug-fix chain |
| `DELIVERABLE` | Default | Brief at `.ai/context/imaginations/{TASK_ID}.md` |

Startup reads: handoff, `memory.md`, `daily-changelog.md` (if present), this doc, then **only** relevant source files.

## Journey simulation

1. **Anchor on symptom** — what the user sees (crash, wrong data, freeze, silent failure).
2. **Rewind to first user action** — tap, submit, navigate, background/foreground.
3. **Forward-walk** hop by hop until symptom or first divergence from expected behavior.
4. **State checkpoints** — note mutable state at each hop (UI state, ViewModel, cache, DB row).
5. **Async boundaries** — coroutines, callbacks, LiveData/Flow collectors, network round-trips.
6. **Expected vs actual** — one line per hop where behavior diverges.

Keep journeys **concrete** ("User taps Export → ViewModel.export() → Repo.upload()") not abstract ("data flows through layers").

## Layer taxonomy

### Generic layers

| Layer | Typical artifacts | What to trace |
|-------|-------------------|---------------|
| UI / Presentation | Screens, components, controllers | User events, rendered state, navigation |
| Presentation logic | ViewModels, presenters, hooks | State reduction, side effects, error mapping |
| Domain | Use cases, services, validators | Business rules, invariants |
| Data | Repositories, DAOs, clients | Cache vs remote, mapping, retries |
| Infrastructure | Network, DB, filesystem, platform APIs | Timeouts, permissions, serialization |

### Android (Jetpack / Compose)

| Layer | Typical artifacts |
|-------|---------------------|
| UI | `@Composable`, Activity/Fragment, Navigation |
| Presentation | `ViewModel`, `UiState`, `UiEvent` |
| Domain | Use cases, interactors |
| Data | Repository impl, Room DAO, Retrofit/Ktor service |
| DI / wiring | Hilt modules, bindings |
| Platform | WorkManager, ContentResolver, MediaStore |

Trace **one primary path** first; note alternate branches only if repro steps touch them.

## Per-hop record format

Each hop in the data-flow table:

| Column | Content |
|--------|---------|
| **Hop** | Sequential number |
| **Layer** | From taxonomy above |
| **Component** | Class/function/file (short name) |
| **Input** | Arguments, intent extras, request body, prior state |
| **Transform** | What the code does (map, filter, validate, persist) |
| **Output** | Return value, emitted state, side effect |
| **Events** | Analytics, logs, navigation, toasts relevant to repro |

Example row:

| 3 | Data | `ExportRepository.upload` | `Uri`, `ExportConfig` | Multipart POST + progress Flow | `Result<ExportId>` | `onFailure` → `UiEvent.ShowError` |

## Failure analysis

For each suspected failure point:

1. **Hop number** where divergence likely occurs
2. **Hypothesis** — one sentence (null, race, stale cache, wrong dispatcher, etc.)
3. **Evidence** — code path, log line, changelog entry, stack frame
4. **Confidence** — HIGH / MEDIUM / LOW

Rank at most **3** primary suspects; list secondary as "watch" items in brief file only.

**HIGH:** stack trace points here, or repro always fails at this hop  
**MEDIUM:** plausible given code + symptom, needs Bug Fix verification  
**LOW:** edge case or missing data — include for completeness

## Confidence levels

| Overall | When to use |
|---------|-------------|
| **HIGH** | Full path traced; primary suspect has strong evidence |
| **MEDIUM** | Path mostly traced; 2+ plausible hops |
| **LOW** | Incomplete files, flaky repro, or symptom before code entry |

State overall confidence in output and brief.

## Regression lens

When `.ai/context/daily-changelog.md` has same-day entries:

- Match symptom area, `FILES`, or module prefix to changelog `TASK_ID`s
- Cite at most 2–3 entries: "Possible regression related to **{TASK_ID}** ({summary})"
- If changelog missing or empty, write `N/A` under Regression Notes

Bug Fix reads the same changelog independently — Imaginer adds **trace-time** regression hints only.

## Brief file schema

Path: `.ai/context/imaginations/{TASK_ID}.md`

```markdown
# Imagination Brief — {TASK_ID}

## Symptom
...

## User Action
...

## Repro Steps
1. ...

## Data Flow
| Hop | Layer | Component | Input | Transform | Output | Events |
...

## Suspected Failure Points
| # | Hop | Hypothesis | Evidence | Confidence |
...

## Overall Confidence
HIGH | MEDIUM | LOW

## Regression Notes
...

## Files Traced
- path/to/file

## Open Questions
- ...
```

Create `imaginations/` directory if missing. Brief is durable for the workflow session; Bug Fix reads it at startup when present.

## Skip criteria

Coordinator may **skip Imaginer** and route directly to Bug Fix when:

- Trivial fix obvious from stack trace (typo, null on one line, missing import)
- User explicitly says "skip imagination" / "just fix"
- Config-only or single-line change with no data-flow ambiguity

When in doubt for crashes, ANRs, regressions, or multi-hop features — **run Imaginer first**.
