# Plan Brief — MAS-04

## Plan

Goal:
Implement **Option 2 — Phased incremental roster** (per `.ai/context/brainstorms/MAS-04.md` and `.ai/context/osint/MAS-04.md`): add **10 narrow specialist agents** across three releases (Phase A v1.2.0, Phase B v1.2.1, Phase C v1.3.0) with deterministic Coordinator routing predicates, brief schemas, spawn-model-policy entries, skill stubs, and mutual-exclusion boundaries vs `reviewer`, `release-readiness`, `test-strategy`, and `ux-intelligence`. **Logic-only** — no UI files. Specialists audit and brief only; they never patch production code or replace existing gates.

**MAS-01 exclusion:** Do not re-implement `mas-debate`, `mas-token-auditor`, or `spawn-model-policy` core — extend those artifacts only.

Tasks:

### Phase A — v1.2.0 P0 quartet (security-auditor, dependency-risk, api-contract, test-executor)

#### A0 — Architect gate (pre-implementation)

1. **Architect confirms routing topology and cap strategy** — Validate predicate priority order, chain positions per brainstorm Logic Flow B, `MAX_CHAIN_AGENTS` (12) overflow policy (optional specialist skip order: test-executor → api-contract → dependency-risk → security-auditor when cap threatened), and advisory-only v1 for all P0 specialists.
   - **Files:** `.ai/context/architecture/MAS-04.md` (new)
   - **Acceptance:** Architecture brief documents predicate table, chain slots, mutual-exclusion matrix rows for P0 quartet; resolves open questions: `SECURITY_BLOCKER: yes` opt-in only; `test-executor` run-only (no inline test fixes); reviewer conditional read steps (0f–0j) only when brief exists.

#### A1 — Protocol foundation (shared across P0)

2. **Extend `brief-schemas.md`** — Register four new brief types with required sections.
   - **Files:** `skills/multi-agent-system/protocol/brief-schemas.md`
   - **Types:** `security-audit` → `.ai/context/security-audits/{TASK_ID}.md` (Threat model, Findings, Validation, Blockers); `api-contract` → `.ai/context/api-contracts/{TASK_ID}.md` (Spec inventory, Breaking changes, Drift, Recommendations); `supply-chain` → `.ai/context/supply-chain/{TASK_ID}.md` (Dependency delta, CVE summary, Blast radius, Remediation); `test-run` → `.ai/context/test-runs/{TASK_ID}.md` (Commands, Pass/fail, Failures, Gaps)
   - **Acceptance:** Registry table rows added; validation guidance unchanged (Reviewer flags gaps).

3. **Extend `spawn-model-policy.md`** — Add MODEL_CLASS for P0 slugs.
   - **Files:** `skills/multi-agent-system/protocol/spawn-model-policy.md`
   - **Map:** `security-auditor` → `thinking`; `api-contract` → `normal`; `dependency-risk` → `fast`; `test-executor` → `normal`
   - **Acceptance:** Table rows present; lite `MC:` cross-ref documented if applicable.

4. **Extend `read-order.md`** — Subscription matrix rows for P0 specialists.
   - **Files:** `skills/multi-agent-system/protocol/read-order.md`
   - **Reads:** security-auditor (osint, architecture, plans, changed FILES); api-contract (osint, architecture, api specs in FILES); dependency-risk (osint, plans, lockfiles/manifest/skills in FILES); test-executor (test-strategies, plans, handoff FILES)
   - **Acceptance:** Matrix complete; no full schema paste.

5. **Extend `handoff-format.md` + lite format** — Add routing flags and lite abbreviations.
   - **Files:** `skills/multi-agent-system/protocol/handoff-format.md`, `skills/multi-agent-system/protocol/handoff-format-lite.md`
   - **Flags:** `SECURITY_AUDIT: yes`, `API_CONTRACT: yes`, `SUPPLY_CHAIN: yes`, `RUN_TESTS: yes`; lite: `SEC:y`, `API:y`, `DEPS:y`, `TEST:y`
   - **Acceptance:** Flags documented with default triggers; existing handoffs without flags remain valid.

6. **Extend `subagent-spawn.md`** — Register four new slug rows with Task spawn template.
   - **Files:** `skills/multi-agent-system/protocol/subagent-spawn.md`
   - **Acceptance:** Slug table includes all four; `run_in_background: false` preserved; model resolution order unchanged.

7. **Create deliverable context directories** — Ensure `.ai/context/` subdirs exist for P0 briefs.
   - **Files:** `.ai/context/security-audits/.gitkeep`, `.ai/context/api-contracts/.gitkeep`, `.ai/context/supply-chain/.gitkeep`, `.ai/context/test-runs/.gitkeep`
   - **Acceptance:** Dirs present; init or export script creates them if project uses automation.

#### A2 — Skill stubs (P0 quartet)

8. **Create `skills/mas-security-auditor/SKILL.md`** — STRIDE + OWASP Top 10 + OWASP LLM Top 10; candidate → validate → report; writes `.ai/context/security-audits/{TASK_ID}.md`; `MODEL_CLASS: thinking`; never patches code; advisory v1 (findings route to dev/bug-fix).
   - **Acceptance:** Startup reads handoff → skill → read-order → optional BRIEF_PATH; forbids Task spawn; output matches security-audit schema.

9. **Create `skills/mas-dependency-risk/SKILL.md`** — CVE/EPSS, blast-radius, skill/MCP trust; MAS-self-scan mode when `SCOPE: mas-framework` or framework TASK_ID; writes `.ai/context/supply-chain/{TASK_ID}.md`; `MODEL_CLASS: fast`.
   - **Acceptance:** Self-scan covers skills, hooks, MCP manifest, `.cursorrules`; never auto-bumps versions.

10. **Create `skills/mas-api-contract/SKILL.md`** — Spec inventory, breaking-change diff, drift, conformance notes; writes `.ai/context/api-contracts/{TASK_ID}.md`; `MODEL_CLASS: normal`; does not replace architect contract design.
    - **Acceptance:** Skips gracefully when no OpenAPI/GraphQL/Proto in FILES and no REST/BFF in SCOPE.

11. **Create `skills/mas-test-executor/SKILL.md`** — Execute tests per test-strategy brief; writes `.ai/context/test-runs/{TASK_ID}.md`; `MODEL_CLASS: normal`; run-only v1 (failures route to bug-fix); documents skip rationale in Gaps when strategy says skip.
    - **Acceptance:** Requires test-strategy brief or explicit `RUN_TESTS: yes`; flaky tests documented, no unbounded retry.

#### A3 — Coordinator routing (P0)

12. **Update `mas-coordinator/SKILL.md` routing table** — Deterministic predicate table (fixed priority, first match per slot, max one spawn per specialist per TASK_ID unless `RE_AUDIT: yes`).
    - **Predicates (Phase A):**

    | Flag / condition | Specialist | Chain position |
    |------------------|------------|----------------|
    | `SUPPLY_CHAIN: yes` OR lockfile/manifest/MCP/skills in FILES | dependency-risk | Early: after osint, before planner/architect; or pre-release |
    | `API_CONTRACT: yes` OR OpenAPI/GraphQL/Proto in FILES OR REST/BFF in SCOPE | api-contract | After architect; or post-dev pre-reviewer |
    | `SECURITY_AUDIT: yes` OR auth/crypto/API in SCOPE OR reviewer security flag | security-auditor | Post-dev, pre-reviewer (or post-architect for design-time audit) |
    | `RUN_TESTS: yes` OR test-strategy brief exists | test-executor | Post-dev, pre-reviewer |

    - **Chain (full feature, API + auth + deps):** Coordinator → osint → brainstorm → planner → architect → dependency-risk (if triggered) → api-contract (if triggered) → test-strategy → dev → security-auditor (if triggered) → test-executor (if triggered) → documenter → reviewer → [debate per MAS-01] → commit
    - **Acceptance:** Zero-token routing (no LLM specialist selection); handoff template includes `BRIEF_PATH`, `MODEL_CLASS`, `SPAWN_STATUS: spawned`.

13. **Update `mas-reviewer/SKILL.md`** — Conditional read steps for P0 briefs when present.
    - **Steps:** When `security-audits/{TASK_ID}.md` exists → verify Validation section and route blockers as findings (not independent merge block unless user `SECURITY_BLOCKER: yes`); when `test-runs/{TASK_ID}.md` exists → consume pass/fail evidence (step 0d alignment with test-strategy); when `api-contracts/` or `supply-chain/` exist → note breaking changes / CVE remediation in review
    - **Acceptance:** Reviewer remains sole `Approved: YES|NO` gate; specialists produce findings only.

14. **Update `mas-lite/SKILL.md`** — Phase A specialists in Lite L tier only; abbreviated flags within 12-line cap; document optional-skip order under chain cap.
    - **Acceptance:** Lite S/M unchanged; L tier may spawn SEC/API/DEPS/TEST per predicates.

#### A4 — Install + manifest (P0)

15. **Update `install/manifest.json`** — Register P0 skills; bump version to `1.2.0`.
    - **Files:** `skills/multi-agent-system/install/manifest.json`
    - **Add:** `mas-security-auditor`, `mas-dependency-risk`, `mas-api-contract`, `mas-test-executor`
    - **Acceptance:** `skills` array includes four entries; export script copies new skill trees.

16. **Update export/install scripts** — Include new skills in bundle.
    - **Files:** `skills/multi-agent-system/install/export-mas-framework.ps1` (if skill list hardcoded)
    - **Acceptance:** Dry-run export includes all four skill directories.

#### A5 — Phase A regression + documentation

17. **Update `mas-test-strategy/SKILL.md`** — Cross-reference test-executor chain position (plans before dev; executor after dev).
    - **Acceptance:** Explicit boundary: test-strategy plans; test-executor executes.

18. **Update `mas-release-readiness/SKILL.md`** — Note optional pre-pass spawn of dependency-risk / security-auditor when handoff flags set; specialists do not replace category sweeps.
    - **Acceptance:** Release gate topology unchanged; FAIL categories still route to dev/bug-fix.

19. **Documenter pass** — README / `skills/multi-agent-system/SKILL.md` — Phase A roster, routing flags, brief paths.
    - **Acceptance:** User-facing docs list P0 specialists and triggers; no inline brief examples in chat rules.

20. **Phase A acceptance workflow** — Manual dogfood: run `/mas` on synthetic TASK_ID with `SECURITY_AUDIT: yes`, `API_CONTRACT: yes`, `SUPPLY_CHAIN: yes`, `RUN_TESTS: yes`.
    - **Acceptance:** Each specialist spawns once; briefs written to correct paths; reviewer reads test-run evidence; no specialist patches code; mutual-exclusion vs test-strategy and reviewer verified.

---

### Phase B — v1.2.1 P1 depth (a11y, i18n, compliance)

#### B0 — Protocol extensions (P1)

21. **Extend `brief-schemas.md`** — Three new types: `a11y-review`, `i18n-review`, `compliance`.
    - **Paths:** `.ai/context/a11y-reviews/{TASK_ID}.md`, `.ai/context/i18n-reviews/{TASK_ID}.md`, `.ai/context/compliance/{TASK_ID}.md`
    - **Sections:** per brainstorm Domain & Contracts table
    - **Acceptance:** compliance brief template includes "not legal advice" disclaimer section.

22. **Extend `spawn-model-policy.md`** — `a11y` → `normal`; `i18n` → `normal`; `compliance` → `thinking`.

23. **Extend `read-order.md`** — a11y (ux-reviews if exists, plans, UI FILES); i18n (plans, string/resource FILES); compliance (osint, architecture, COMPLIANCE_FRAMEWORK handoff).

24. **Extend handoff formats** — `A11Y_AUDIT: yes`, `I18N_AUDIT: yes`, `COMPLIANCE_FRAMEWORK: SOC2|GDPR|HIPAA|EU_AI_ACT|FedRAMP`; lite: `A11Y:y`, `I18N:y`.

25. **Create context dirs** — `.ai/context/a11y-reviews/`, `.ai/context/i18n-reviews/`, `.ai/context/compliance/` with `.gitkeep`.

#### B1 — Skill stubs (P1 trio)

26. **Create `skills/mas-a11y/SKILL.md`** — WCAG 2.2 AA criterion table; keyboard/screen-reader notes; no behavioral friction (defer to ux-intelligence); writes a11y-review brief.
    - **Acceptance:** Mutual exclusion vs ux-intelligence documented in skill; no layout/cosmetic redesign.

27. **Create `skills/mas-i18n/SKILL.md`** — ICU, locale tags, RTL, pluralization, string extraction audit; writes i18n-review brief.
    - **Acceptance:** Does not own translation vendor workflow; routes fixes to dev.

28. **Create `skills/mas-compliance/SKILL.md`** — Framework clause map, evidence gaps, audit export shape; `MODEL_CLASS: thinking`; skill header + brief "not legal advice"; spawn only when `COMPLIANCE_FRAMEWORK` set.
    - **Acceptance:** Never auto-approves compliance; HITL for legal/prod remediation.

#### B2 — Coordinator + release-readiness integration (P1)

29. **Update `mas-coordinator/SKILL.md`** — Phase B predicates and UI chain (Logic Flow C).
    - **Chain:** ... dev → ux-intelligence (if `UI_CHANGES: yes`) → a11y (if triggered) → i18n (if triggered) → compliance (if `COMPLIANCE_FRAMEWORK` set) → test-executor → documenter → reviewer
    - **Spawn rule:** ux-intelligence, a11y, i18n sequential only (a11y before i18n when both); no parallel unless `PARALLEL_READ: YES` (MAS-01 defer)
    - **Acceptance:** release-readiness Accessibility FAIL → route to a11y (not re-audit in release-readiness); Localization FAIL → route to i18n.

30. **Update `mas-ux-intelligence/SKILL.md`** — Boundary note: WCAG/ARIA → a11y; locale/string architecture → i18n; ux-intelligence owns behavioral friction only.

31. **Update `mas-release-readiness/SKILL.md`** — Category FAIL routing map to a11y/i18n/compliance specialists; compliance category remains PASS/FAIL sweep.

32. **Update `mas-reviewer/SKILL.md`** — Conditional reads for a11y/i18n/compliance briefs when present.

#### B3 — Install (P1)

33. **Update manifest** — Add `mas-a11y`, `mas-i18n`, `mas-compliance`; version `1.2.1`.

34. **Update `mas-lite/SKILL.md`** — Lite abbreviations for A11Y/I18N; compliance full `/mas` only (enterprise opt-in).

#### B4 — Phase B acceptance

35. **Manual dogfood** — UI feature TASK_ID with `UI_CHANGES: yes`, `A11Y_AUDIT: yes`, `I18N_AUDIT: yes`, `COMPLIANCE_FRAMEWORK: GDPR`.
    - **Acceptance:** Sequential spawn order verified; release-readiness integration documented; compliance skipped when framework flag absent.

---

### Phase C — v1.3.0 P2 qualified (observability, migration, chaos-resilience)

#### C0 — Protocol extensions (P2)

36. **Extend `brief-schemas.md`** — `observability`, `migration`, `resilience` types per brainstorm table.

37. **Extend `spawn-model-policy.md`** — `observability` → `thinking`; `migration` → `thinking`; `chaos-resilience` → `normal`.

38. **Extend `read-order.md`** — observability (osint, imaginations, SOURCES_HINT telemetry); migration (osint, brainstorms, prior migrations, architecture); chaos-resilience (protocol/skills in FILES, workflow session JSON).

39. **Extend handoff formats** — `OBSERVABILITY_MODE: prod-triage`, `MIGRATION_TYPE: framework|api|legacy|strangler`, `CHAOS_AUDIT: yes`.

40. **Create context dirs** — `.ai/context/observability/`, `.ai/context/migrations/`, `.ai/context/resilience/`.

#### C1 — Skill stubs (P2 trio)

41. **Create `skills/mas-observability/SKILL.md`** — Prod triage: hypothesis tree, signal correlation, RCA brief; HITL for prod actions; degrades to imaginer + user when telemetry MCP unavailable.
    - **Acceptance:** Never autonomous prod remediation; writes observability brief.

42. **Create `skills/mas-migration/SKILL.md`** — Behavioral spec graph, phased waves, parity validation; feeds test-strategy acceptance; migration before api-contract on same upgrade program.
    - **Acceptance:** No big-bang rewrite without phased plan in brief.

43. **Create `skills/mas-chaos-resilience/SKILL.md`** — Orchestrator fault injection (timeouts, malformed JSON, rate limits); framework meta-QA; non-blocking advisory; runs on MAS protocol/skill changes.
    - **Acceptance:** No production fault injection; writes resilience brief.

#### C2 — Coordinator chains (P2)

44. **Update `mas-coordinator/SKILL.md`** — Phase C chains (Logic Flow D–F).
    - **Prod bug:** observability (if `OBSERVABILITY_MODE: prod-triage` or `SYMPTOM: prod`) → imaginer → bug-fix → test-executor → reviewer
    - **Migration program:** osint → migration (if `MIGRATION_TYPE` set) → planner → architect → test-strategy → dev chain
    - **MAS framework change:** planner → dev → chaos-resilience (if `CHAOS_AUDIT: yes` or `SCOPE: mas-framework`) → reviewer → token-auditor (MAS-01)

45. **Update `mas-imaginer/SKILL.md`** — Boundary: observability = prod signals first; imaginer = local code trace confirm.

46. **Update `mas-reviewer/SKILL.md`** — Conditional reads for observability/migration/resilience briefs.

#### C3 — Install (P2)

47. **Update manifest** — Add `mas-observability`, `mas-migration`, `mas-chaos-resilience`; version `1.3.0`.

#### C4 — Phase C acceptance

48. **Framework self-dogfood** — MAS-04 protocol change TASK_ID: dependency-risk self-scan + chaos-resilience audit on coordinator/skill edits.
    - **Acceptance:** Both specialists produce briefs; chaos-resilience does not block workflow.

---

### Cross-phase — Final integration

49. **Update `skills/multi-agent-system/SKILL.md`** — Full v2 roster table, phase versions, deferred `mas-product` watch list (`PRODUCT_SHAPING: yes` when added).

50. **Update `token-rules.md`** — Document specialist priority skip order when `MAX_CHAIN_AGENTS` (12) threatened; Lite tier specialist allowance.

51. **Reviewer final regression checklist** — Mutual-exclusion matrix (brainstorm section) spot-check all 10 specialists vs reviewer, release-readiness, test-strategy, ux-intelligence, MAS-01 agents.

52. **Finalize workflow** — Reviewer approval on all protocol/skill/manifest changes; optional token-auditor post-approval per MAS-01.

## Dependencies:

| Task | Depends on |
|------|------------|
| A2 (skills 8–11) | A1 (schemas, policy, read-order, handoff flags) |
| A3 (coordinator 12–14) | A2 (skill paths and MODEL_CLASS known) |
| A4 (manifest 15–16) | A2 |
| A5 (17–20) | A3, A4 |
| B1 (26–28) | A5 Phase A shipped (routing patterns established) |
| B2 (29–32) | B0, B1 |
| B3–B4 (33–35) | B2 |
| C1 (41–43) | B4 or parallel after A5 if team splits (recommended: after B4 for release-readiness integration lessons) |
| C2 (44–46) | C0, C1 |
| C3–C4 (47–48) | C2 |
| 49–52 | All phases complete |

**Upstream briefs:** `.ai/context/brainstorms/MAS-04.md` (Recommended, Logic Flow, Domain & Contracts, Edge Cases), `.ai/context/osint/MAS-04.md` (Recommended Approach, Implementation Guidance, Priority Order). **MAS-01 artifacts** assumed present: `spawn-model-policy.md`, `brief-schemas.md`, `read-order.md`, `handoff-format.md`, debate/token-auditor skills.

**Architect gate (A0):** Required before A1 task 2. Confirms predicate priority, cap overflow skip order, and open-question resolutions.

**Deferred (not in MAS-04 scope):** `mas-product` greenfield PRD agent; `PARALLEL_READ: YES` parallel specialist spawns; `SECURITY_BLOCKER: yes` blocking semantics beyond advisory v1 documentation.

## Risks:

| Risk | Impact | Mitigation |
|------|--------|------------|
| Full-chain agent count exceeds `MAX_CHAIN_AGENTS` (12) | Cap violation, skipped specialists | Document priority skip order in token-rules + coordinator; Lite spawns subset only |
| security-auditor false positives | Dev friction, token waste | Required Validation section; candidate → validate → report pattern in skill |
| test-executor vs bug-fix boundary blur | Role confusion | Run-only v1; explicit route failures to bug-fix in skill + coordinator |
| compliance legal exposure | Enterprise adoption risk | Disclaimer in skill header + brief template; HITL for remediation |
| observability without telemetry MCP | Empty or shallow briefs | Degrade path: brief notes "credentials unavailable" → imaginer + user HITL |
| Coordinator routing table complexity | Maintenance burden | Fixed-priority predicate table; zero-token deterministic rules only |
| Phase big-bang temptation | Untested chain permutations | Enforce phased releases A → B → C with per-phase dogfood (tasks 20, 35, 48) |
| Reviewer token cost from new brief reads | Reviewer bloat | Conditional read steps only when brief file exists |
| dependency-risk network for CVE lookup | Offline failure | Document bounded CI/OSV commands; graceful degrade in brief |
| a11y + i18n spawn cost on UI features | Token increase | Sequential spawn default; separate agents per industry pattern (no bundling v1) |

## Build & Test Plan:

**N/A — Gradle/Android.** Logic-only framework upgrade (`UI_SCOPE: logic-only`).

| Surface | Command / action | Pass criteria |
|---------|------------------|---------------|
| Manifest version | Inspect `install/manifest.json` after each phase | Phase A: `1.2.0` + 4 skills; B: `1.2.2.1` + 3; C: `1.3.0` + 3 |
| Export bundle | `export-mas-framework.ps1` to temp dir | All 10 new skill trees present |
| Schema registry | Reviewer spot-check brief missing required heading | `Approved: NO` with schema gap note |
| Predicate: security | Handoff `SECURITY_AUDIT: yes` on auth change TASK_ID | security-auditor spawns once; brief at `security-audits/{TASK_ID}.md` |
| Predicate: supply-chain | FILES includes `package-lock.json` delta | dependency-risk spawns; MAS-self-scan on framework TASK_ID |
| Predicate: api-contract | OpenAPI in FILES | api-contract spawns post-architect |
| Predicate: test-executor | test-strategy brief exists + `RUN_TESTS: yes` | test-run brief with Commands + Pass/fail |
| Mutual exclusion | Full chain with all P0 flags | test-strategy before dev; test-executor after dev; reviewer sole approval |
| Phase B UI chain | `UI_CHANGES: yes` + A11Y + I18N | ux-intelligence → a11y → i18n sequential |
| Phase C framework | Edit coordinator SKILL + `CHAOS_AUDIT: yes` | chaos-resilience brief; non-blocking |
| Lite regression | `/mas-lite` L tier without flags | No new specialist spawns; unchanged behavior |
| Cap stress | Handoff triggering 6+ specialists | Coordinator skips per documented priority or escalates |
| Idempotency | Re-run same TASK_ID without `RE_AUDIT: yes` | No duplicate specialist spawn |

**test-strategy agent:** Brief for synthetic fixture TASK_IDs and expected chain permutations (recommended between planner and Phase A dev work).

## Visual QA Scenarios:

N/A — `UI_SCOPE: logic-only`. No Compose screens, layouts, or theme tokens. UiState field contracts for a11y findings may appear in `brief-schemas.md` only (Phase B).

## Required Agents:

### Phase A (v1.2.0)

| Agent | When | Scope |
|-------|------|-------|
| **architect** | Task A0 — before protocol edits | Routing topology, cap strategy, open-question resolutions |
| **test-strategy** | After A0, before A2 skills | Fixture TASK_IDs, chain permutation test matrix, skip/rationale cases |
| **general-dev** | A1–A4 | Protocol files, four skill stubs, coordinator/reviewer/lite edits, manifest |
| **documenter** | After A4 | README, multi-agent-system SKILL roster section |
| **reviewer** | After A5 dogfood | Phase A regression checklist, schema compliance, mutual-exclusion |

### Phase B (v1.2.1)

| Agent | When | Scope |
|-------|------|-------|
| **architect** | Optional delta review | release-readiness FAIL → specialist routing map |
| **general-dev** | B0–B3 | Three skills, protocol extensions, ux-intelligence/release-readiness/coordinator updates |
| **documenter** | After B3 | Compliance disclaimer docs, Phase B routing flags |
| **reviewer** | After B4 dogfood | a11y/i18n/compliance boundaries vs ux-intelligence and release-readiness |

### Phase C (v1.3.0)

| Agent | When | Scope |
|-------|------|-------|
| **architect** | Optional — migration chain | migration → test-strategy behavioral spec handoff |
| **general-dev** | C0–C3 | Three skills, prod/migration/framework chains, imaginer boundary |
| **documenter** | After C3 | Observability MCP optional setup notes, chaos-resilience scope |
| **reviewer** | After C4 + tasks 49–52 | Full v2 roster regression, framework self-dogfood evidence |

**Not required:** android-dev, ux-intelligence (unless dogfooding UI chain in B4), imaginer (unless C4 prod-bug path), perf-optimizer, commit (unless user opts in post-approval).

## Acceptance criteria (workflow-level)

1. **Phased delivery:** Phase A ships four P0 specialists before Phase B/C skills are registered in manifest.
2. **Deterministic routing:** Coordinator spawns specialists only when predicate matches; no LLM-based specialist selection.
3. **Idempotency:** Max one spawn per specialist per TASK_ID unless `RE_AUDIT: yes`.
4. **Artifact-forward:** Specialist chat return = one line + `BRIEF_PATH`; briefs validate against `brief-schemas.md`.
5. **Gate preservation:** `reviewer` remains sole change-set approval; `release-readiness` remains holistic ship gate; specialists produce findings only (advisory v1).
6. **Mutual exclusion:** test-strategy plans / test-executor executes; ux-intelligence friction / a11y WCAG / i18n locale; security-auditor exploitability / compliance regulatory evidence — boundaries enforced in skills.
7. **MAS-self-scan:** dependency-risk and chaos-resilience run on MAS framework TASK_IDs.
8. **Lite compatibility:** Phase A flags abbreviate within 12-line cap; no regression on S/M tiers without flags.
9. **Deferred respect:** No `mas-product` implementation; no MAS-01 debate/token-auditor re-proposal.
10. **Version bumps:** manifest `1.2.0` → `1.2.1` → `1.3.0` aligned with phase releases.

## Usage Report

Model: default
Class: normal
Tokens: unknown

DONE
