# Performance Optimization Standards

Reference for the **Performance Optimization** agent (`mas-perf-optimizer`). Defines how to profile existing implementations and recommend measurable production gains without patching code.

## Purpose & boundaries

| In scope | Out of scope |
|----------|--------------|
| Profile CPU, memory, UI rendering, coroutines, I/O, startup, battery, scalability | Writing or editing production code |
| Identify inefficiencies with measurable impact | Adding features or new functionality |
| Recommend architecture and implementation directions | Cosmetic or layout changes |
| Regression lens via daily changelog | Spawning agents or routing workflows |
| Brief at `.ai/context/optimizations/{TASK_ID}.md` | Micro-optimizations without production impact |
| Preserve behavior/UI/readability (unless significant-gain exception) | Replacing Dev implementation entirely |

Perf Optimizer **narrows the optimization scope** for Dev. Dev may confirm, extend, or reject brief items per handoff scope.

## Objective

Maximize runtime performance, startup speed, UI smoothness, battery efficiency, and scalability. **Never add features** — only optimize existing implementations.

## Inputs

Coordinator handoff should include:

| Field | Required | Notes |
|-------|----------|-------|
| `PERF_SYMPTOM` | Yes | User-visible perf problem (jank, slow start, high memory, battery drain, etc.) |
| `SCOPE` | Yes | Screens, modules, flows, or file prefixes to analyze |
| `METRICS` | Optional | Baseline numbers or `unknown` |
| `FILES` | Optional | Seed paths — ViewModels, composables, repos, startup entry |
| `ANALYZE_ONLY` | Optional | `true` → deliver brief only; no dev chain |
| `DELIVERABLE` | Default | Brief at `.ai/context/optimizations/{TASK_ID}.md` |

Startup reads: handoff, `memory.md`, `daily-changelog.md` (if present), this doc, then **only** relevant source files.

## Analysis axes

Analyze applicable axes — not every axis applies to every symptom:

| Axis | What to look for |
|------|------------------|
| **CPU** | Hot paths, unnecessary work on critical path, algorithmic complexity |
| **Memory** | Retained objects, large allocations, leak patterns, bitmap sizing |
| **Allocations / GC** | Allocation churn in loops, boxing, string concat in hot paths |
| **UI rendering** | Overdraw, layout thrashing, expensive measure/layout |
| **Recompositions** | Unstable keys, unstable lambdas, state hoisting gaps (Compose/React) |
| **Coroutines / async** | Structured concurrency, scope leaks, blocking calls |
| **Flow / streams** | Unbounded collectors, missing `distinctUntilChanged`, backpressure |
| **Dispatchers / threading** | Main-thread I/O, wrong dispatcher, lock contention |
| **Sync / blocking** | `runBlocking`, synchronized blocks on UI thread, ANR risks |
| **Database** | N+1 queries, missing indexes, main-thread reads |
| **Bitmaps / media** | Decode size vs display size, cache strategy, hardware bitmaps |
| **Networking** | Redundant requests, missing cache headers, serial vs parallel |
| **Caching** | Stale-while-revalidate, in-memory vs disk, eviction policy |
| **Startup** | Critical path init, lazy vs eager DI, content provider cost |
| **Battery** | Wake locks, frequent wakeups, background work scheduling |
| **ANR risk** | Main-thread blocking, binder calls, heavy sync on UI |
| **Scalability** | Pagination, unbounded lists, O(n²) operations on growth |
| **Architecture** | Layer violations causing redundant work, missing boundaries |

Keep analysis **concrete** ("`ExportViewModel.loadAll()` fetches full list on main dispatcher") not abstract ("performance could be better").

## Per-finding record format

Each finding in brief and full chat output table:

| Field | Content |
|-------|---------|
| **Current** | What the code does today (specific component/path) |
| **Issue** | Observed inefficiency or risk |
| **Why** | Mechanism (e.g. main-thread I/O, unstable recomposition keys) |
| **Impact** | Measurable or qualitative user/system effect |
| **Recommended architecture** | Target pattern (dispatcher, caching layer, pagination, etc.) |
| **Optimized implementation** | Concrete change direction for dev (not full patch) |

**Confidence per finding:** HIGH | MEDIUM | LOW.

Rank at most **~5** primary findings in brief; secondary items in watch list only.

**HIGH:** clear hot path or profiler/stack evidence, reproduces consistently  
**MEDIUM:** plausible given code + symptom, needs Dev verification  
**LOW:** edge case or uncertain gain — include for completeness only

## Measurable-impact bar

**Never recommend micro-optimizations.** Each primary finding must document:

- User-visible or system-level effect (frame drops, startup ms, memory MB, battery, ANR risk)
- Why the change is production-grade, not theoretical

Demote items that are style-only, negligible allocation savings, or readability cost without significant gain.

## Behavior preservation

- **Default:** optimizations must not change app behavior, UI, or sacrifice readability.
- **Exception:** only when brief `Significant-Gain Exceptions` section documents justification (e.g. pagination changes initial load behavior with net UX gain).

Dev rejects brief items that are feature requests — note out-of-scope, do not implement.

## Confidence levels

| Overall | When to use |
|---------|-------------|
| **HIGH** | Multiple axes analyzed; top findings have strong evidence |
| **MEDIUM** | Scope partially analyzed; 2+ plausible findings |
| **LOW** | Incomplete files, missing metrics, or symptom before code entry |

State overall confidence in brief `Analysis Summary`.

## Regression lens

Perf Optimizer cites changelog at analysis time — Dev reads changelog independently.

When `.ai/context/daily-changelog.md` has same-day entries:

- Match symptom area, `FILES`, or module prefix to changelog `TASK_ID`s
- Cite at most 2–3 entries: "Possible regression related to **{TASK_ID}** ({summary})"
- If changelog missing or empty, write `N/A` under Regression Notes

Dev reads changelog independently — Perf Optimizer adds **analysis-time** regression hints only.

## Brief file schema

Path: `.ai/context/optimizations/{TASK_ID}.md`

```markdown
# Optimization Brief — {TASK_ID}

## Perf Symptom
...

## Scope
...

## Baseline Metrics
<numbers or "unknown" + profiling recommendation>

## Analysis Summary
<2–4 sentences: overall assessment, top axis>

## Findings
| # | Current | Issue | Why | Impact | Recommended architecture | Optimized implementation | Confidence |
...

## Priority Order
1. Finding #N — <one line rationale>
...

## Behavior / UI Constraints
<preserve behavior unless exception below>

## Significant-Gain Exceptions
<items where UI/behavior may change — must justify gain>

## Regression Notes
...

## Files Analyzed
- path/to/file

## Open Questions
- ...

## Expected Improvement
<what metric should improve post-implementation — for reviewer>
```

Create `optimizations/` directory if missing. Brief is durable for the workflow session; Dev and Reviewer read it when present.

## Skip criteria

Coordinator may **skip Perf Optimizer** and route directly to **dev** when:

- Trivial one-line perf fix obvious (e.g. missing `remember`, single `Dispatchers.IO`)
- User explicitly says "skip analysis" / "just fix"
- Greenfield feature work — never perf-optimizer as entry
- Functional bug primary (crash, wrong data) — imaginer chain, not perf

When in doubt for jank, startup, memory, battery — **run Perf Optimizer first**.

## Mutual exclusivity

Perf Optimizer and Imaginer are **mutually exclusive entry points** for a given `TASK_ID` symptom class:

| Signal | Route |
|--------|-------|
| Crash, wrong data, functional bug | Imaginer → Bug Fix |
| Jank, slow start, memory, battery | Perf Optimizer → Dev |
| Mixed perf + functional bug | Imaginer first — correctness before optimization |
| ANR + stack trace pointing to bug | Imaginer → Bug Fix |
| ANR risk / main-thread blocking, no clear bug | Perf Optimizer → Dev |

Do not chain both Perf Optimizer and Imaginer for the same workflow without explicit user override.

## Android vs generic layer notes

### Android (Jetpack / Compose)

| Area | Typical artifacts |
|------|-------------------|
| UI | `@Composable`, recomposition, `LazyColumn` keys |
| Presentation | `ViewModel`, `StateFlow`, `viewModelScope` |
| Data | Room DAO, Repository, Retrofit/Ktor |
| Startup | `Application.onCreate`, Hilt init, ContentProvider |
| Media | Bitmap decode, ExoPlayer, MediaCodec |

### Generic (React / Next / Node / Python)

| Area | Typical artifacts |
|------|-------------------|
| UI | React re-renders, memo, virtual lists |
| State | hooks, stores, selectors |
| Data | fetch/cache, ORM queries |
| Startup | bundle size, SSR hydration, lazy imports |
| I/O | sync fs, connection pooling |

Trace **one primary path** first; note alternate branches only if scope includes them.
