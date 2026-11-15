# Architecture Brief — REV-01: Multi-Stage Adaptive Review Architecture

## Architecture

**Modular 3-Stage Adaptive Review Architecture with Situation-Specific Profiles, Deterministic Fast-Fail Circuit Breaker, and False-Positive Suppressed Arbiter Synthesis** (implementing Option 4 from `.ai/context/brainstorms/REV-01.md` and `.ai/context/plans/REV-01.md`).

This architecture represents the **v2.0.0 evolution** of the Multi-Agent System (MAS) review subsystem. It dissolves the legacy 825-line monolithic `mas-reviewer` agent—which accumulated 15 disjoint, conditional pre-checks (`0`, `0b`–`0o`) and 8 numbered general steps across MAS-04 through MAS-11—into a disciplined, high-reliability, 3-stage review lifecycle:

1. **Stage 1: Deterministic Mechanical Gate (Fast-Fail Circuit Breaker)**  
   Executes deterministic host tools prior to invoking semantic LLM reasoning: static linter (`ReadLints`), build compilation via host mutex (`mas-host-exec`), unit test execution (`mas-host-exec`), and secret/diff hygiene. A hard **circuit breaker** immediately halts evaluation upon any tool failure with `Approved: NO` and raw compiler diagnostics, saving $\ge 75\%$ prompt tokens on uncompilable diffs.
2. **Stage 2: Situation-Adaptive Domain Deep-Dive**  
   Replaces monolithic checklist bloat with modular, domain-specific review profiles loaded dynamically from `skills/multi-agent-system/references/review-profiles/` (`bugfix.md`, `ui.md`, `backend.md`, `infra.md`, `genai.md`, `feature.md`, `refactor.md`, and `reviewer-lite.md`). The active profile is determined via zero-token Coordinator predicates or handoff metadata, focusing LLM attention strictly on domain-relevant invariants.
3. **Stage 3: Arbiter Synthesis with Evidence Anchors & False-Positive Suppression**  
   Synthesizes domain findings into a binding verdict governed by an **Evidence Anchor Contract** (`path/to/File.ext#Lxx-Lyy` + trigger scenario), a **4-Rule False-Positive Suppression Filter** (eliminating speculative nullability claims, unanchored style nits, and compiler hallucinations), strict severity/confidence ratings, and actionable drop-in code remediations.
4. **Delta-Only Re-Review Protocol**  
   Eliminates developer-reviewer ping-pong loops by restricting subsequent review iterations to verifying previous blocker remediations and checking for regression deltas. New blocking issues on unchanged code are strictly forbidden.

`UI_SCOPE: logic-only` — framework protocols, reviewer skill architecture, reference standards, profile schemas, test fixtures, and automated PowerShell harnesses only. No user-facing Android Compose layouts or CSS components are modified.

---

### Core Architectural Invariants

1. **Deterministic Fast-Fail Invariant**: If code fails compilation, static linting, or automated tests in Stage 1, the review stops immediately. The reviewer MUST NOT load Stage 2 profiles or evaluate imaginary visual/semantic edge cases on broken code.
2. **Evidence Anchor Invariant**: No defect may be marked `Critical` or `Major` unless anchored to an exact file path, verifiable line range (`#Lstart-Lend`), and accompanied by a concrete reproducing trigger scenario.
3. **Sole Merge Authority**: `mas-reviewer` remains the sole framework gate issuing `Approved: YES | NO`. No specialist subagent (`mas-security-auditor`, `mas-backend-dev`, `mas-genai`, etc.) can bypass or self-approve review.
4. **Reviewer Prompt Line Budget**: The core `skills/mas-reviewer/SKILL.md` orchestrator is capped at $\le 180$ lines. All domain-specific verification rules reside in external profile reference documents ($\le 120$ lines each).
5. **Delta Re-Review Boundary**: On review iteration 2+, the reviewer is strictly bounded to validating fixes for previously reported blockers and ensuring no regressions were introduced. Flagging new blocking issues on code that was untouched since iteration 1 is prohibited.
6. **Backward Compatibility**: Reviewer gracefully degrades to auto-detecting review profiles from modified file patterns when `REVIEW_PROFILE` is omitted in legacy or Lite handoffs. All downstream coordinator output envelope contracts (`## Daily Summary`, `## Memory Update`, `Approved: YES | NO`, `DONE`) remain 100% invariant.

---

### End-to-End Execution Topology

```
                  [Coordinator / User Handoff]
                 (TASK_ID, FILES, REVIEW_PROFILE)
                                ↓
┌──────────────────────────────────────────────────────────────┐
│ STAGE 1: Deterministic Mechanical Gate                       │
│  1. ReadLints on changed FILES                               │
│  2. mas-host-exec Compile (e.g. ./gradlew :core:compileDebug) │
│  3. mas-host-exec Unit Tests (e.g. ./gradlew :core:testDebug) │
│  4. Diff & Secret Scan (regex / git hygiene)                 │
└──────────────────────────────┬───────────────────────────────┘
                               │
            ┌──────────────────┴──────────────────┐
     [FAIL: Exit != 0]                     [PASS: All Clean]
            │                                     │
            ▼                                     ▼
 ┌──────────────────────┐      ┌──────────────────────────────────────┐
 │ FAST-FAIL TERMINATION│      │ STAGE 2: Situation-Adaptive Profiles │
 │  - Trip CircuitBreak │      │  Load references/review-profiles/    │
 │  - Raw Diagnostics   │      │  • bugfix.md    • ui.md      • genai │
 │  - Approved: NO      │      │  • backend.md   • infra.md   • feature│
 │  - Exit immediately  │      │  • refactor.md  • lite.md            │
 └──────────────────────┘      └──────────────────┬───────────────────┘
                                                  │
                                                  ▼
                               ┌──────────────────────────────────────┐
                               │ STAGE 3: Arbiter Synthesis           │
                               │  1. Evidence Anchor Verification     │
                               │  2. 4-Rule False-Positive Filter     │
                               │  3. Confidence & Severity Scoring    │
                               │  4. Actionable Remediation Patch     │
                               └──────────────────┬───────────────────┘
                                                  │
            ┌─────────────────────────────────────┴───────────────────┐
   [Blockers: Critical > 0 OR Major > 0]                      [0 Critical AND 0 Major]
            │                                                         │
            ▼                                                         ▼
 ┌──────────────────────────────────────┐                  ┌──────────────────────┐
 │ Approved: NO                         │                  │ Approved: YES        │
 │ Actionable Fix Snippets              │                  │ Daily Summary        │
 │ Returns to Coordinator -> Dev        │                  │ Memory Update Entry  │
 └──────────────────────────────────────┘                  └──────────────────────┘
```

---

## Architect Gate Decisions (Phase 0 — D1–D10 Confirmed)

Binding decisions formulated for downstream development (`general-dev`, `test-strategy`, `test-executor`, `documenter`, `reviewer`).

| # | Question / Decision Area | **Binding Decision** | Rationale |
|---|--------------------------|----------------------|-----------|
| **D1** | Stage 1 Tool Invocation Sequence & Exit Code Mapping | **Tool sequence is strictly ordered: `ReadLints` (FILES) $\rightarrow$ Compilation via `mas-host-exec` $\rightarrow$ Unit Tests via `mas-host-exec` $\rightarrow$ Secret/Diff scan.** Any non-zero exit code or static lint error constitutes an immediate failure. | Catches mechanical and compiler defects before burning model tokens on semantic deep-dives. Ensures host lock safety via MAS-10. |
| **D2** | Fast-Fail Circuit Breaker Halt Contract | **When Stage 1 fails, reviewer outputs `Stage 1 Gate Status: FAIL`, emits raw compiler/linter error output, sets `Approved: NO`, and halts immediately without loading Stage 2 profiles or executing Stage 3.** | Eliminates token waste and stops LLM hallucinations on syntactically invalid or uncompilable code. Slashes token usage by $\ge 75\%$ on broken diffs. |
| **D3** | Profile Directory Layout & Naming | **Directory is `skills/multi-agent-system/references/review-profiles/`. Seven profiles: `bugfix.md`, `ui.md`, `backend.md`, `infra.md`, `genai.md`, `feature.md`, `refactor.md`. Lite mode continues using `reviewer-lite.md` with an alias link.** | Provides modular, human-readable reference standards isolated by technical discipline; keeps each profile below 120 lines. |
| **D4** | Zero-Token Profile Resolution & Composite Profiles | **Coordinator evaluates deterministic file path, handoff tag, and specialist chain predicates. Primary profile is emitted in handoff `REVIEW_PROFILE: <primary>`. Composite tasks support secondary profiles: `REVIEW_PROFILE: feature (secondary: backend, genai)`.** | Eliminates conversational routing tokens; enables multi-discipline tasks (e.g. mobile app with backend sync and LLM summarization) to combine relevant checklist slices. |
| **D5** | Evidence Anchor Syntax & Defect Schema | **Evidence Anchor syntax is strictly `path/to/File.ext#Lstart-Lend` (e.g. `core/model/User.kt#L45-L52`). Every finding must define ID, Domain, Confidence, Severity, Anchor, Defect Description, Reproducing Scenario, and Actionable Remediation.** | Pinpoints exact defective lines, proves realistic defect exploitability, and prevents hand-waving speculative objections. |
| **D6** | Four False-Positive Suppression Rules | **Enforce 4 deterministic suppression rules:**<br>1. *Rule 1 (Evidence Anchor):* Drop or downgrade unanchored claims.<br>2. *Rule 2 (Type-System Invariance):* Prohibit flagging NPEs on non-null language types.<br>3. *Rule 3 (Compilation Truth):* Prohibit flagging missing imports/symbols if Stage 1 passed.<br>4. *Rule 4 (Style vs Correctness):* Cosmetic, naming, and stylistic feedback are strictly `ADVISORY` and cannot block approval. | Solves the primary cause of developer frustration: phantom nullability bugs, compiler hallucinations, and nitpick ping-pong loops. |
| **D7** | Severity Criteria & Approval Gate Threshold | **`Approved: YES` strictly requires: Stage 1 PASS, 0 Critical findings, 0 Major findings, and Profile Invariants satisfied. For `bugfix`, also requires `Issue Resolved: YES`. Any Critical or Major finding mandates `Approved: NO`. `ADVISORY` findings never block approval.** | Establishes a deterministic, non-negotiable quality gate that treats stylistic opinions as advisory while holding functional and security defects to zero tolerance. |
| **D8** | Delta-Only Re-Review Protocol | **On re-review loops (iteration 2+), Coordinator injects `REVIEW_SCOPE: delta-only` and `PREVIOUS_BLOCKERS: [...]`. The reviewer verifies fixes for previously flagged blockers and checks for regression deltas only. Emitting new blockers on unchanged code is prohibited.** | Prevents infinite review ping-pong where reviewer discovers new unrelated stylistic complaints on each subsequent turn. |
| **D9** | Monolith Refactoring & Prompt Size Budget | **`skills/mas-reviewer/SKILL.md` is refactored from 825 lines down to $\le 180$ lines. Monolithic steps 0 and 0b–0o are factored out into domain profiles.** If handoff omits `REVIEW_PROFILE`, reviewer falls back to auto-detecting domain from changed file extensions and paths. | Drastically improves LLM attention focus, cuts context window bloat, and makes the core reviewer logic highly maintainable. |
| **D10** | Framework Version Bump | **Bump framework version from `1.9.0` to `2.0.0` in `install/manifest.json`.** | Represents a major architectural evolution of the core review engine, introducing staged gates, modular profiles, and revised review schemas. |

---

## Modules:

Logical packaging across the framework repository.

| Module | Path / Location | Purpose |
|--------|-----------------|---------|
| **ReviewerCore** | `skills/mas-reviewer/SKILL.md` | Lean stage controller ($\le 180$ lines) orchestrating Stage 1 $\rightarrow$ Stage 2 $\rightarrow$ Stage 3. |
| **MechanicalGate** | `skills/multi-agent-system/references/review-stage-gate.md` | Specification of Stage 1 deterministic tool execution, exit code mapping, and fast-fail circuit breaker. |
| **ArbiterEngine** | `skills/multi-agent-system/references/review-arbiter-standards.md` | Specification of Stage 3 evidence anchor format, 4-rule false-positive filter, severity/confidence definitions, and actionable remediation. |
| **ProfileRegistry** | `skills/multi-agent-system/references/review-profiles/` | Modular domain verification profiles:<br>• `bugfix.md` — Root cause depth, repro verification, regression test proof.<br>• `ui.md` — Visual QA fidelity (0k), design-spec schema (0j), sealed UiState, a11y, responsive.<br>• `backend.md` — Clean architecture (0n), forward migrations, parameterized SQL, idempotency, auth.<br>• `infra.md` — Container rootless (0o), SHA-pinned actions, zero secret leaks, health probes.<br>• `genai.md` — XML prompt tags (0l), strict tool schemas, $\ge 6\text{GB}$ RAM guards, eval metrics.<br>• `feature.md` — PRD acceptance (0m), 20-point edge cases, similar flow consistency, KDoc.<br>• `refactor.md` — Behavioral invariance, zero contract drift, perf budgets (0b), test parity. |
| **ReviewerLite** | `skills/multi-agent-system/references/reviewer-lite.md` | Lightweight single-turn gate for MAS Lite mode (`RP:` tag support). |
| **CoordinatorRouting** | `skills/mas-coordinator/SKILL.md`<br>`skills/multi-agent-system/SKILL.md` | Zero-token profile detection table, composite profile injection, and delta-only re-review loop enforcement. |
| **ProtocolSchemas** | `skills/multi-agent-system/protocol/handoff-format.md`<br>`skills/multi-agent-system/protocol/handoff-format-lite.md`<br>`skills/multi-agent-system/protocol/read-order.md` | Handoff metadata specifications (`REVIEW_PROFILE`, `REVIEW_SCOPE`, `PREVIOUS_BLOCKERS`, `RP:`) and context read order. |
| **FixtureHarness** | `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/`<br>`skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1` | Comprehensive offline test fixture suite and PowerShell test driver validating fast-fail, profile routing, false-positive suppression, and delta re-review. |
| **InstallManifest** | `skills/multi-agent-system/install/manifest.json` | Version bump to `2.0.0`; registration of new reference documents and profile files. |

---

## Layers:

Review lifecycle layers and execution progression:

| Layer | Name | Responsibility | Inputs / Trigger | Outputs |
|-------|------|----------------|------------------|---------|
| **L0** | **Dispatch & Resolution** | Evaluates zero-token predicates; assigns `REVIEW_PROFILE` and `REVIEW_SCOPE` in handoff. | Task ID, modified file list, prior agent chain. | Structured handoff `.ai/handoffs/{TASK_ID}.md`. |
| **L1** | **Deterministic Mechanical Gate** | Executes `ReadLints`, compile check, unit tests, secret scan. Trips circuit breaker on error. | Changed `FILES`, project build configs, MAS host mutex. | `## Stage 1: Mechanical Gate Results`<br>(PASS $\rightarrow$ proceed; FAIL $\rightarrow$ halt). |
| **L2** | **Situation-Adaptive Deep-Dive** | Loads active profile reference; executes targeted domain checklist; assesses invariants. | Selected profile (`bugfix`, `ui`, `backend`, etc.), deliverable briefs. | Domain checklist evaluations, defect observations. |
| **L3** | **Arbiter Synthesis & Quality Gate** | Applies 4-Rule False-Positive Filter; assigns confidence/severity; formats actionable patch; renders verdict. | Raw findings from L1 & L2, evidence anchor rules. | `## Findings`, `Approved: YES \| NO`, remediation patches. |
| **L4** | **Telemetry & Durable Memory** | Generates one-line changelog summary, proposes durable memory updates, outputs token report. | Review findings, architectural lessons learned. | `## Daily Summary`, `## Memory Update`, `## Usage Report`, `DONE`. |

---

## Contracts:

### Contract 1: Stage 1 Mechanical Gate & Fast-Fail Contract

#### 1. Tool Invocation Sequence
Stage 1 executes deterministic tools via PowerShell and the MAS host mutex (`mas-host-exec`):
1. **Linter Check:** Call `ReadLints` on each file in handoff `FILES`.
2. **Compilation Check:** Wrap build command in host mutex:
   ```powershell
   # Android Gradle example
   mas-host-exec --task-id {TASK_ID} -- ./gradlew :module:compileDebugKotlin
   # Node / TypeScript example
   mas-host-exec --task-id {TASK_ID} -- npm run build
   # Python example
   mas-host-exec --task-id {TASK_ID} -- python -m py_compile {FILES}
   ```
3. **Automated Unit Tests:** Execute affected unit test suite:
   ```powershell
   mas-host-exec --task-id {TASK_ID} -- ./gradlew :module:testDebugUnitTest
   ```
4. **Secret & Diff Hygiene Scan:** Regex scan modified diffs for committed API keys, tokens, or private secrets (`AKIA[0-9A-Z]{16}`, `AIza[0-9A-Za-z\\-_]{35}`, `ghp_[0-9a-zA-Z]{36}`, etc.).

#### 2. Exit Code & Result Mapping
| Check | Tool / Command | PASS Condition | FAIL Condition |
|-------|----------------|----------------|----------------|
| **Static Linter** | `ReadLints` | 0 errors | $\ge 1$ error on modified lines |
| **Compilation** | `mas-host-exec <build>` | Exit code `0` | Exit code $\ne 0$ |
| **Unit Tests** | `mas-host-exec <test>` | Exit code `0` (or `NOT_RUN` with approved rationale) | Exit code $\ne 0$ (failing assertions) |
| **Secret Scan** | Git diff regex | 0 pattern matches | $\ge 1$ match for credentials/secrets |

#### 3. Fast-Fail Circuit Breaker Output Envelope
If ANY check in Stage 1 results in `FAIL`:
```markdown
## Stage 1: Mechanical Gate Results

| Check | Tool / Command | Exit Code | Result | Diagnostics |
|-------|----------------|-----------|--------|-------------|
| Static Linter | ReadLints (FILES) | 1 | FAIL | 2 syntax errors detected |
| Compilation | mas-host-exec ./gradlew :core:compileDebugKotlin | 1 | FAIL | Unresolved reference: 'UserProfile' |
| Unit Tests | mas-host-exec ./gradlew :core:testDebugUnitTest | — | SKIPPED | Blocked by compilation failure |
| Secret Scan | Diff regex scan | 0 | PASS | Clean |

Stage 1 Gate Status: FAIL (Circuit Breaker Tripped)

### Mechanical Diagnostics
```text
core/src/main/java/com/example/UserProfile.kt:42:15: error: unresolved reference: UserAvatar
core/src/main/java/com/example/UserProfile.kt:88:9: error: missing return statement
```

Approved: NO

## Daily Summary
Fast-fail mechanical gate tripped: compilation failure in :core:compileDebugKotlin.

## Memory Update
None

## Usage Report
Model: inherit
Class: normal
Tokens: unknown

DONE
```

*Invariant:* When `Stage 1 Gate Status: FAIL` is emitted, execution terminates immediately. No Stage 2 profile files are loaded, no visual QA is performed, and no subjective edge cases are evaluated.

---

### Contract 2: Stage 2 Review Profile Registry & Specification Contracts

All profiles reside in `skills/multi-agent-system/references/review-profiles/{profile}.md`. Each profile defines domain-specific invariants and requires explicit `Handled | Missing | N/A` checklist outputs.

#### 1. Zero-Token Profile Resolution Predicate Matrix
Coordinator automatically resolves the review profile using this precedence order:

| Precedence | Profile Slug | Trigger Condition (Deterministic Predicates) | Target Domain Focus | Active Profile Reference |
|:---:|---|---|---|---|
| **P0** | `bugfix` | Handoff contains `ORIGINAL_SYMPTOM`, `ROOT_CAUSE`, or `REPRO_STEPS`; or `bug-fix` in chain. | Root cause depth, repro verification, regression test presence, no symptom masking. | `references/review-profiles/bugfix.md` |
| **P1** | `ui` | `UI_CHANGES: YES`, `design-specs/{TASK_ID}.md` exists, or changed files touch Compose/XML/CSS/layout. | Visual QA fidelity (0k), design-spec schema (0j), sealed UiState, touch targets $\ge 48\text{dp}$, responsive, a11y. | `references/review-profiles/ui.md` |
| **P2** | `backend` | Files touch `server/`, `api/`, `db/`, `migrations/`, `entities/`, or `mas-backend-dev` in chain. | Clean architecture (0n), forward-only DB migrations, SQL parameterization, idempotency keys, RBAC auth. | `references/review-profiles/backend.md` |
| **P3** | `infra` | Files touch `Dockerfile`, `.github/`, `k8s/`, `terraform/`, `scripts/`, or `mas-devops` in chain. | Rootless containers (0o), 40-char pinned commit SHAs, zero secret leaks, health probes (`/healthz`). | `references/review-profiles/infra.md` |
| **P4** | `genai` | `.ai/context/genai/{TASK_ID}.md` exists, or files touch LLM clients, prompt templates, RAG retrievers. | XML prompt tags (0l), strict tool JSON schemas, on-device $\ge 6\text{GB}$ RAM guards, eval metrics. | `references/review-profiles/genai.md` |
| **P5** | `refactor` | `.ai/context/optimizations/{TASK_ID}.md` exists or handoff scope notes refactor/performance. | Behavioral invariance, zero contract drift, performance budgets (0b), list paging, test suite parity. | `references/review-profiles/refactor.md` |
| **P6** | `feature` | Default full `/mas` workflow; multi-tier implementation; standard greenfield feature. | PRD acceptance (0m), 20-point edge cases, architectural layering, similar flow consistency, KDoc. | `references/review-profiles/feature.md` |
| **—** | `lite` | `MODE: LITE` or `REVIEWER_MODE: lite` in handoff. | Minimal single-turn mechanical check + one-line visual/perf/test check. | `references/reviewer-lite.md` |

#### 2. Composite Profile Specification
When a feature touches multiple technical domains (e.g. mobile UI calling a backend API with GenAI streaming), Coordinator emits a composite profile string:
```text
REVIEW_PROFILE: feature (secondary: backend, genai)
```
- **Execution Rule:** Reviewer loads primary profile `review-profiles/feature.md`, plus the specific checklist sections from secondary profile references (`review-profiles/backend.md` and `review-profiles/genai.md`).
- **Section Envelope:** Secondary checks are rendered as subsections under `## Stage 2: Domain Deep-Dive`:
  - `### Secondary Audit: backend`
  - `### Secondary Audit: genai`

#### 3. Mandatory Checklist Requirements per Profile
- **`bugfix.md`:** Must contain `## Bug Resolution Verification` table evaluating: (1) Root Cause addressed, (2) Repro Steps re-run, (3) Automated regression test added, (4) No symptom masking. Requires explicit `Issue Resolved: YES | NO`.
- **`ui.md`:** Must contain `## Visual QA (Fidelity or Imagined)` table and `## Android Veteran UI Gates` table. Verifies sealed `UiState`, touch targets $\ge 48\text{dp}$, responsive breakpoints, fontScale.
- **`backend.md`:** Must contain `## Backend Architecture & Migration Verification` table. Verifies layering (Domain/Repository/DataSource), forward migrations, zero raw SQL string concatenation, idempotency keys on mutative APIs.
- **`infra.md`:** Must contain `## Platform & DevOps Verification` table. Verifies non-root container users, 40-char SHA pinning for actions, zero unmasked secrets in configs, health probes present.
- **`genai.md`:** Must contain `## GenAI Specification & Evaluation Verification` table. Verifies XML prompt boundary tags, strict JSON schemas for tools, device $\ge 6\text{GB}$ RAM guard, eval assertions.
- **`feature.md`:** Must contain `## PRD Acceptance Verification` table and `## 20-Point Edge Case Matrix`.
- **`refactor.md`:** Must contain `## Refactor & Behavioral Invariance Verification` table. Verifies zero contract drift and performance metrics.

---

### Contract 3: Stage 3 Arbiter Schema & Evidence Anchor Contract

Stage 3 synthesizes all findings into a deterministic report. Every non-advisory defect MUST comply with the **Evidence Anchor Contract**.

#### 1. Finding Schema
```markdown
### Finding Schema
- **ID:** `[CRITICAL-01]` | `[MAJOR-01]` | `[ADVISORY-01]`
- **Domain:** `RootCause` | `Security` | `Concurrency` | `Migration` | `VisualQA` | `Contract` | `Architecture`
- **Confidence:** `HIGH` | `MEDIUM` | `LOW`
- **Anchor:** `path/to/File.ext#Lstart-Lend`
- **Defect Description:** Concrete explanation of the flaw, crash, data corruption, or contract breach.
- **Reproducing Scenario / Trigger:** Input, state transition, or event sequence that exposes the defect.
- **Actionable Remediation:** Drop-in code replacement snippet or exact corrective shell command.
```

#### 2. Evidence Anchor Syntax & Line Range Rules
- Syntax: `path/to/file.ext#Lstart-Lend` or `path/to/file.ext#Lline` (e.g. `feature/auth/src/AuthRepository.kt#L104-L112`).
- The line range MUST correspond to actual modified lines or directly affected call sites in the repository.
- File-level anchor `path/to/file.ext` is permitted ONLY for systemic architecture violations (e.g. invalid layer dependency in package declaration), provided a concrete trigger scenario is documented.

#### 3. Confidence & Severity Rating Matrix
| Severity | Definition | Confidence Required | Impact on Approval | Examples |
|---|---|:---:|:---:|---|
| **`CRITICAL`** | Crash, data loss/corruption, remote code execution, SQL injection, leaked credential, or Stage 1 build break. | `HIGH` | **Blocks Approval** (`Approved: NO`) | Raw SQL concatenation; unhandled null pointer on nullable DB field; hardcoded API secret; infinite recomposition loop. |
| **`MAJOR`** | Functional bug, broken PRD acceptance criteria, missing bugfix regression test, contract breach, missing error UI state. | `HIGH` or `MEDIUM` | **Blocks Approval** (`Approved: NO`) | Bugfix lacks repro unit test; mutative API lacks idempotency; Compose screen lacks Error state handling; missing 40-char SHA pin in CI. |
| **`ADVISORY`** | Stylistic improvement, non-blocking naming convention, documentation polish, optional perf optimization hint. | Any | **Never Blocks** (`Approved: YES` permitted) | Renaming variable for clarity; adding KDoc to internal helper; splitting large composable into smaller functions. |

---

### Contract 4: Four-Rule False-Positive Suppression Filter Specification

Before emitting any finding into `## Findings`, the Reviewer Arbiter passes it through four suppression rules. Findings violating these rules are automatically discarded or downgraded to `ADVISORY`.

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

#### Detailed Rule Definitions
1. **Rule 1 (Evidence Anchor):** Any finding that cannot cite an exact file and line range with a plausible runtime trigger scenario is invalid. Speculative statements such as *"In some rare cases this might fail"* without a concrete state sequence are discarded.
2. **Rule 2 (Type-System Invariance):** The reviewer MUST NOT flag potential `NullPointerException` or nullability issues on variables or return types that are strictly non-nullable in the programming language's type system (e.g., Kotlin non-nullable `String`, TypeScript strict `interface`, Rust non-Option types).
3. **Rule 3 (Compilation Truth):** The reviewer MUST NOT claim that an import is missing, a symbol is unresolved, or a class does not exist if Stage 1 compilation and `ReadLints` passed cleanly. Stage 1 tools have absolute authority over syntax and classpath validity.
4. **Rule 4 (Style vs Correctness):** Stylistic opinions, personal architectural philosophies, subjective variable naming preferences, and optional code comment requests are strictly classified as `ADVISORY`. An advisory finding CANNOT be marked `Critical` or `Major` and CANNOT cause `Approved: NO`.

---

### Contract 5: Delta-Only Re-Review Protocol Contract

When a developer submits a revised changeset following an `Approved: NO` verdict, the workflow enters review iteration 2+. The Delta-Only Re-Review Protocol governs this phase to eliminate review ping-pong loops:

1. **Handoff Contract for Iteration 2+:**
   Coordinator injects iteration context into the handoff:
   ```markdown
   REVIEW_SCOPE: delta-only
   REVIEW_ITERATION: 2
   PREVIOUS_BLOCKERS:
     - ID: [MAJOR-01]
       Anchor: core/src/data/Repository.kt#L45-L52
       Summary: Missing SQL parameterization in query
     - ID: [MAJOR-02]
       Anchor: feature/auth/src/AuthViewModel.kt#L88-L94
       Summary: Missing Error state emission on network failure
   ```
2. **Review Scope Restriction:**
   The reviewer is permitted to evaluate ONLY:
   - Verification that the specific `PREVIOUS_BLOCKERS` have been cleanly remediated.
   - Regression analysis of the exact delta lines modified between iteration 1 and iteration 2.
3. **Prohibition of New Blockers on Unchanged Code:**
   The reviewer is strictly forbidden from raising new `Critical` or `Major` findings against code that was present and unchanged during iteration 1. Any newly discovered issue in unchanged code must be recorded as `ADVISORY` for future debt tracking.
4. **Iteration Output Envelope:**
   The reviewer output includes a dedicated verification section:
   ```markdown
   ## Delta Re-Review Verification
   | Previous Blocker ID | Remediated? | Evidence Anchor | Notes |
   |---|---|---|---|
   | [MAJOR-01] | YES | core/src/data/Repository.kt#L45-L55 | Parameterized query implemented |
   | [MAJOR-02] | YES | feature/auth/src/AuthViewModel.kt#L88-L98 | Emits UiState.Error(msg) on catch |
   ```

---

### Contract 6: Full Reviewer Output Envelope Specification

When Stage 1 passes, the reviewer produces this standardized output structure:

```markdown
## Stage 1: Mechanical Gate Results

| Check | Tool / Command | Exit Code | Result | Diagnostics |
|-------|----------------|-----------|--------|-------------|
| Static Linter | ReadLints (FILES) | 0 | PASS | Clean (0 errors, 0 warnings) |
| Compilation | mas-host-exec ./gradlew :core:compileDebugKotlin | 0 | PASS | Build successful in 4.2s |
| Unit Tests | mas-host-exec ./gradlew :core:testDebugUnitTest | 0 | PASS | 14 passed, 0 failed |
| Secret Scan | Diff regex scan | 0 | PASS | Clean |

Stage 1 Gate Status: PASS (Proceed to Stage 2)

## Stage 2: Domain Deep-Dive (Profile: {profile})

{Profile-Specific Checklist Tables from references/review-profiles/{profile}.md}

## Stage 3: Arbiter Synthesis

### Findings

#### [MAJOR-01] Unhandled Room SQLite Exception on Unique Constraint Violation
- **Domain:** Backend
- **Confidence:** HIGH
- **Anchor:** core/data/src/main/java/com/example/data/UserRepositoryImpl.kt#L64-L72
- **Defect Description:** Inserting a duplicate email throws SQLiteConstraintException, crashing the caller because the coroutine dispatcher lacks an exception handler or Result wrapper.
- **Reproducing Scenario / Trigger:** User registers with an email that already exists in the local room database.
- **Actionable Remediation:**
```kotlin
// In core/data/src/main/java/com/example/data/UserRepositoryImpl.kt
try {
    userDao.insertUser(userEntity)
} catch (e: SQLiteConstraintException) {
    throw DuplicateUserException("Email already registered", e)
}
```

Approved:
YES | NO

## Daily Summary
<one line, ≤120 chars — Coordinator uses this for daily changelog append>

## Memory Update
<concise entry for memory.md, or "None">

## Usage Report
Model: inherit
Class: thinking
Tokens: unknown

DONE
```

---

## Responsive Strategy:

N/A — `UI_SCOPE: logic-only`. This architecture brief governs internal agent frameworks, review orchestration lifecycles, and verification protocols. It contains no Android presentation screens, Compose widgets, or responsive layout components.

*Note for UI Review Profile (`references/review-profiles/ui.md`):*  
When the Reviewer operates under the `ui` profile, responsive verification is strictly enforced against user-facing UI code using the following checklist dimensions:
- Compact (phone portrait, 360–400dp width) vs Medium (foldable/tablet portrait, 600dp) vs Expanded (tablet landscape, 840dp+).
- Support for `fontScale` accessibility scaling up to 2.0x without text clipping or button overflow.
- Proper handling of landscape orientation without obscuring primary action buttons.

---

## Files:

### 1. New Reference Standards & Domain Profiles

| File | Purpose |
|------|---------|
| `skills/multi-agent-system/references/review-stage-gate.md` | Authoritative specification of Stage 1 deterministic tool invocation, exit code mappings, and fast-fail circuit breaker. |
| `skills/multi-agent-system/references/review-arbiter-standards.md` | Authoritative specification of Stage 3 evidence anchor syntax, 4-rule false-positive suppression filter, severity/confidence matrices, and remediation formats. |
| `skills/multi-agent-system/references/review-profiles/bugfix.md` | Domain profile for bug fixes: root cause verification, repro steps re-run, regression test requirement, anti-symptom-masking rules. |
| `skills/multi-agent-system/references/review-profiles/ui.md` | Domain profile for UI changes: Visual QA fidelity (0k), design-spec schema (0j), sealed UiState, touch targets, accessibility, and responsive validation. |
| `skills/multi-agent-system/references/review-profiles/backend.md` | Domain profile for backend changes: Clean architecture (0n), forward-only safe DB migrations, SQL parameterization, idempotency keys, and RBAC. |
| `skills/multi-agent-system/references/review-profiles/infra.md` | Domain profile for DevOps & platform: Rootless containers (0o), 40-character pinned commit SHAs, zero secret leaks, health probes (`/healthz`). |
| `skills/multi-agent-system/references/review-profiles/genai.md` | Domain profile for GenAI changes: XML prompt boundary tags (0l), strict JSON schemas, on-device $\ge 6\text{GB}$ RAM guards, eval metrics. |
| `skills/multi-agent-system/references/review-profiles/feature.md` | Domain profile for greenfield features: PRD acceptance (0m), 20-point edge case matrix, architectural layering, and public KDoc. |
| `skills/multi-agent-system/references/review-profiles/refactor.md` | Domain profile for refactoring and perf: Behavioral invariance, zero contract drift, performance budgets (0b), and test suite parity. |

### 2. Modified Agent Skills & Protocols

| File | Modification Details |
|------|----------------------|
| `skills/mas-reviewer/SKILL.md` | Major refactor: slashed from 825 lines to $\le 180$ lines. Orchestrates Stage 1 $\rightarrow$ Stage 2 $\rightarrow$ Stage 3. Delegates domain logic to `review-profiles/`. Retains exact Coordinator envelope. |
| `skills/mas-coordinator/SKILL.md` | Added zero-token profile resolution table, composite profile injection (`feature (secondary: backend)`), and delta-only re-review loop enforcement. |
| `skills/multi-agent-system/SKILL.md` | Updated reviewer role description and documentation of the 3-stage adaptive architecture. |
| `skills/multi-agent-system/protocol/handoff-format.md` | Documented `REVIEW_PROFILE:`, `REVIEW_SCOPE:`, and `PREVIOUS_BLOCKERS:` handoff metadata fields. |
| `skills/multi-agent-system/protocol/handoff-format-lite.md` | Documented `RP:` profile tag for Lite mode handoffs. |
| `skills/multi-agent-system/protocol/read-order.md` | Updated Reviewer context read order: reads `review-stage-gate.md`, `review-arbiter-standards.md`, and selected `review-profiles/{profile}.md`. |
| `skills/multi-agent-system/references/reviewer-lite.md` | Updated to align with 3-stage concepts while maintaining single-turn token frugality. |
| `skills/multi-agent-system/install/manifest.json` | Bumped framework version to `2.0.0`; registered new reference documents and review profile files in manifest inventory. |

### 3. Fixtures & Test Verification Scripts

| File | Purpose |
|------|---------|
| `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/fixture-01-fastfail-compile/` | Broken Kotlin syntax file fixture verifying Stage 1 trips circuit breaker immediately with `Approved: NO`. |
| `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/fixture-02-fastfail-lint/` | Static linter violation fixture verifying Stage 1 circuit breaker halts execution. |
| `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/fixture-03-profile-bugfix/` | Bugfix without regression test fixture verifying `MAJOR-01` emission. |
| `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/fixture-04-profile-ui/` | Compose UI lacking sealed UiState fixture verifying UI profile error/loading checks. |
| `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/fixture-05-profile-backend/` | Unparameterized SQL query fixture verifying backend profile SQL injection flag. |
| `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/fixture-06-false-positive-filter/` | Test input with non-null NPE claim and cosmetic style nit verifying suppression filter discards or downgrades to `ADVISORY`. |
| `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/fixture-07-delta-rereview/` | Second-review scenario fixture verifying unchanged code cannot have new blocking findings. |
| `skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1` | Standalone automated PowerShell test harness executing all 7 fixture scenarios and asserting pass/fail exit codes. |
| `.ai/context/test-strategies/REV-01.md` | Test strategy brief defining test matrix and acceptance verification. |
| `.ai/context/test-runs/REV-01.md` | Test execution brief recording automated test run evidence. |

---

## Usage Report

Model: default
Class: thinking
Tokens: unknown

DONE