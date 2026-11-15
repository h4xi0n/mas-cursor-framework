# Stage 3: Arbiter Standards & False-Positive Suppression

Source of Truth (SOT) for Stage 3 synthesis, evidence anchoring, false-positive suppression, and approval gate criteria in the Multi-Stage Adaptive Review Architecture (v2.0.0). Reference standard for [mas-reviewer](../../mas-reviewer/SKILL.md) synthesis, verdict determination, and delta re-reviews.

---

## Purpose

Stage 3 synthesizes mechanical checks from Stage 1 and domain evaluations from Stage 2 into a binding, objective review verdict (`Approved: YES | NO`).

The Arbiter enforces:
1. **Evidence Anchor Contracts** to eliminate vague or speculative objections.
2. The **4-Rule False-Positive Suppression Filter** to reject compiler hallucinations and phantom nullability claims.
3. Strict **Severity & Confidence Scoring**.
4. **Actionable Remediation Patches** for every blocking finding.
5. The **Delta-Only Re-Review Protocol** for iteration 2+ to prevent review ping-pong loops.

---

## Evidence Anchor Contract

Every finding marked `CRITICAL` or `MAJOR` **MUST** satisfy the Evidence Anchor Contract:

```markdown
#### [CRITICAL-01] or [MAJOR-01] Title
- **Domain:** RootCause | Security | Concurrency | Migration | VisualQA | Contract | Architecture
- **Confidence:** HIGH | MEDIUM | LOW
- **Anchor:** path/to/File.ext#Lstart-Lend
- **Defect Description:** Concrete explanation of flaw, crash, data corruption, or contract breach.
- **Reproducing Scenario / Trigger:** Runtime input, state transition, or event sequence exposing defect.
- **Actionable Remediation:** Drop-in code replacement snippet or exact corrective shell command.
```

### Line Range & Anchor Rules

- **Syntax:** `path/to/file.ext#Lstart-Lend` (e.g. `core/model/User.kt#L45-L52`) or `path/to/file.ext#Lline`.
- Anchors must reference actual modified lines or directly affected call sites in the repository.
- **File-level anchors** (`path/to/file.ext`) are allowed **ONLY** for systemic architectural violations (such as forbidden cross-module dependencies or package declarations), and must include a concrete trigger scenario.
- Speculative claims without verifiable line anchors are strictly prohibited.

---

## Four-Rule False-Positive Suppression Filter

Prior to emitting any finding into `## Findings`, the Arbiter passes it through four deterministic filters. Findings failing these rules are discarded or forced to `ADVISORY`:

```
                  [Raw Proposed Finding]
                            ↓
┌────────────────────────────────────────────────────────┐
│ RULE 1: Evidence Anchor & Reproducible Scenario Check  │
│  - Has valid path/to/File.ext#Lxx-Lyy?                │
│  - Documents concrete trigger/repro sequence?          │
└───────────────────────────┬────────────────────────────┘
               NO ──────────┴──────────► [DISCARD or Downgrade to ADVISORY]
              YES
                            ↓
┌────────────────────────────────────────────────────────┐
│ RULE 2: Type-System Invariance Check                   │
│  - Does finding allege NPE / null crash on a type      │
│    marked non-nullable by Kotlin / TypeScript / DB?    │
└───────────────────────────┬────────────────────────────┘
              YES ──────────┴──────────► [SUPPRESS / DISCARD (Type System Valid)]
               NO
                            ↓
┌────────────────────────────────────────────────────────┐
│ RULE 3: Compilation Truth Check                        │
│  - Does finding claim missing import, syntax error, or │
│    unresolved class when Stage 1 build passed?         │
└───────────────────────────┬────────────────────────────┘
              YES ──────────┴──────────► [SUPPRESS / DISCARD (Compiler Truth)]
               NO
                            ↓
┌────────────────────────────────────────────────────────┐
│ RULE 4: Style vs Correctness Isolation                 │
│  - Is the finding a stylistic preference, naming nit,  │
│    or cosmetic comment request?                        │
└───────────────────────────┬────────────────────────────┘
              YES ──────────┴──────────► [Force Severity to ADVISORY (Non-Blocking)]
               NO
                            ↓
                [Emit as CRITICAL or MAJOR Blocker]
```

### Rule Definitions

1. **Rule 1 (Evidence Anchor):**  
   Any finding that cannot cite an exact file and line range with a plausible runtime trigger scenario is invalid. Statements such as *"In rare cases this might fail"* without a concrete state sequence are discarded.
2. **Rule 2 (Type-System Invariance):**  
   The reviewer **MUST NOT** flag potential `NullPointerException` or nullability issues on variables or return types that are strictly non-nullable in the programming language's type system (e.g. Kotlin non-nullable `String`, TypeScript strict `interface`, Rust non-Option types, database columns with `NOT NULL`).
3. **Rule 3 (Compilation Truth):**  
   The reviewer **MUST NOT** claim that an import is missing, a symbol is unresolved, or a class does not exist if Stage 1 compilation and `ReadLints` passed cleanly. Stage 1 tool execution has absolute authority over syntax and classpath validity.
4. **Rule 4 (Style vs Correctness):**  
   Stylistic opinions, personal architectural philosophies, subjective variable naming preferences, and optional code comment requests are strictly classified as `ADVISORY`. An advisory finding **CANNOT** be marked `Critical` or `Major` and **CANNOT** cause `Approved: NO`.

---

## Severity & Confidence Rating Matrix

| Severity | Definition | Confidence Required | Impact on Approval | Examples |
|---|---|:---:|:---:|---|
| **`CRITICAL`** | Crash, data loss/corruption, remote code execution, SQL injection, leaked credential, or Stage 1 build break. | `HIGH` | **Blocks Approval** (`Approved: NO`) | Raw SQL concatenation; unhandled null pointer on nullable DB field; hardcoded API secret; infinite recomposition loop. |
| **`MAJOR`** | Functional bug, broken PRD acceptance criteria, missing bugfix regression test, contract breach, missing error UI state. | `HIGH` or `MEDIUM` | **Blocks Approval** (`Approved: NO`) | Bugfix lacks repro unit test; mutative API lacks idempotency; Compose screen lacks Error state handling; missing 40-char SHA pin in CI. |
| **`ADVISORY`** | Stylistic improvement, non-blocking naming convention, documentation polish, optional perf optimization hint. | Any | **Never Blocks** (`Approved: YES` permitted) | Renaming variable for clarity; adding KDoc to internal helper; splitting large composable into smaller functions. |

---

## Approval Gate Threshold

`Approved: YES` strictly requires all of the following:
1. **Stage 1 PASS**: All mechanical tools passed (or tests `NOT_RUN` with approved rationale).
2. **0 Critical Findings**: No unsuppressed `CRITICAL` findings.
3. **0 Major Findings**: No unsuppressed `MAJOR` findings.
4. **Profile Invariants Satisfied**: All mandatory domain invariants verified.
5. **Issue Resolved (Bugfix only)**: On `bugfix` profile, requires explicit `Issue Resolved: YES`.

Any `CRITICAL` or `MAJOR` finding mandates **`Approved: NO`**.  
`ADVISORY` findings **never** block approval.

---

## Delta-Only Re-Review Protocol

When a developer submits a revised changeset following an `Approved: NO` verdict, review enters iteration 2+.

### Coordinator Injection
Coordinator marks handoff with:
```markdown
REVIEW_SCOPE: delta-only
REVIEW_ITERATION: 2
PREVIOUS_BLOCKERS:
  - ID: [MAJOR-01]
    Anchor: core/src/data/Repository.kt#L45-L52
    Summary: Missing SQL parameterization in query
```

### Reviewer Boundary Invariants
1. **Scope Restriction:** Reviewer evaluates **ONLY**:
   - Verification that `PREVIOUS_BLOCKERS` are cleanly remediated.
   - Regression analysis of the exact delta lines modified between iteration 1 and 2.
2. **Prohibition of New Blockers on Unchanged Code:** Reviewer is **strictly forbidden** from raising new `Critical` or `Major` findings against code that was present and unchanged during iteration 1.
3. Any newly discovered issue in unchanged code must be recorded as `ADVISORY` for future debt tracking.

### Verification Output Envelope
```markdown
## Delta Re-Review Verification

| Previous Blocker ID | Remediated? | Evidence Anchor | Notes |
|---|---|---|---|
| [MAJOR-01] | YES | core/src/data/Repository.kt#L45-L55 | Parameterized query implemented |
```
