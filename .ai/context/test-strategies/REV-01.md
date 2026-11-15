# Test Strategy — REV-01: Multi-Stage Adaptive Review Architecture (v2.0.0)

## Feature
Multi-Stage Adaptive Review Architecture (v2.0.0) — 3-stage modular review pipeline: Deterministic Mechanical Gate (Fast-Fail Circuit Breaker), Situation-Adaptive Domain Deep-Dive (7 Profiles), and Arbiter Synthesis with Evidence Anchors and False-Positive Suppression.

## Scope
- Core Reviewer Agent: `skills/mas-reviewer/SKILL.md` (budget $\le 180$ lines)
- Stage 1 Gate Standards: `skills/multi-agent-system/references/review-stage-gate.md`
- Stage 3 Arbiter Standards: `skills/multi-agent-system/references/review-arbiter-standards.md`
- Profile Registry: `skills/multi-agent-system/references/review-profiles/` (`bugfix.md`, `ui.md`, `backend.md`, `infra.md`, `genai.md`, `feature.md`, `refactor.md`, `lite.md`)
- Lite Mode Spec: `skills/multi-agent-system/references/reviewer-lite.md`
- Coordinator Dispatch & Routing: `skills/mas-coordinator/SKILL.md`, `skills/multi-agent-system/SKILL.md`
- Protocol Contracts: `skills/multi-agent-system/protocol/handoff-format.md`, `skills/multi-agent-system/protocol/handoff-format-lite.md`, `skills/multi-agent-system/protocol/read-order.md`
- Install Manifest: `skills/multi-agent-system/install/manifest.json` (v2.0.0 bump)
- Test Harness & Fixtures: `skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1`, `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/` (7 fixture scenarios)

## Test Surfaces
unit | integration | structural

`UI_SCOPE: logic-only`. No user-facing Android UI, Compose screens, or connected device tests are executed.

---

## Device Prerequisites

| Field | Value |
|-------|-------|
| Enrollment | none |
| Target | none |
| Prep gate | skip |
| DEVICE_SERIAL | — |
| DEVICE_POLICY | auto |
| Package | — |
| Permissions to pre-grant | — |
| adb reverse | — |
| Skip rationale | Logic-only framework architecture verification. No Android device, emulator, or connected instrumentation required. |

---

## Tests to Write / Execute

| # | Type | Target | Scenario | Rationale | Priority | Flaky risk | Mitigation | Command hint |
|---|------|--------|----------|-----------|:--------:|:----------:|------------|--------------|
| **1** | structural | `skills/mas-reviewer/SKILL.md` | Line count assertion $\le 180$ lines | Enforces architectural budget invariant D9; prevents monolithic prompt bloat | **P0** | LOW | Pure filesystem line count | `powershell -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test Structural` |
| **2** | structural | `skills/multi-agent-system/install/manifest.json` | Manifest version is "2.0.0", JSON is valid, and registers `reviewStandards` & $\ge 7$ `reviewProfiles` | Enforces D10 framework version bump and inventory discovery | **P0** | LOW | Standard JSON parser validation | `powershell -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test Structural` |
| **3** | structural | `skills/multi-agent-system/references/review-profiles/` | Verify all 7 domain profile files exist and satisfy line budget ($\le 120$ lines each) | Enforces modularity and file-size constraints per D3 & D9 | **P0** | LOW | Exact path and line checks | `powershell -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test Structural` |
| **4** | unit | Fixture 01 (`fixture-01-fastfail-compile`) | Broken Kotlin syntax file triggers Stage 1 compiler failure, trips circuit breaker, emits `Approved: NO`, and skips Stages 2/3 | Enforces D1 & D2 fast-fail circuit breaker contract; guarantees zero token waste on uncompilable diffs | **P0** | LOW | Deterministic fixture AST/regex assertion | `powershell -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test FastFail` |
| **5** | unit | Fixture 02 (`fixture-02-fastfail-lint`) | Static linter violation (`NonExistentClass`) triggers Stage 1 Gate Status FAIL and halts review | Enforces D1 & D2 mechanical gate ordering and linter halt contract | **P0** | LOW | Deterministic fixture static inspection | `powershell -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test FastFail` |
| **6** | integration | Fixture 03 (`fixture-03-profile-bugfix`) | Bugfix profile flags missing regression unit test with `MAJOR-01` finding and `Issue Resolved: NO` | Enforces D3 & D7 bugfix invariant (mandatory regression test proof) | **P0** | LOW | Fixture metadata & profile rule assertion | `powershell -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test Profiles` |
| **7** | integration | Fixture 04 (`fixture-04-profile-ui`) | UI profile flags unsealed mutable state in Compose UI with `MAJOR-01` finding | Enforces D3 & D7 UI profile invariant (sealed UiState architecture) | **P0** | LOW | Fixture code regex inspection | `powershell -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test Profiles` |
| **8** | integration | Fixture 05 (`fixture-05-profile-backend`) | Backend profile detects raw SQL string interpolation and flags `CRITICAL-01` injection blocker | Enforces D3 & D7 backend profile security invariant (mandatory parameterization) | **P0** | LOW | Fixture code regex inspection | `powershell -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test Profiles` |
| **9** | integration | Fixture 06 (`fixture-06-false-positive-filter`) | Stage 3 False-Positive Filter: Rule 2 discards non-null NPE claims; Rule 4 downgrades style nits to ADVISORY; outputs `Approved: YES` | Enforces D6 4-rule suppression filter; prevents phantom nullability and cosmetic nitpick ping-pong | **P0** | LOW | Mock finding metadata filter evaluation | `powershell -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test Suppression` |
| **10** | integration | Fixture 07 (`fixture-07-delta-rereview`) | Iteration 2 re-review restricts scope to delta diffs; rejects new blocking findings on untouched code; outputs `Approved: YES` once prior blockers are fixed | Enforces D8 delta-only re-review boundary contract | **P0** | LOW | Multi-turn metadata evaluation | `powershell -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test Delta` |
| **11** | integration | Full Fixture Suite (`Test-AdaptiveReviewer.ps1`) | End-to-end execution of all 18 assertions across 5 test suites | Complete regression suite for the review architecture | **P0** | LOW | Aggregated exit code validation (`exit 0`) | `powershell -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test All` |
| **12** | integration | Backward Compatibility Check | Auto-detection fallback when `REVIEW_PROFILE` omitted in handoff; downstream envelope compatibility (`Approved:`, `Daily Summary`, `Memory Update`, `Usage Report`) | Guarantees non-breaking compatibility with legacy handoffs and Coordinator pipelines per D4 & D9 | **P1** | LOW | Schema verification across handoff formats | Manual inspect `skills/mas-coordinator/SKILL.md` & `skills/mas-reviewer/SKILL.md` |

---

## Tests to Skip

| # | Target | Reason | Covered by |
|---|--------|--------|------------|
| 1 | Android Gradle build (`./gradlew compileDebugKotlin`) | Repository contains agent framework definitions, PowerShell test suites, and documentation. No Android application code was modified in REV-01. | Logic-only scope; verified by `Test-AdaptiveReviewer.ps1` structural tests |
| 2 | Live LLM Model Invocations | Running live API calls to test prompt completions introduces non-deterministic variance, token cost, and network dependencies. | Hermetic fixture assertions in `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/` via `Test-AdaptiveReviewer.ps1` |
| 3 | Connected Device UI / Screencap Tests | No visual UI or Android presentation components exist in the framework layer (`UI_SCOPE: logic-only`). | Device Prerequisites skipped with rationale |
| 4 | Figma MCP Extraction | Framework task does not touch Figma designs or UI visual specs. | Scope exclusion (`UI_SCOPE: logic-only`) |

---

## Edge Cases

| Case | Layer | Test approach | Priority |
|------|-------|---------------|:--------:|
| Missing `REVIEW_PROFILE` in handoff | L0 Dispatch / Startup | Verify `SKILL.md` includes explicit fallback rules auto-detecting domain from file extensions/paths | P0 |
| Composite Profile (`feature (secondary: backend, genai)`) | L0 / L2 Profile Resolution | Verify parser and profile specs support combining primary checklist with secondary audit subsections | P1 |
| Both Syntax Error and Secret Leak in Stage 1 | L1 Mechanical Gate | Verify circuit breaker trips immediately on first mechanical failure without masking diagnostics | P0 |
| Unanchored Critical Finding Proposed by Reviewer | L3 Arbiter | Verify Rule 1 in `review-arbiter-standards.md` discards or downgrades unanchored findings to ADVISORY | P0 |
| Re-Review Iteration 2 Attempting to Flag Untouched Code | L3 Delta Protocol | Verify Rule in `review-arbiter-standards.md` and Fixture 07 strictly forbids new blockers on code untouched since iteration 1 | P0 |
| Missing Reference Standards on Fresh Install | Install Manifest | Verify `manifest.json` lists all reference docs (`review-stage-gate.md`, `review-arbiter-standards.md`, `review-profiles/*.md`) | P0 |

---

## Regression Risks

- **MAS-11 Specialist Audit Alignment**: MAS-11 added review checks for GenAI (`0l`), Product Management (`0m`), Backend Clean Architecture (`0n`), and DevOps (`0o`). Refactoring the monolithic reviewer into modular profiles risked omitting these checks.  
  *Mitigation:* Profile files `genai.md`, `feature.md`, `backend.md`, and `infra.md` explicitly implement these invariant tables; verified via structural existence and line-count tests.
- **Monolithic Reviewer Prompt Size Creep**: The reviewer prompt previously expanded to 825 lines across 11 MAS releases.  
  *Mitigation:* Automated assertion in `Test-AdaptiveReviewer.ps1` strictly enforces that `skills/mas-reviewer/SKILL.md` is $\le 180$ lines (currently 131 lines).
- **Coordinator Envelope Contract Drift**: Downstream Coordinator steps parse `Approved: YES | NO`, `## Daily Summary`, and `## Memory Update`.  
  *Mitigation:* Stage 1 fast-fail and Stage 3 envelopes both output identical contract headers.

---

## Flaky Test Risks

| Risk | Surface | Mitigation |
|------|---------|------------|
| PowerShell Path Separator Discrepancy | `Test-AdaptiveReviewer.ps1` on Windows vs POSIX | Harness uses `Join-Path` and `[System.IO.Path]` normalization for cross-platform stability. |
| Line Ending Variations (CRLF vs LF) | Line Count & Line Range Anchors | Line-count check measures array elements from `Get-Content` rather than raw character byte count. |
| Fixture File Reading Errors | JSON Fixtures | Harness wraps JSON parsing in try/catch blocks with detailed assertion failure messages. |

---

## Recommended Commands for Test Executor

### 1. Execute All Verification Suites (Comprehensive Gate)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test All
```

### 2. Execute Granular Test Suites
```powershell
# Structural line-budget & manifest checks
powershell -NoProfile -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test Structural

# Stage 1 Fast-Fail Circuit Breaker checks
powershell -NoProfile -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test FastFail

# Stage 2 Domain Verification Profile checks
powershell -NoProfile -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test Profiles

# Stage 3 False-Positive Suppression Filter checks
powershell -NoProfile -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test Suppression

# Delta-Only Re-Review Protocol checks
powershell -NoProfile -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test Delta
```

---

## Overall Confidence
**HIGH** — Complete architectural specifications, reference standards, 7 offline fixture scenarios, and an automated PowerShell verification harness are fully in place and verified.

## Files Reviewed
- `.ai/handoffs/REV-01.md`
- `.ai/context/architecture/REV-01.md`
- `skills/mas-reviewer/SKILL.md`
- `skills/mas-coordinator/SKILL.md`
- `skills/multi-agent-system/references/review-stage-gate.md`
- `skills/multi-agent-system/references/review-arbiter-standards.md`
- `skills/multi-agent-system/references/review-profiles/*.md`
- `skills/multi-agent-system/install/manifest.json`
- `skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1`
- `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/*`

## Open Questions
None. All 10 architectural decisions (D1–D10) are confirmed and actionable.
