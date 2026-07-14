# Test Strategy Standards

Reference for the **Test Strategy** agent (`mas-test-strategy`). Defines how to plan what to test, what to skip, and why — before Dev or Bug Fix writes test code.

## Purpose & boundaries

| In scope | Out of scope |
|----------|--------------|
| Test pyramid decisions (unit, integration, UI, snapshot) | Writing or editing test source code |
| Coverage targets and ROI-ranked test surfaces | Patching production source code |
| Edge-case matrix and regression risk analysis | Spawning agents or routing workflows |
| Flaky-test risk identification and mitigations | Replacing Planner acceptance criteria |
| Recommended commands aligned with `build-test-visual-qa.md` | Full test implementation patches |
| Brief at `.ai/context/test-strategies/{TASK_ID}.md` | Cosmetic or layout-only changes |

Test Strategy **operationalizes** Planner's high-level test bullets. Dev writes tests per brief; Reviewer verifies execution against brief.

## Objective

Determine **what to test, what to skip, and why** before implementation. Maximize ROI per the testing pyramid in `build-test-visual-qa.md` and `logic-brainstorm-standards.md`.

## Inputs

Coordinator handoff should include:

| Field | Required | Notes |
|-------|----------|-------|
| `FEATURE` | Yes | Screen, flow, or module name |
| `SCOPE` | Yes | Modules, layers, files to analyze |
| `TEST_SURFACE` | Optional | `unit` \| `integration` \| `ui` \| `mixed` (default `mixed`) |
| `FILES` | Optional | Seed paths from Planner/Architect output |
| `PLAN_PATH` | Optional | `.ai/context/plans/{TASK_ID}.md` or brainstorm brief |
| `STRATEGY_ONLY` | Optional | `true` → deliver brief only; no dev chain |
| `DELIVERABLE` | Default | Brief at `.ai/context/test-strategies/{TASK_ID}.md` |

Startup reads: handoff, `memory.md`, this doc, optional `PLAN_PATH`, then **only** seed `FILES` — no broad repo scan.

## Test surfaces

Rank by ROI per testing pyramid (unit highest, E2E lowest unless critical path):

| Surface | Typical targets | When to prioritize |
|---------|-----------------|-------------------|
| **Unit** | ViewModel, use-case, repository logic, pure domain, hooks, services | Business logic, state machines, error mapping, pure functions |
| **Integration** | Repo + DB, API client + mocks, module wiring, DI graph | Cross-layer contracts, serialization, cache vs remote |
| **UI** | Compose/instrumentation, React Testing Library, E2E | New screens, navigation, critical user paths, accessibility |
| **Snapshot / visual** | Compose screenshot, visual regression | Stable UI components with high regression risk only |

**Default:** favor unit tests for logic; add integration when boundaries matter; UI tests for new screens and critical flows only.

## Per-test record format

Each row in **Tests to Write** table:

| Field | Content |
|-------|---------|
| **Type** | `unit` \| `integration` \| `ui` \| `snapshot` |
| **Target** | Class, function, screen, or module |
| **Scenario** | Concrete case under test (happy path, error, edge) |
| **Rationale** | Why this test adds value (regression guard, contract, critical path) |
| **Priority** | P0 (must ship) \| P1 (should ship) \| P2 (nice) \| P3 (defer) |
| **Skip if** | Condition under which this row could be omitted (optional) |
| **Flaky risk** | LOW \| MEDIUM \| HIGH — async, timing, network, animation |
| **Mitigation** | Stable pattern if flaky risk ≥ MEDIUM (idling, test scope, fake clock) |
| **Command hint** | Targeted run command for Dev/Reviewer |

Example row:

| 1 | unit | `ExportViewModel` | `export()` emits Loading then Success when repo returns id | Guards primary export flow regression | P0 | — | LOW | — | `./gradlew :app:testDebugUnitTest --tests "ExportViewModelTest"` |

## Skip criteria

Every skipped target **must** include mandatory rationale:

| Skip reason | Example |
|-------------|---------|
| Trivial getter/setter | No logic; covered by compiler |
| Covered by higher layer | ViewModel test exercises repository contract |
| Manual-only surface | OS permission dialog; document manual QA |
| Generated/boilerplate | Hilt module glue with no custom logic |
| Third-party SDK | Test via integration boundary only |
| Cost >> value | Full E2E for one-line text change |

Record in **Tests to Skip** table: Target, Reason, Covered by (layer or manual).

## Edge-case matrix

For each applicable flow, evaluate and recommend test approach:

| Case | Layers to cover | Test approach |
|------|-----------------|---------------|
| Empty | VM, UI | Assert empty state emitted/rendered |
| Error | Repo, VM, UI | Exception mapped to user-visible error |
| Offline | Repo, VM | Cache fallback or offline message |
| Timeout | Repo, network client | Retry or timeout error path |
| Permission denied | Platform, VM | Graceful degradation |
| Concurrent use | VM, repo | No duplicate side effects |
| Process death | VM, navigation | State restore if applicable |
| Invalid input | Domain, VM | Validation errors |
| Boundary values | Domain, VM | Min, max, overflow |

Not every case applies — mark N/A with reason in brief.

## Regression lens

When `.ai/context/daily-changelog.md` has same-day entries:

- Match `SCOPE` files or module prefix to changelog `TASK_ID`s
- Cite at most 2–3 entries: "Possible regression related to **{TASK_ID}** ({summary})"
- Recommend regression tests for touched modules
- If changelog missing or empty, write `N/A` under Regression Risks

Dev reads changelog independently — Test Strategy adds **planning-time** regression hints only.

## Flaky-test section

Identify surfaces prone to flakiness and recommend stable patterns (not full patches):

| Risk source | Surface | Mitigation pattern |
|-------------|---------|-------------------|
| Async / timing | VM, UI | `runTest`, Turbine, `advanceUntilIdle` |
| Espresso idling | Android UI | IdlingResource, disable animations |
| Coroutine scope | VM | `TestScope`, `UnconfinedTestDispatcher` |
| Network mocks | Integration | Fake server, recorded responses |
| Animation | Compose UI | `ComposeTestRule` with animation disabled |
| Clock / dates | Domain | Injectable `Clock` or fake time |
| Random / UUID | Domain | Seeded generator in tests |

Flag HIGH flaky risk on P0 tests — Dev must apply mitigation before merge.

## Confidence levels

| Overall | When to use |
|---------|-------------|
| **HIGH** | Scope files read; clear pyramid; P0 tests identified |
| **MEDIUM** | Partial scope; some open questions on UI coverage |
| **LOW** | Missing plan/files; stack unknown; defer detailed matrix |

State overall confidence in brief `Overall Confidence`.

## Brief file schema

Path: `.ai/context/test-strategies/{TASK_ID}.md`

```markdown
# Test Strategy — {TASK_ID}

## Feature
...

## Scope
...

## Test Surfaces
unit | integration | ui

## Tests to Write
| # | Type | Target | Scenario | Rationale | Priority | Flaky risk | Mitigation | Command hint |
...

## Tests to Skip
| # | Target | Reason | Covered by |
...

## Edge Cases
| Case | Layer | Test approach | Priority |
...

## Regression Risks
<daily-changelog TASK_ID links or N/A>

## Flaky Test Risks
| Risk | Surface | Mitigation |
...

## Recommended Commands
- ./gradlew :module:testDebugUnitTest --tests "..."

## Overall Confidence
HIGH | MEDIUM | LOW

## Files Reviewed
- path/to/file

## Open Questions
- ...
```

Create `test-strategies/` directory if missing. Brief is durable for the workflow session; Dev, Bug Fix, and Reviewer read it when present.

## Skip criteria (Coordinator)

Coordinator may **skip Test Strategy** and route directly to **dev** when:

- Trivial one-file/obvious fix with no testable logic
- Config-only, typo, or docs-only change
- User explicitly says "skip test strategy"
- `STRATEGY_ONLY` workflow already completed for this `TASK_ID`
- Planning-only chain with no dev next

When in doubt for non-trivial features with ViewModel, repository, API, or new screen — **run Test Strategy after Planner/Architect**.

## Android vs generic command hints

### Android (Gradle)

```bash
./gradlew :<module>:testDebugUnitTest
./gradlew :<module>:testDebugUnitTest --tests "com.example.FooTest"
./gradlew :<module>:connectedDebugAndroidTest --tests "com.example.BarUiTest"
./gradlew :<module>:compileDebugKotlin
```

### Generic (npm / pytest / etc.)

```bash
npm test -- --testPathPattern=Foo
npm test -- Foo.test.ts
pytest tests/test_foo.py -k "scenario_name"
```

Align commands with `build-test-visual-qa.md` and project conventions from `project.md` when present.

## Mutual exclusivity with symptom classifiers

Test Strategy is a **pre-dev test gate**, not a symptom classifier:

| Signal | Route |
|--------|-------|
| Crash, wrong data, functional bug | Imaginer → Bug Fix (optional test-strategy after) |
| Jank, slow start, memory, battery | Perf Optimizer → Dev (optional test-strategy when user requests) |
| New feature with testable logic | Planner → **Test Strategy** → Dev |
| "What should we test?" | Test Strategy (`STRATEGY_ONLY` or pre-dev) |

Do not use Test Strategy as entry for crash/jank symptoms — use Imaginer or Perf Optimizer first.
