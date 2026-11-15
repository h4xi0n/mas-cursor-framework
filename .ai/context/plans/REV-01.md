# Plan Brief — REV-01: Multi-Stage Adaptive Review Architecture

## Plan

Goal:
Transform `mas-reviewer` from an 825-line monolithic prompt into a modular, high-reliability **Multi-Stage Adaptive Review Architecture** (Option 4 from Brainstorm). Replace the unmaintainable 15-precheck monolith with a disciplined 3-stage review lifecycle:
1. **Stage 1 (Deterministic Fast-Fail Gate):** Execute automated mechanical checks (ReadLints, Gradle/command compilation via `mas-host-exec`, unit tests, secret scanning). Fast-fail circuit breaker terminates immediately on build/lint/test failure with `Approved: NO` and raw compiler diagnostics, saving ~80% tokens on broken diffs.
2. **Stage 2 (Situation-Adaptive Domain Deep-Dive):** Dynamically load domain-specific verification profiles from modular references in `skills/multi-agent-system/references/review-profiles/` (`bugfix`, `ui`, `backend`, `infra`, `genai`, `feature`, `refactor`, `lite`) tailored to the change, eliminating verbose boilerplate and deepening technical rigor.
3. **Stage 3 (Arbiter Synthesis & False-Positive Suppression):** Enforce strict Evidence Anchor contracts (`path/to/File.kt#Lxx-Lyy`), apply a 4-rule False-Positive Suppression Filter (type-system invariance, compiler truth, evidence anchors, style vs correctness isolation), assign confidence and severity, and generate drop-in actionable remediations for all blocking issues.
4. **Coordinator & Handoff Integration:** Add `REVIEW_PROFILE` predicate resolution and handoff schema fields, enforce Delta-Only Re-Review on rejection loops to eliminate reviewer-dev ping-pong.
5. **Fixture Verification & Dogfooding:** Offline fixture harness and automated test driver validating fast-fail, profile routing, false-positive suppression, and backward compatibility.

**Upstream Context:**
- Brainstorm Brief: `.ai/context/brainstorms/REV-01.md` (Option 4 Recommended).
- Handoff: `.ai/handoffs/REV-01.md`.
- Durable Memory: `.ai/context/memory.md` (MAS-04 audit specialists, MAS-05 Figma design-spec, MAS-06 visual-fidelity, MAS-07 connected device, MAS-10 host mutex `mas-host-exec`, MAS-11 product team expansion).
- Target Version: `2.0.0` (Major architecture evolution of the MAS review subsystem).

**Scope & UI:**
- `UI_SCOPE: logic-only`. No Android UI, layouts, or CSS changes. Focuses entirely on agent prompts, reference standards, routing logic, PowerShell test scripts, and test fixtures.

---

## Tasks

### Phase 0 — Architect Gate (Pre-Implementation Contracts)

1. **Architect validates Stage Contracts, Profile Schemas, and Re-Review Protocol**
   - **File:** `.ai/context/architecture/REV-01.md` (new)
   - **Decisions & Contracts required:**
     - **Stage 1 Contract:** Formalize mechanical tool invocation order (`ReadLints` $\rightarrow$ `mas-host-exec` compile $\rightarrow$ `mas-host-exec` test $\rightarrow$ secret scan), exit code mapping, and the exact circuit breaker early-exit format.
     - **Stage 2 Profile Registry:** Define exact directory layout (`skills/multi-agent-system/references/review-profiles/`), naming conventions, mandatory checklist sections per profile, and composite profile resolution (e.g., `feature` with `secondary: backend, genai`).
     - **Stage 3 Arbiter Schema:** Formalize finding IDs (`[CRITICAL-xx]`, `[MAJOR-xx]`, `[ADVISORY-xx]`), Confidence levels (`HIGH`, `MEDIUM`, `LOW`), Evidence Anchor syntax, and the 4-rule False-Positive Suppression Filter.
     - **Delta Re-Review Scope Contract:** Invariant rules for review iteration 2: Reviewer verifies fixes for previously flagged blockers + regression delta only; new blockers on unchanged code are forbidden.
     - **Backward Compatibility:** Fallback mechanisms when `REVIEW_PROFILE` is missing in handoffs from legacy tools or MAS Lite.
     - **Semver:** Confirmation of version bump to `2.0.0`.
   - **Acceptance:** Architecture brief complete with all required sections (`Architecture`, `Modules`, `Layers`, `Contracts`, `Files`).

---

### Phase P0 — Mechanical Gate & Circuit Breaker Standards (Core Stage Standards)

2. **Create `review-stage-gate.md` (Stage 1 Specification)**
   - **File:** `skills/multi-agent-system/references/review-stage-gate.md` (new)
   - **Responsibilities:**
     - Define deterministic mechanical check sequence:
       1. Static Linter (`ReadLints` on modified `FILES`).
       2. Compilation check via `mas-host-exec` (e.g. `./gradlew :module:compileDebugKotlin` or project compiler).
       3. Unit Test execution via `mas-host-exec` (affected unit test suite).
       4. Diff hygiene & secret scan (regex scanning for committed keys, tokens, or private assets).
     - Define Fast-Fail Circuit Breaker semantics: If any check returns exit code $\ne 0$ or detects lint errors/secrets, immediately stop, format raw compiler/linter error output, set `Approved: NO`, and exit before invoking LLM semantic analysis.
     - Include standardized Markdown output block for Stage 1 evidence.
   - **Acceptance:** Clean, self-contained reference doc cross-linked by Reviewer and Coordinator.

3. **Create `review-arbiter-standards.md` (Stage 3 Specification)**
   - **File:** `skills/multi-agent-system/references/review-arbiter-standards.md` (new)
   - **Responsibilities:**
     - Define Evidence Anchor format: `path/to/file.ext#Lstart-Lend` with mandatory reproducible execution trace or trigger scenario.
     - Formalize the 4 False-Positive Suppression Filter Rules:
       - *Rule 1 (Evidence Anchor):* Discard or downgrade to `ADVISORY` any finding lacking exact file, line range, and trigger scenario.
       - *Rule 2 (Type-System Invariance):* Strictly prohibit flagging NPEs or nullability risks on types declared non-nullable by language type systems.
       - *Rule 3 (Compilation Truth):* Strictly prohibit claiming missing imports, unresolved symbols, or syntax errors if Stage 1 compilation passed.
       - *Rule 4 (Style vs Correctness):* Classify cosmetic, stylistic, or optional documentation feedback as `ADVISORY` only; never let `ADVISORY` block `Approved: YES`.
     - Define Severity Criteria:
       - `Critical`: Crashes, data corruption, security exploits, credential leakage, broken Stage 1 build.
       - `Major`: Functional regression, broken acceptance criteria, contract breach, missing bug repro test, unhandled core edge case.
       - `Advisory`: Code cleanup, non-blocking naming suggestions, optional performance hints, styling.
     - Define Actionable Remediation Schema: Concrete drop-in code snippet or exact shell command for every Critical/Major issue.
     - Define final verdict decision tree: `Approved: YES` if and only if 0 Critical and 0 Major findings.
   - **Acceptance:** SOT for review synthesis, ensuring zero hallucinated blockers and consistent gate verdicts.

---

### Phase P1 — Situation-Adaptive Domain Profile References

Create directory `skills/multi-agent-system/references/review-profiles/` and author modular domain profiles:

4. **Create `review-profiles/bugfix.md`**
   - **File:** `skills/multi-agent-system/references/review-profiles/bugfix.md` (new)
   - **Content:**
     - Extraction of former Step 0 ("Post-Bug Fix Verification").
     - Forensic verification that fix addresses `ROOT_CAUSE`, not merely `ORIGINAL_SYMPTOM` masking.
     - Requirement to re-run documented `REPRO_STEPS` mentally or via test command.
     - Mandatory regression test verification: If no unit/instrumentation test is added or repro command documented, emit `MAJOR-01`.
     - Strict `Issue Resolved: YES | NO` checklist and criteria.
   - **Acceptance:** Self-contained guide for reviewing bugfix pull requests without extraneous UI or infra baggage.

5. **Create `review-profiles/ui.md`**
   - **File:** `skills/multi-agent-system/references/review-profiles/ui.md` (new)
   - **Content:**
     - Consolidation of UI-specific checks: Visual QA fidelity (step 0k), Figma design-spec schema (step 0j), UX interaction QA (step 4b), Android Veteran UI gates (step 8).
     - Unidirectional Data Flow (UDF) & sealed `UiState` state machines (`Loading`, `Content`, `Empty`, `Error`).
     - Responsive & adaptive layout validation (compact, medium, expanded, fontScale, landscape).
     - Accessibility conformance (touch targets $\ge 48\text{dp}$, semantics, content descriptions).
     - Fallback Imagined Visual QA table when no Figma `design-spec` or `visual-qa` brief exists.
   - **Acceptance:** Comprehensive mobile/web UI review profile eliminating non-UI checks.

6. **Create `review-profiles/backend.md`**
   - **File:** `skills/multi-agent-system/references/review-profiles/backend.md` (new)
   - **Content:**
     - Consolidation of Step 0n ("Backend Clean Architecture & Migration Verification").
     - Layering integrity: strict separation of Domain, Repository, and Data Source.
     - Database migration safety: forward-only, non-destructive, versioned migrations.
     - SQL parameterization: zero raw string concatenation in queries (SQL injection defense).
     - Idempotency & Auth: idempotency keys for mutative APIs, RBAC/auth context propagation.
   - **Acceptance:** Focused backend and database verification profile.

7. **Create `review-profiles/infra.md`**
   - **File:** `skills/multi-agent-system/references/review-profiles/infra.md` (new)
   - **Content:**
     - Consolidation of Step 0o ("DevOps & Platform Verification").
     - Container security: non-root users, multi-stage builds, minimal base images.
     - CI/CD Action integrity: 40-character immutable Git commit SHAs (no mutable tags).
     - Secret hygiene: verification that environment templates (`.env.example`) have zero real credentials.
     - Health checks: presence of liveness (`/healthz`) and readiness (`/readyz`) probes.
   - **Acceptance:** Isolated infrastructure, CI/CD, and DevOps review standard.

8. **Create `review-profiles/genai.md`**
   - **File:** `skills/multi-agent-system/references/review-profiles/genai.md` (new)
   - **Content:**
     - Consolidation of Step 0l ("GenAI Specification & Evaluation Verification").
     - Prompt hierarchy & XML boundary tags (`<context>`, `<instructions>`, `<input>`).
     - Structured JSON tool calling schemas (Draft-07 strict validation, no ambiguous types).
     - On-device SLM RAM guards: mandatory verification of $\ge 6\text{GB}$ device RAM check.
     - Evaluation metrics: Faithfulness, Answer Relevancy, Hallucination score verification.
   - **Acceptance:** Specialized profile for LLM applications and agent systems.

9. **Create `review-profiles/feature.md`**
   - **File:** `skills/multi-agent-system/references/review-profiles/feature.md` (new)
   - **Content:**
     - Full feature review profile for end-to-end capabilities spanning multiple layers.
     - PRD alignment (step 0m): user stories implemented vs planned, acceptance scenarios pass.
     - 20-Point Edge Case Matrix: comprehensive failure, network, lifecycle, concurrency, and navigation tracing.
     - Architectural layering and consistency with existing patterns in codebase.
     - In-code documentation check (step 7): public API KDoc/Javadoc completeness, no noise comments.
   - **Acceptance:** Rigorous full-feature profile for multi-file greenfield capabilities.

10. **Create `review-profiles/refactor.md`**
    - **File:** `skills/multi-agent-system/references/review-profiles/refactor.md` (new)
    - **Content:**
      - Behavioral invariance verification: proving that refactored code preserves external contracts.
      - Zero API contract drift (step 0g alignment).
      - Performance regression defense (step 0b and `list-surface-performance.md`): verifying list page sizes, recomposition stability, memory footprint.
      - Test suite parity: ensuring existing tests continue to pass without weakening assertions.
    - **Acceptance:** Targeted profile for code reorganizations, optimizations, and cleanups.

11. **Update `reviewer-lite.md` / `review-profiles/lite.md`**
    - **File:** `skills/multi-agent-system/references/reviewer-lite.md` (update) & symlink/alias reference
    - **Content:** Ensure alignment with 3-stage concepts while keeping prompt execution to a fast, single-turn lightweight gate.
    - **Acceptance:** MAS Lite remains fast and token-frugal.

---

### Phase P2 — Reviewer Core Refactor & Arbiter Engine

12. **Refactor `skills/mas-reviewer/SKILL.md` Core**
    - **File:** `skills/mas-reviewer/SKILL.md` (major refactor)
    - **Transformation:**
      - Slash prompt size from 825 lines down to ~160–180 lines.
      - Remove inlined 15 conditional steps (`0`, `0b`–`0o`) and monolithic edge case checklists.
      - Replace with an explicit **3-Stage Orchestration Lifecycle**:
        - **Startup:** Read handoff, resolve `REVIEW_PROFILE` (or auto-detect), read changed `FILES`.
        - **Stage 1 (Mechanical Gate):** Execute deterministic tools per `references/review-stage-gate.md`. If FAIL, halt immediately with circuit breaker output, set `Approved: NO`, and exit.
        - **Stage 2 (Domain Deep-Dive):** Dynamically load and execute only the selected profile from `references/review-profiles/{profile}.md`.
        - **Stage 3 (Arbiter Synthesis):** Synthesize findings per `references/review-arbiter-standards.md`, execute False-Positive Suppression Filter, generate actionable remediation, and render final verdict.
    - **Backward Compatibility Invariants:**
      - Retain exact output envelope expected by Coordinator:
        - `## Stage 1: Mechanical Gate Results`
        - `## Findings` (with `[CRITICAL-xx]`, `[MAJOR-xx]`, `[ADVISORY-xx]`)
        - `Approved: YES | NO`
        - `## Daily Summary` (≤120 chars)
        - `## Memory Update`
        - `## Usage Report`
        - `DONE`
    - **Acceptance:** Clean, readable, modular skill file adhering to strict line count target.

---

### Phase P3 — Coordinator & Routing Integration

13. **Update Coordinator Routing & Profile Detection in `mas-coordinator/SKILL.md`**
    - **File:** `skills/mas-coordinator/SKILL.md`
    - **Additions:**
      - **Zero-Token Profile Resolution Predicate Table:**
        - `bugfix`: Handoff contains `ORIGINAL_SYMPTOM`, `ROOT_CAUSE`, or `bug-fix` in chain.
        - `ui`: `UI_CHANGES: YES`, `design-specs/{TASK_ID}.md` exists, or files touch Compose/XML/CSS.
        - `backend`: Files touch `server/`, `api/`, `db/`, `migrations/`, or `mas-backend-dev` in chain.
        - `infra`: Files touch `Dockerfile`, `.github/`, `k8s/`, `terraform/`, or `mas-devops` in chain.
        - `genai`: `genai/{TASK_ID}.md` exists or files touch LLM/prompts/evals.
        - `refactor`: `optimizations/{TASK_ID}.md` exists or scope is refactoring/perf.
        - `feature`: Standard multi-tier feature (fallback when multiple domains touch).
        - `lite`: `MODE: LITE` active.
      - **Composite Profile Support:** Primary profile with secondary tags (e.g. `feature (secondary: backend)`).
      - **Delta-Only Re-Review Enforcement:** On reviewer rejection loop 2, inject `REVIEW_SCOPE: delta-only` and `PREVIOUS_BLOCKERS` into Reviewer handoff to eliminate review ping-pong.
    - **Acceptance:** Coordinator automatically assigns correct profile without requiring manual user tags.

14. **Update `multi-agent-system/SKILL.md` & Protocol Files**
    - **Files:**
      - `skills/multi-agent-system/SKILL.md` (update reviewer role description and 3-stage pipeline).
      - `skills/multi-agent-system/protocol/handoff-format.md` (document `REVIEW_PROFILE` and `REVIEW_SCOPE`).
      - `skills/multi-agent-system/protocol/handoff-format-lite.md` (document `RP:` profile tag).
      - `skills/multi-agent-system/protocol/read-order.md` (document Reviewer reading `review-stage-gate.md`, `review-arbiter-standards.md`, and `review-profiles/{profile}.md`).
      - `skills/multi-agent-system/install/manifest.json` (bump version to `2.0.0`, register new reference files in manifest).
    - **Acceptance:** All framework documentation and schemas reflect the new architecture.

---

### Phase P4 — Fixture Verification, Dogfooding & Test Strategy

15. **Author Test Strategy Brief**
    - **File:** `.ai/context/test-strategies/REV-01.md` (new)
    - **Coverage:**
      - Matrix of test cases: Stage 1 circuit breaker trigger, Stage 2 profile routing across all 8 profiles, Stage 3 false-positive suppression, and Delta re-review.
      - Offline fixture execution commands and validation assertions.
    - **Acceptance:** Complete test strategy brief adhering to `brief-schemas.md`.

16. **Create Fixture Suite in `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/`**
    - **Directory:** `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/` (new)
    - **Fixtures:**
      - `fixture-01-fastfail-compile/`: Broken syntax file $\rightarrow$ verifies Stage 1 halts immediately with `Approved: NO`.
      - `fixture-02-fastfail-lint/`: Linter violation $\rightarrow$ verifies Stage 1 circuit breaker trips.
      - `fixture-03-profile-bugfix/`: Bugfix with missing regression test $\rightarrow$ verifies `MAJOR-01` emitted.
      - `fixture-04-profile-ui/`: Compose UI without sealed `UiState` $\rightarrow$ verifies UI profile flags missing error/loading states.
      - `fixture-05-profile-backend/`: Unparameterized SQL query $\rightarrow$ verifies backend profile flags SQL injection risk.
      - `fixture-06-false-positive-filter/`: Test inputs containing speculative NPE and cosmetic style comments $\rightarrow$ verifies rules discard or downgrade to `ADVISORY`.
      - `fixture-07-delta-rereview/`: Second review scenario $\rightarrow$ verifies unchanged code is not re-flagged.
    - **Acceptance:** Complete fixture assets with test inputs and expected JSON/Markdown results.

17. **Author Automated Test Driver Script**
    - **File:** `skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1` (new)
    - **Responsibilities:**
      - Execute verification tests against the fixture directory.
      - Assert that Stage 1 fast-fail trips without executing Stage 2 or 3.
      - Assert that profile-specific checklists are enforced.
      - Assert that False-Positive Suppression filters out unanchored nits.
      - Output clean PASS/FAIL summary and exit codes.
    - **Acceptance:** Standalone PowerShell script runnable in framework CI or local workspace.

18. **Test Execution & Verification Brief**
    - **File:** `.ai/context/test-runs/REV-01.md` (new)
    - **Responsibilities:** Execute `Test-AdaptiveReviewer.ps1` via `mas-test-executor` and record evidence.
    - **Acceptance:** All test cases pass with exit code 0.

19. **Documentation & Memory Update**
    - **Responsibilities:**
      - Update in-code comments and script headers via `mas-documenter`.
      - Propose memory entry for `REV-01` in `.ai/context/memory.md` summarizing the Multi-Stage Adaptive Review Architecture and version `2.0.0`.
    - **Acceptance:** Documentation complete; clean durable knowledge entry prepared.

20. **Final Dogfood Review**
    - **Responsibilities:** Execute `mas-reviewer` on the REV-01 changeset using the new 3-stage adaptive architecture to achieve `Approved: YES`.
    - **Acceptance:** Review passes with zero critical/major issues and verified Stage 1/2/3 output.

---

## Dependencies

| Dependency | Required By | Impact & Integration Notes |
|------------|-------------|----------------------------|
| **MAS-10 Host Mutex (`mas-host-exec`)** | Stage 1 Mechanical Gate | Used by Reviewer in Stage 1 to safely execute Gradle builds and tests without daemon deadlocks. Reviewer uses `mas-host-exec` wrappers. |
| **MAS-05 Figma & Design Spec** | `review-profiles/ui.md` | Provides the contract for step 0j design-spec verification in the UI profile. |
| **MAS-06 Visual Fidelity** | `review-profiles/ui.md` | Provides the contract for step 0k visual-qa brief consumption in the UI profile. |
| **MAS-11 Specialist Roles & Briefs** | Domain Profiles (`genai.md`, `backend.md`, `infra.md`, `feature.md`) | Ingests brief schemas from MAS-11 (`genai-spec`, `devops`, `prd`) into their respective domain review profiles. |
| **ReadLints Tool** | Stage 1 Mechanical Gate | Workspace tool used to verify that modified files have no active syntax or compiler errors before semantic review. |
| **Existing MAS Handoff Schema** | Coordinator & Reviewer | Reviewer must remain backwards compatible with existing handoffs that omit `REVIEW_PROFILE`. |

---

## Acceptance criteria

1. **Stage 1 Fast-Fail Circuit Breaker:**
   - When a modified file has a compiler error, syntax error, or failing test in Stage 1, the reviewer terminates immediately with `Stage 1 Gate Status: FAIL`, outputs exact raw diagnostics, sets `Approved: NO`, and does NOT load Stage 2 profiles or evaluate Stage 3 edge cases.
   - Saves $\ge 75\%$ prompt tokens on uncompilable diffs compared to monolithic review.

2. **Modular Situation-Adaptive Profiles:**
   - 7 distinct domain profiles (`bugfix.md`, `ui.md`, `backend.md`, `infra.md`, `genai.md`, `feature.md`, `refactor.md`) authored under `skills/multi-agent-system/references/review-profiles/`.
   - Each profile is modular ($\le 120$ lines), focused purely on its domain, and defines concrete pass/fail checks.
   - `skills/mas-reviewer/SKILL.md` reduced from 825 lines to $\le 180$ lines by delegating domain logic to modular profiles.

3. **Stage 3 Arbiter Synthesis & False-Positive Suppression:**
   - All findings satisfy the Evidence Anchor Schema (`path/to/File.kt#Lxx-Lyy` + trigger scenario + actionable code remediation).
   - False-Positive Suppression Filter successfully drops or downgrades speculative nullability concerns on non-null types, stylistic opinions, and unanchored claims.
   - `Approved: YES` is strictly gated on 0 Critical and 0 Major findings.

4. **Coordinator Automated Profile Routing:**
   - Coordinator automatically resolves `REVIEW_PROFILE` from task type, changed file paths, and chain context using the zero-token predicate table.
   - Supports composite profiles (e.g. `feature (secondary: backend)`).
   - Enforces Delta-Only Re-Review on iteration 2, preventing new nitpicks on unchanged code.

5. **Backward Compatibility & Invariants:**
   - Reviewer functions seamlessly when `REVIEW_PROFILE` is omitted, auto-detecting the domain.
   - Preserves all standard Coordinator handoff hooks (`## Daily Summary`, `## Memory Update`, `Approved: YES | NO`, `DONE`).
   - `reviewer-lite.md` continues to support fast, single-turn lightweight reviews.

6. **Automated Verification Harness:**
   - `Test-AdaptiveReviewer.ps1` executes all fixture scenarios in `.ai/fixtures/REV-01-ADAPTIVE-REVIEW/` with 100% pass rate.
   - No external network or live Android emulator required for framework verification tests.

---

## Risks

| Risk | Likelihood | Impact | Mitigation Strategy |
|------|------------|--------|---------------------|
| **Profile Misclassification:** Coordinator misclassifies a multi-faceted task, skipping relevant checks. | Low | Medium | Default to `feature` profile whenever multiple heterogeneous domains are touched, or specify composite profiles (e.g. `feature (secondary: backend)`). |
| **Excessive Tool Turns:** Reading external profile reference files via `read_file` adds latency. | Low | Low | Profiles are compact ($\le 120$ lines). In full `/mas`, Reviewer loads the profile in turn 1 alongside changed files. |
| **Breaking Existing Review Output Parsers:** Downstream scripts (e.g. `append-daily-changelog.ps1`, `trim-memory.ps1`) fail if output format changes. | Medium | High | Maintain exact casing and Markdown heading contracts for `## Findings`, `Approved: YES | NO`, `## Daily Summary`, `## Memory Update`, and `## Usage Report`. |
| **Linter / Gradle Failure in Air-Gapped Environments:** Stage 1 compilation fails due to missing local dependencies or Gradle daemons. | Low | Medium | Wrap execution in `mas-host-exec` and support `NOT_RUN` with documented reason when environment prerequisites are absent (matching MAS-04/10 standards). |
| **Overly Aggressive False-Positive Filter:** Genuine architectural flaws suppressed if line numbers cannot be pinpointed. | Low | Medium | Rule 1 allows file-level architectural anchors (`path/to/ArchitectureLayer.kt`) when the defect is systemic, provided a concrete trigger scenario is documented. |

---

## Build & Test Plan

| Surface | Command / Verification Action | Owner |
|---------|-------------------------------|-------|
| **Stage 1 Fast-Fail Fixture** | Run `Test-AdaptiveReviewer.ps1 -Test FastFail` against uncompilable code; assert immediate `Approved: NO` and zero Stage 2 execution. | test-executor |
| **Profile Routing Fixtures** | Run `Test-AdaptiveReviewer.ps1 -Test Profiles` across `bugfix`, `ui`, `backend`, `genai`, `refactor`; assert correct profile rules applied. | test-executor |
| **False-Positive Suppression Fixture** | Run `Test-AdaptiveReviewer.ps1 -Test Suppression`; assert speculative nits and non-null NPE warnings are discarded. | test-executor |
| **Full Automated Harness** | `powershell -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1` | test-executor |
| **Framework Manifest & Schema Check** | Verify `install/manifest.json` valid JSON, files exist on disk, line count of `mas-reviewer/SKILL.md` $\le 180$ lines. | reviewer |
| **Dogfood Review** | Run `mas-reviewer` on REV-01 itself; verify Stage 1 PASS, profile selection `feature (secondary: backend)`, and `Approved: YES`. | reviewer |

---

## Visual QA Scenarios

N/A — `UI_SCOPE: logic-only`. No user-facing mobile or web UI is modified. Verification is performed exclusively through deterministic test scripts and fixture outputs.

---

## Required Agents

| Agent | Phase | Responsibility |
|-------|-------|----------------|
| **architect** | Phase 0 | Author architecture brief `.ai/context/architecture/REV-01.md`, finalize stage contracts, profile registry, and false-positive filter rules. |
| **general-dev** | Phase P0–P3 | Author reference files (`review-stage-gate.md`, `review-arbiter-standards.md`, 7 profile files), refactor `mas-reviewer/SKILL.md`, update Coordinator and handoff protocols, create test fixtures and `Test-AdaptiveReviewer.ps1`. |
| **test-strategy** | Phase P4 | Create `.ai/context/test-strategies/REV-01.md` acceptance matrix and fixture verification commands. |
| **test-executor** | Phase P4 | Execute `Test-AdaptiveReviewer.ps1` against fixtures and record `.ai/context/test-runs/REV-01.md`. |
| **documenter** | Phase P4 | Sync reference documentation, script headers, and README manifests. |
| **reviewer** | Phase P4 | Perform dogfood verification of REV-01 under the new 3-stage adaptive architecture; provide final `Approved: YES` gate. |

*Excluded Agents:* `android-dev` (no mobile UI), `mas-figma`, `mas-visual-fidelity`, `mas-pm` (PRD already captured in Brainstorm/Handoff), `mas-security-auditor` (advisory only unless requested).
