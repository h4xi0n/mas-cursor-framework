# Handoff Format

All agent communication uses structured handoffs written to `.ai/handoffs/{TASK_ID}.md`.

## Coordinator Handoff Template

```
TASK_ID: <id>
MODE: FULL | LITE
TIER: S | M | L | L+ | none
TARGET_AGENT: <spec-reader|brainstorm|planner|architect|android-dev|general-dev|osint|imaginer|ux-intelligence|perf-optimizer|release-readiness|test-strategy|bug-fix|documenter|reviewer|commit>
SPAWN_STATUS: spawned
UI_SCOPE: logic-only | ui-allowed
GOAL: <single sentence>
DOCS:
* path/to/requirements or openapi (optional)
CONTEXT:
* item
* item
FILES:
* path (optional)
MODULES:
* :app (optional, Android)
UI_CHANGES: YES | NO
DELIVERABLE: <expected result>
NEXT_AGENT: <agent or none>
DONE
```

### Coordinator → Imaginer Handoff

```
TASK_ID: <id>
TARGET_AGENT: imaginer
SYMPTOM: <user-visible problem or stack trace>
USER_ACTION: <what user did before failure>
REPRO_STEPS:
* step
FILES:
* seed paths (optional)
TRACE_ONLY: true | false
DELIVERABLE: Brief at .ai/context/imaginations/{TASK_ID}.md
NEXT_AGENT: bug-fix | none
DONE
```

`TRACE_ONLY: false` (default) → `NEXT_AGENT: bug-fix`. `TRACE_ONLY: true` → `NEXT_AGENT: none`.

### Coordinator → Perf Optimizer Handoff

```
TASK_ID: <id>
TARGET_AGENT: perf-optimizer
GOAL: <one sentence optimization objective>
PERF_SYMPTOM: <user-visible perf problem>
SCOPE:
* screens, modules, flows, or file prefixes
METRICS: <baseline numbers or unknown>
FILES:
* seed paths (optional)
ANALYZE_ONLY: true | false
DELIVERABLE: Brief at .ai/context/optimizations/{TASK_ID}.md
NEXT_AGENT: android-dev | general-dev | none
DONE
```

`ANALYZE_ONLY: false` (default) → `NEXT_AGENT: android-dev` | `general-dev` (platform from `project.md` or stack detection). `ANALYZE_ONLY: true` → `NEXT_AGENT: none`.

### Coordinator → Release Readiness Handoff

```
TASK_ID: <id>
TARGET_AGENT: release-readiness
GOAL: <one sentence release audit objective>
RELEASE_TARGET: <version / build / channel or unknown>
SCOPE:
* modules, screens, flows, or file prefixes
FILES:
* seed paths (optional)
RELEASE_ONLY: true | false
DELIVERABLE: Brief at .ai/context/release-readiness/{TASK_ID}.md
NEXT_AGENT: bug-fix | android-dev | general-dev | none | commit
DONE
```

`RELEASE_ONLY: false` (default) → `NEXT_AGENT` from top P0 fix agent per [release-readiness-standards.md](../references/release-readiness-standards.md). `RELEASE_ONLY: true` → `NEXT_AGENT: none`.

**Failure routing (category → default fix agent):**

| Category | Default fix agent |
|----------|-------------------|
| Crashes, ANRs (functional), Edge cases (functional) | `bug-fix` |
| Lint (Android), Startup, Memory, A11y, L10n, Play*, Signing, Versioning, Backups, ProGuard, Baseline, Battery, Offline | `android-dev` |
| Lint (non-Android), Versioning (generic) | `general-dev` |
| Play store listing, keystore | `android-dev` + `user` |

### Fix agent ← Release Readiness

```
TASK_ID: <id>
TARGET_AGENT: bug-fix | android-dev | general-dev
RELEASE_BRIEF: .ai/context/release-readiness/{TASK_ID}.md
SCOPE: P0/P1 failures only — items listed in brief Priority Order
FAILURE_CATEGORIES:
* Crashes
* Lint
FILES:
* paths implicated by top failures
DELIVERABLE: Fix release blockers per brief Priority Order
NEXT_AGENT: documenter | reviewer
DONE
```

### Coordinator → Test Strategy Handoff

```
TASK_ID: <id>
TARGET_AGENT: test-strategy
FEATURE: <screen or module>
SCOPE:
* layers and modules
TEST_SURFACE: unit | integration | ui | mixed
FILES:
* paths from planner
PLAN_PATH: .ai/context/plans/{TASK_ID}.md
STRATEGY_ONLY: true | false
DELIVERABLE: Brief at .ai/context/test-strategies/{TASK_ID}.md
NEXT_AGENT: android-dev | general-dev | bug-fix | none
DONE
```

`STRATEGY_ONLY: false` (default) → `NEXT_AGENT: android-dev` | `general-dev` (platform from `project.md` or stack detection); optional `bug-fix` when spawned post-Imaginer. `STRATEGY_ONLY: true` → `NEXT_AGENT: none`.

### Planner → Test Strategy

When non-trivial testable scope, Planner output / Coordinator sets `NEXT_AGENT: test-strategy` (not `android-dev`/`general-dev`).

```
DELIVERABLE: Task decomposition complete — test strategy required
NEXT_AGENT: test-strategy
```

### Test Strategy → Dev

```
TASK_ID: <id>
TARGET_AGENT: android-dev | general-dev
TEST_STRATEGY_BRIEF: .ai/context/test-strategies/{TASK_ID}.md
SCOPE: implement P0/P1 tests per brief; document skips
FILES:
* paths from brief
DELIVERABLE: Implementation + tests per test strategy brief
NEXT_AGENT: documenter
```

### Coordinator → OSINT Handoff

```
TASK_ID: <id>
TARGET_AGENT: osint
GOAL: <one sentence research objective>
RESEARCH_MODE: FEATURE | BUG
TOPIC: <one-line research question>
SCOPE: <feature area / symptom / stack component>
SOURCES_HINT:
* optional repos, docs, URLs
FILES:
* seed paths (optional, local context only)
RESEARCH_ONLY: true | false
DELIVERABLE: Brief at .ai/context/osint/{TASK_ID}.md
NEXT_AGENT: brainstorm | planner | imaginer | bug-fix | none
DONE
```

**`NEXT_AGENT` resolution:**

| Condition | `NEXT_AGENT` |
|-----------|--------------|
| `RESEARCH_ONLY: true` | `none` |
| `RESEARCH_MODE: FEATURE` + logic unclear | `brainstorm` |
| `RESEARCH_MODE: FEATURE` + scope clear | `planner` |
| `RESEARCH_MODE: BUG` + non-trivial data flow | `imaginer` |
| `RESEARCH_MODE: BUG` + fix pattern clear, trivial local trace | `bug-fix` |

### Coordinator → UX Intelligence Handoff

```
TASK_ID: <id>
TARGET_AGENT: ux-intelligence
FEATURE: <screen or flow>
USER_GOAL: <user intent>
SCOPE:
* primary path
* empty/loading/error states
FILES:
* paths from dev
UI_CHANGES: YES
UX_ONLY: true | false
DELIVERABLE: Brief at .ai/context/ux-reviews/{TASK_ID}.md
NEXT_AGENT: android-dev | general-dev | documenter | none
DONE
```

`UX_ONLY: true` → `NEXT_AGENT: none`. Brief with P0/P1 implementable fixes → `android-dev` | `general-dev`. Advisory-only or no friction → `documenter`.

### Dev → UX Intelligence (when UI_CHANGES: YES)

When Dev completes with `UI_CHANGES: YES`, Dev output sets `NEXT_AGENT: ux-intelligence` (not `documenter`).

```
UI_CHANGES: YES
DELIVERABLE: Implementation complete — UX review required
NEXT_AGENT: ux-intelligence
```

### UX Intelligence → Dev (second pass)

```
TASK_ID: <id>
TARGET_AGENT: android-dev | general-dev
UX_BRIEF: .ai/context/ux-reviews/{TASK_ID}.md
SCOPE: behavioral fixes only — no layout or cosmetic changes
FILES:
* paths from brief Files hint column
UI_CHANGES: YES
DELIVERABLE: Apply P0/P1 behavioral fixes from UX brief
NEXT_AGENT: documenter
```

### Post-Bug Fix Reviewer Handoff (Coordinator → Reviewer)

Required after every Bug Fix completion. `NEXT_AGENT` on Bug Fix handoff must be `reviewer`.

```
TASK_ID: <id>
TARGET_AGENT: reviewer
GOAL: Verify bug is perfectly resolved.
ORIGINAL_SYMPTOM: <user report or stack trace>
ROOT_CAUSE: <from Bug Fix>
FIX_SUMMARY: <what changed>
REPRO_STEPS:
* step
FILES:
* patched paths
UI_CHANGES: YES | NO
MODULES:
* :app
DELIVERABLE: Bug Resolution Verification + Build & Tests + Visual QA if UI
NEXT_AGENT: none
DONE
```

## Rules

- Keep handoffs under 20 lines.
- **`MODE`:** `FULL` for `/mas`; `LITE` for `/mas-lite` (required on every coordinator handoff).
- **`TIER`:** `S` | `M` | `L` | `L+` for lite; `none` or omit semantics for full `/mas`.
- Reference `memory.md` by section name; never paste its contents.
- Never paste entire conversations or codebases.
- Coordinator writes handoff to disk; do not duplicate full handoff in chat.

## Agent Output Templates

### Spec Reader

```
## Sources

| Document | Status | Notes |

## Requirements Summary

## API Contract Summary

## Design & UX Notes

## Acceptance Criteria

## Constraints

## Assumptions

## Open Questions

## Conflicts with Memory

## Brief Path

.ai/context/specs/{TASK_ID}.md

## Recommended Next Agent

planner

DONE
```

Coordinator sets `NEXT_AGENT: brainstorm` (greenfield) or `planner` (trivial scope).

### Brainstorm

```
## Outcome

## UI Scope

logic-only | ui-allowed

## Options

| # | Option | Pros | Cons | Risk | Effort |

## Recommended

## Logic Flow

## Domain & Contracts

## Edge Cases

## Quality Bar

## Risks & Open Questions

## Brief File

.ai/context/brainstorms/{TASK_ID}.md

## Suggested Next

planner | architect

DONE
```

Coordinator sets `NEXT_AGENT: planner` (default) or `architect` per `Suggested Next`.

### Planner

```
## Plan

Goal:
...

Tasks:
1.
2.
3.

## Dependencies:

## Risks:

## Build & Test Plan:

## Visual QA Scenarios:

## Required Agents:

DONE
```

### Architect

```
## Architecture

## Modules:

## Layers:

## Contracts:

## Files:

DONE
```

### Android Dev / General Dev

```
## Files

<file path>

<code>

## Tests

<file path or N/A>

<command + PASS/FAIL>

## Build

<command + PASS/FAIL>

## Responsive Notes

## Visual Notes

DONE
```

Android Dev / General Dev output sets `NEXT_AGENT: ux-intelligence` when `UI_CHANGES: YES`; `NEXT_AGENT: documenter` when `UI_CHANGES: NO` or logic-only.

### UX Intelligence

```
## Feature

...

## Persona Journey

1.

## Friction Points

| # | Dimension | Moment | User struggle | Why it hurts | Behavioral fix | Priority | Files hint |

## Recommended Behavioral Fixes

1.

## Preserve UI Checklist

- [ ] No layout moves proposed
- [ ] No cosmetic/token changes proposed

## Confidence

HIGH | MEDIUM | LOW

## Regression Notes

...

## Brief Path

.ai/context/ux-reviews/{TASK_ID}.md

DONE
```

Standards: [ux-intelligence-standards.md](../references/ux-intelligence-standards.md). Coordinator sets `NEXT_AGENT: android-dev | general-dev | documenter | none` per brief content and `UX_ONLY` flag.

### Imaginer

```
## Symptom

...

## User Journey

1.
2.

## Data Flow

| Hop | Layer | Component | Input | Transform | Output | Events |

## Suspected Failure Points

| # | Hop | Hypothesis | Evidence | Confidence |

## Confidence

HIGH | MEDIUM | LOW

## Regression Notes

...

## Brief Path

.ai/context/imaginations/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT: bug-fix` (default) or `none` when `TRACE_ONLY: true`.

### OSINT

```
## Research Mode

FEATURE | BUG

## Topic

...

## Scope

...

## Findings

| # | Source | Context | Pattern/Fix | Tradeoffs | Applicability | Recommendation | Confidence |

## Recommended Approach | Recommended Fix Strategy

<mode-appropriate section>

## Priority Order

1. ...

## Overall Confidence

HIGH | MEDIUM | LOW

## Brief Path

.ai/context/osint/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT` per `RESEARCH_MODE` and `RESEARCH_ONLY` (see OSINT handoff subsection). `RESEARCH_ONLY: true` → `none`.

### Perf Optimizer

```
## Perf Symptom

...

## Scope

...

## Findings

| # | Current | Issue | Why | Impact | Recommended architecture | Optimized implementation | Confidence |

## Priority Order

1. ...

## Expected Improvement

...

## Regression Notes

...

## Brief Path

.ai/context/optimizations/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT: android-dev` | `general-dev` (default) or `none` when `ANALYZE_ONLY: true`.

### Release Readiness

```
## Release Target

...

## Scope

...

## Category Results

| Category | Status | Blocker | Finding | Fix agent |
...

## Release Ready

YES | NO

## Priority Order

1. ...

## Regression Notes

...

## Brief Path

.ai/context/release-readiness/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT: bug-fix` | `android-dev` | `general-dev` | `none` when `RELEASE_ONLY: true` or all pass; `commit` only when user confirmed ship.

### Test Strategy

```
## Feature

...

## Scope

...

## Tests to Write

| # | Type | Target | Scenario | Rationale | Priority | Flaky risk | Mitigation | Command hint |

## Tests to Skip

| # | Target | Reason | Covered by |

## Edge Cases

| Case | Layer | Test approach | Priority |

## Regression Risks

...

## Flaky Test Risks

| Risk | Surface | Mitigation |

## Recommended Commands

- ...

## Confidence

HIGH | MEDIUM | LOW

## Brief Path

.ai/context/test-strategies/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT: android-dev` | `general-dev` | `bug-fix` (optional bug chain) or `none` when `STRATEGY_ONLY: true`.

### Bug Fix

```
## Original Symptom

...

## Repro Steps

1.
2.

## Root Cause

...

## Confidence

HIGH | MEDIUM | LOW

## Fix Strategy

*

## Files To Modify

*

## Patch

<code>

## Regression Risks

*

## Build & Tests

## Visual After Fix

DONE
```

Coordinator routes Bug Fix → **Documenter** (if FILES) → Reviewer (`NEXT_AGENT: documenter` then `reviewer`).

### Documenter

```
## Comment Audit

<file>:
- CREATED / UPDATED / DELETED: ...

## Files Updated

<file path>

## Summary

Created: N | Updated: N | Deleted: N

DONE
```

Handoff in: `FILES`, `CHANGE_SUMMARY`, `PUBLIC_API: YES | NO`.  
Handoff out: `NEXT_AGENT: reviewer`.

### Reviewer

```
## Findings

## Bug Resolution Verification:

<required after Bug Fix; N/A otherwise>

## Implementation Walkthrough:

## Lint:

## Build & Tests:

## Visual QA (Imagined):

## Similar Flow Comparison:

## Android Veteran Review:

## Edge Cases:

## Critical:

## Major:

## Minor:

Approved:
YES | NO

## Daily Summary

<one line, ≤120 chars — only when FILES non-empty; Coordinator prefers this for changelog append>

## Memory Update

<optional>

DONE
```

Post-bugfix: `Approved: YES` requires `Issue Resolved: YES`.

All Android reviews: `Approved: YES` requires build PASS, tests PASS (or documented NOT_RUN), visual QA PASS for `UI_CHANGES: YES`.

After approval, Coordinator may offer Commit agent if user opts in — Reviewer does not commit.

### Commit

```
## Change Summary

## Proposed Commit Message

```
subject

body
```

## Files to Stage

## Branch Status

## Reviewer Gate

PASS | WARN | N/A

## Confirmation

Commit: PENDING | APPROVED | SKIPPED
Push: PENDING | APPROVED | SKIPPED

## Result

DONE
```

Handoff in: `TASK_ID`, `PUSH: ASK | YES | NO`, optional Reviewer approval reference.  
Agent must obtain explicit user yes before `git commit` and separate yes before `git push`.
