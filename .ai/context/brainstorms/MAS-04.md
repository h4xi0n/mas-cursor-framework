# Brainstorm Brief — MAS-04

## Problem & User Outcome

**Problem:** MAS v1.1 ships 19 specialist skills plus coordinator/lite, but production-grade AI SDLC platforms (Devin Security Swarm, Factory security-reviewer, Copilot custom agents, AgentForge) decompose security, supply-chain, API contract drift, test execution, WCAG/i18n depth, compliance evidence, production observability, migration parity, and orchestrator resilience into **narrow specialists with scoped tools and artifact outputs**. MAS covers planning, implementation, change-set review, perf, UX friction, release gate, and MAS-01 token/debate micro-chains — but lacks eight high-impact delivery specialists. Without clear boundaries, new agents risk duplicating `reviewer`, `release-readiness`, `test-strategy`, or `ux-intelligence`.

**User outcome:** Run `/mas` workflows that route to the right depth specialist at the right chain position — security threat models, dependency blast-radius, API breaking-change reports, test execution evidence, WCAG/i18n/compliance deep dives, prod triage, migration parity plans — without bloating token cost, without replacing existing gates, and without re-proposing MAS-01 additions (`mas-debate`, `mas-token-auditor`, `spawn-model-policy`).

**UI scope:** `logic-only` — protocol routing, skill contracts, brief schemas, handoff flags, chain predicates. No UI files, layouts, or visual design. UiState *contracts* (e.g., a11y finding fields) may appear in brief schemas only.

**OSINT delta:** Eight primary specialists (P0–P2) plus two qualified/deferred. This brief operationalizes OSINT phased rollout, mutual-exclusion matrix, and Coordinator routing predicates. Does not re-research externally.

**MAS-01 exclusion:** Do not re-propose `debate-synthesizer`, `token-auditor`, or `spawn-model-policy` — assume shipped or in-flight from MAS-01.

---

## Options

| # | Option | Pros | Cons | Risk | Effort |
|---|--------|------|------|------|--------|
| 1 | **Phase A only (P0 quartet)** — Ship `security-auditor`, `dependency-risk`, `api-contract`, `test-executor`; defer B/C | Fastest ROI; closes highest-frequency production gaps (security, deps, API breaks, test evidence); minimal manifest churn; aligns with Factory/Devin/Copilot consensus | No WCAG/i18n/compliance depth; prod incidents still route imaginer-only; migration programs unaddressed | L | M |
| 2 | **Phased incremental roster (recommended)** — Phase A (P0×4) → Phase B (a11y, i18n, compliance) → Phase C (observability, migration, chaos-resilience); `mas-product` deferred | Balances coverage and maintenance; each phase validates routing before next; release-readiness stays holistic gate; specialists feed fix routing with depth | 10 new skills over 3 releases; Coordinator routing table grows; compliance/observability credential-dependent | M | L |
| 3 | **Bundled specialists** — Merge `a11y`+`i18n` → `mas-inclusive-design`; merge `security-auditor`+`compliance` → `mas-security-compliance`; single `mas-quality-executor` for test-strategy overlap | Fewer skills to install; lower spawn count on UI+regulated chains; token savings on combined reads | Blurred mutual-exclusion boundaries; harder to tune model class per concern; compliance legal disclaimer mixed with STRIDE; release-readiness category routing becomes ambiguous | M | M |
| 4 | **Big-bang v1.2 roster** — All 10 specialists + schemas + routing in one release | Single documentation pass; users get full enterprise surface immediately | High review burden; untested routing interactions; token cost spike on full chains; chaos-resilience and migration rarely triggered but always in manifest | H | L |

**Fits existing patterns?** Options 1–2: Y (extends `brief-schemas.md`, `spawn-model-policy.md`, `read-order.md`, `handoff-format.md`, `install/manifest.json` per MAS-01). Option 3: N (violates narrow-specialist industry pattern). Option 4: N (conflicts with incremental validation from MAS-01).

---

## Recommended

**Option 2 — Phased incremental roster** — Ship specialists in three waves aligned with OSINT priority and production frequency. Phase A closes universal delivery gaps (security, supply chain, API contracts, test execution). Phase B adds depth where `release-readiness` categories are PASS/FAIL sweeps only. Phase C adds qualified, lower-frequency specialists (prod telemetry, migration programs, framework meta-QA).

**Rationale vs alternatives:** Option 1 leaves regulatory and accessibility depth gaps that `release-readiness` cannot fill without becoming a monolith. Option 3 trades token savings for role confusion — Factory/Copilot/Devin patterns consistently use separate security vs compliance vs a11y vs i18n roles. Option 4 risks shipping untested chain permutations and violates the MAS-01 incremental protocol upgrade philosophy.

---

## Logic Flow

### A. Coordinator routing (deterministic, zero-token)

1. Coordinator reads handoff flags + `FILES` + `SCOPE` + chain history from workflow session JSON.
2. Apply **predicate table** (below) in fixed priority order — first match wins per specialist slot; max one spawn per specialist per `TASK_ID` unless `RE_AUDIT: yes`.
3. Write specialist handoff with `BRIEF_PATH` refs (upstream briefs only), `MODEL_CLASS` per `spawn-model-policy.md`, `SPAWN_STATUS: spawned`.
4. Specialist reads handoff → skill → `read-order.md` → optional `BRIEF_PATH` + `SECTIONS:` slices.
5. Specialist writes deliverable brief; validates against `brief-schemas.md`.
6. Coordinator records step; routes findings to `dev`/`bug-fix`/`reviewer` — specialists never patch production code.
7. `reviewer` remains sole change-set approval gate; specialist blockers are **findings**, not workflow termination (except optional `SECURITY_BLOCKER: yes` user policy — open question).

### B. Phase A chain — full feature (API + auth + deps)

```
Coordinator → osint → brainstorm → planner → architect
  → dependency-risk (if lockfile/manifest/MCP/skills in FILES or SUPPLY_CHAIN: yes)
  → api-contract (if OpenAPI/GraphQL/Proto in FILES or API_CONTRACT: yes)
  → test-strategy → dev
  → security-auditor (if SECURITY_AUDIT: yes | auth/crypto/API in SCOPE | reviewer security flag)
  → test-executor (if RUN_TESTS: yes | test-strategy brief exists)
  → documenter → reviewer → [debate loop per MAS-01] → commit
```

### C. Phase B chain — UI feature with accessibility/i18n

```
... Phase A through dev ...
  → ux-intelligence (if UI_CHANGES: yes) — behavioral friction only
  → a11y (if A11Y_AUDIT: yes | release-readiness Accessibility FAIL | interactive widgets in FILES)
  → i18n (if I18N_AUDIT: yes | new strings/locale/RTL in SCOPE)
  → compliance (if COMPLIANCE_FRAMEWORK: set)
  → test-executor → documenter → reviewer
```

**Spawn rule:** `ux-intelligence`, `a11y`, `i18n` are **sequential spawns only** (Coordinator picks order: a11y before i18n when both triggered). No parallel unless user `PARALLEL_READ: YES` (MAS-01 defer).

### D. Phase C chain — production bug

```
Coordinator → observability (if OBSERVABILITY_MODE: prod-triage | SYMPTOM: prod)
  → imaginer (local code/data-flow confirm)
  → bug-fix → test-executor → reviewer
```

### E. Phase C chain — migration program

```
Coordinator → osint → migration (if MIGRATION_TYPE: set)
  → planner → architect → test-strategy → dev chain
  (migration brief behavioral rules feed test-strategy acceptance)
```

### F. Phase C chain — MAS framework change

```
Coordinator → planner → dev → chaos-resilience (if CHAOS_AUDIT: yes | SCOPE: mas-framework)
  → reviewer → token-auditor (MAS-01)
```

### G. Release gate (unchanged topology, optional specialist pre-pass)

```
Coordinator → release-readiness
  (+ optional: dependency-risk, security-auditor, compliance when handoff flags set)
  → route FAIL categories to dev/bug-fix/a11y/i18n/compliance per category map
  → re-run release-readiness after fixes
```

### H. Routing predicates (handoff extensions)

| Flag | Specialist | Default trigger |
|------|------------|-----------------|
| `SECURITY_AUDIT: yes` | security-auditor | Auth/crypto/API changes; reviewer security finding |
| `API_CONTRACT: yes` | api-contract | OpenAPI/GraphQL/Proto in FILES; REST/BFF SCOPE |
| `SUPPLY_CHAIN: yes` | dependency-risk | Lockfile/manifest/MCP/skills/hooks delta |
| `RUN_TESTS: yes` | test-executor | Post-dev; test-strategy brief exists |
| `A11Y_AUDIT: yes` | a11y | UI FILES; release-readiness Accessibility FAIL |
| `I18N_AUDIT: yes` | i18n | Strings/locale/RTL SCOPE |
| `COMPLIANCE_FRAMEWORK: SOC2\|GDPR\|...` | compliance | Regulated industry; AI governance changes |
| `OBSERVABILITY_MODE: prod-triage` | observability | Prod incident; telemetry in SOURCES_HINT |
| `MIGRATION_TYPE: framework\|api\|legacy\|strangler` | migration | Major upgrade/rewrite programs |
| `CHAOS_AUDIT: yes` | chaos-resilience | MAS protocol/skill changes |

Lite abbreviations (12-line cap): `SEC:y`, `API:y`, `DEPS:y`, `TEST:y`, `A11Y:y`, `I18N:y`.

---

## Phased v2 Rollout

### Phase A — v1.2.0 (P0 quartet)

| Agent | Deliverable path | MODEL_CLASS | Blocking? |
|-------|------------------|-------------|-----------|
| `mas-security-auditor` | `.ai/context/security-audits/{TASK_ID}.md` | thinking | Advisory v1; findings route to dev |
| `mas-dependency-risk` | `.ai/context/supply-chain/{TASK_ID}.md` | fast | Advisory; includes MAS-self-scan for framework TASK_IDs |
| `mas-api-contract` | `.ai/context/api-contracts/{TASK_ID}.md` | normal | Advisory |
| `mas-test-executor` | `.ai/context/test-runs/{TASK_ID}.md` | normal | Advisory; evidence for reviewer |

**Protocol touchpoints:** `install/manifest.json`, `brief-schemas.md` (4 types), `spawn-model-policy.md`, `read-order.md`, `handoff-format.md`, `mas-coordinator/SKILL.md` routing table.

**Acceptance (logic):** Coordinator spawns each specialist only when predicate matches; reviewer reads test-run brief when present; no specialist patches code.

### Phase B — v1.2.1 (depth beyond release-readiness)

| Agent | Deliverable path | MODEL_CLASS | Trigger frequency |
|-------|------------------|-------------|-------------------|
| `mas-a11y` | `.ai/context/a11y-reviews/{TASK_ID}.md` | normal | UI features, store/regulatory a11y |
| `mas-i18n` | `.ai/context/i18n-reviews/{TASK_ID}.md` | normal | Localization scope |
| `mas-compliance` | `.ai/context/compliance/{TASK_ID}.md` | thinking | Enterprise-qualified; opt-in via `COMPLIANCE_FRAMEWORK` |

**Release-readiness integration:** FAIL on Accessibility → route to `a11y` (not re-audit in release-readiness). FAIL on Localization → route to `i18n`. Compliance category remains PASS/FAIL sweep; deep clause mapping is `compliance` specialist only.

### Phase C — v1.3.0 (qualified / lower frequency)

| Agent | Deliverable path | MODEL_CLASS | Notes |
|-------|------------------|-------------|-------|
| `mas-observability` | `.ai/context/observability/{TASK_ID}.md` | thinking | Requires observability MCP/credentials; HITL for prod actions |
| `mas-migration` | `.ai/context/migrations/{TASK_ID}.md` | thinking | Behavioral spec graph → test-strategy input |
| `mas-chaos-resilience` | `.ai/context/resilience/{TASK_ID}.md` | normal | Framework meta-QA; non-blocking advisory |

**Deferred watch list:** `mas-product` (greenfield PRD shaping) — overlaps `spec-reader` + `brainstorm`; add only with `PRODUCT_SHAPING: yes` handoff when user demand confirmed.

---

## Mutual Exclusion Matrix

Explicit boundaries vs existing agents. New specialists **audit and brief**; they do not replace gates.

### vs `reviewer`

| Dimension | `reviewer` | New specialists |
|-----------|------------|-----------------|
| **Purpose** | Sole change-set approval gate; build/test/lint; implementation walkthrough | Depth audits in narrow domains |
| **Security** | Surface-level security review in general pass | `security-auditor`: STRIDE, OWASP Top 10 + LLM Top 10, exploit-path validation, CWE refs |
| **Tests** | May run tests as part of approval; verifies against test-strategy brief | `test-executor`: owns command execution, pass/fail analysis, flaky notes, coverage gaps vs strategy |
| **Output** | `Approved: YES\|NO` | Findings tables with severity; no approval authority |
| **Never** | — | Block merge independently of reviewer (v1 advisory) |

### vs `release-readiness`

| Dimension | `release-readiness` | New specialists |
|-----------|---------------------|-----------------|
| **Purpose** | 17-category PASS/FAIL holistic ship gate | Deep dive on single category/domain |
| **Accessibility** | Category sweep → PASS/FAIL | `a11y`: WCAG 2.2 criterion table, keyboard/screen-reader, component-level fixes |
| **Localization** | Shallow category check | `i18n`: ICU, locale tags, RTL, pluralization, string extraction audit |
| **Security** | Category PASS/FAIL | `security-auditor`: threat model + validated findings |
| **Compliance** | Play policy ≠ clause mapping | `compliance`: framework clause map, evidence gaps, audit export shape |
| **Dependencies** | May note outdated deps in category | `dependency-risk`: CVE/EPSS, blast-radius graph, skill/MCP trust |
| **Relationship** | Stays final ship gate | Specialists invoked on FAIL or pre-release optional depth; release-readiness does not duplicate WCAG table |

### vs `test-strategy`

| Dimension | `test-strategy` | `test-executor` |
|-----------|-----------------|-----------------|
| **Purpose** | Plan what to test, skip, and why **before** dev | Execute tests **after** dev per strategy |
| **Output** | `.ai/context/test-strategies/{TASK_ID}.md` | `.ai/context/test-runs/{TASK_ID}.md` |
| **Code** | Never patches test or production code | Never writes new production code; may run existing test commands |
| **Chain position** | Pre-dev (with planner/architect) | Post-dev, pre-reviewer |
| **Reviewer** | Reviewer verifies strategy alignment (step 0d) | Reviewer consumes pass/fail evidence from test-run brief |

### vs `ux-intelligence`

| Dimension | `ux-intelligence` | `a11y` |
|-----------|-------------------|--------|
| **Purpose** | Behavioral friction — user journey simulation | WCAG 2.2 AA conformance — criteria, ARIA, contrast, keyboard |
| **Scope** | Interaction quality; empty/loading/error paths | Accessibility standards; assistive-tech simulation notes |
| **Exclusions** | No layout/cosmetic redesign | No behavioral friction analysis (defer to ux-intelligence) |
| **Chain** | Pre-dev or post-dev UX review | Post-ux-intelligence or parallel trigger; sequential spawn |
| **Overlap** | RTL/i18n *behavioral* friction | `i18n` owns locale/string architecture; `a11y` owns a11y+i18n-a11y overlap (dir, logical properties) |

### vs MAS-01 agents (no overlap)

| MAS-01 agent | Boundary |
|--------------|----------|
| `mas-debate` | 2-round critic micro-chain on 2nd reviewer rejection only; security-persona is capped, not STRIDE depth |
| `mas-token-auditor` | Post-workflow advisory telemetry; not security/supply-chain audit |
| `spawn-model-policy` | Model routing only; new agents extend the map, do not replace policy |

### Cross-specialist exclusion

| Pair | Rule |
|------|------|
| `security-auditor` ↔ `compliance` | Security = exploitability; compliance = regulatory clause evidence. May both spawn on same TASK_ID when `COMPLIANCE_FRAMEWORK` + auth changes. |
| `api-contract` ↔ `architect` | Architect designs contracts; api-contract lints/diffs/conformance only. |
| `dependency-risk` ↔ `migration` | dependency-risk = point-in-time delta; migration = behavioral parity program across waves. |
| `observability` ↔ `imaginer` | observability = prod signals first; imaginer = local code trace confirm. |
| `chaos-resilience` ↔ `reviewer` | chaos-resilience = orchestrator fault injection; advisory, non-blocking. |

---

## Domain & Contracts

### Brief schema additions (per `brief-schemas.md`)

| Type | Path | Required sections |
|------|------|-------------------|
| security-audit | `.ai/context/security-audits/{TASK_ID}.md` | Threat model, Findings, Validation, Blockers |
| api-contract | `.ai/context/api-contracts/{TASK_ID}.md` | Spec inventory, Breaking changes, Drift, Recommendations |
| supply-chain | `.ai/context/supply-chain/{TASK_ID}.md` | Dependency delta, CVE summary, Blast radius, Remediation |
| test-run | `.ai/context/test-runs/{TASK_ID}.md` | Commands, Pass/fail, Failures, Gaps |
| a11y-review | `.ai/context/a11y-reviews/{TASK_ID}.md` | WCAG table, Findings, Fix priority, Manual checklist |
| compliance | `.ai/context/compliance/{TASK_ID}.md` | Framework map, Gaps, Evidence, Remediation |
| i18n-review | `.ai/context/i18n-reviews/{TASK_ID}.md` | String inventory, Locale gaps, RTL, Recommendations |
| observability | `.ai/context/observability/{TASK_ID}.md` | Hypotheses, Correlation, Root cause, Code areas |
| migration | `.ai/context/migrations/{TASK_ID}.md` | Inventory, Behavioral rules, Waves, Validation |
| resilience | `.ai/context/resilience/{TASK_ID}.md` | Fault scenarios, Pass rates, Weak points, Recommendations |

### Spawn model policy extensions

| Agent slug | MODEL_CLASS |
|------------|-------------|
| security-auditor | thinking |
| api-contract | normal |
| dependency-risk | fast |
| test-executor | normal |
| a11y | normal |
| i18n | normal |
| compliance | thinking |
| observability | thinking |
| migration | thinking |
| chaos-resilience | normal |

### Subscription matrix (read at startup)

| Agent | Reads |
|-------|-------|
| security-auditor | osint, architecture, plans, changed FILES |
| api-contract | osint, architecture, api specs in FILES |
| dependency-risk | osint, plans, lockfiles/manifest/skills in FILES |
| test-executor | test-strategies, plans, handoff FILES |
| a11y | ux-reviews (if exists), plans, UI FILES |
| i18n | plans, string/resource FILES |
| compliance | osint, architecture, COMPLIANCE_FRAMEWORK handoff |
| observability | osint, imaginations, SOURCES_HINT telemetry |
| migration | osint, brainstorms, prior migrations, architecture |
| chaos-resilience | protocol/skills in FILES, workflow session JSON |

### Specialist invariants (all agents)

- Read-only audit or bounded CI/shell commands listed in skill
- Write brief to disk; chat return = one-line summary + path
- Never spawn Task subagents
- Never patch production source (test-executor: run only, no new test code unless explicit future policy)
- Never replace reviewer approval or release-readiness ship gate

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| No OpenAPI in repo but REST changes | `api-contract` skipped; architect + reviewer own contract |
| `test-strategy` says skip UI tests | `test-executor` documents skip rationale in Gaps section; does not force run |
| `release-readiness` Accessibility PASS but user requests a11y | `A11Y_AUDIT: yes` overrides; a11y runs optional depth |
| Security-auditor + debate security-persona same TASK_ID | Debate only on 2nd reviewer rejection; security-auditor on predicate — no duplicate if debate already ran unless `RE_AUDIT: yes` |
| dependency-risk on MAS framework TASK_ID | MAS-self-scan mode: skills, hooks, MCP manifest, `.cursorrules` trust |
| observability without telemetry MCP | Write brief with "credentials unavailable"; route to imaginer + user HITL |
| compliance without `COMPLIANCE_FRAMEWORK` | Do not spawn; release-readiness compliance category only |
| Lite 12-line handoff | Abbreviated flags; Phase A specialists only in Lite L tier |
| test-executor flaky suite | Document flaky tests; do not auto-retry beyond skill-defined cap |
| migration + api-contract same upgrade | migration first (behavioral spec); api-contract on resulting API surface |

---

## Quality Bar

- **Deterministic routing:** Coordinator predicates are zero-token; no LLM routing for specialist selection
- **Idempotency:** Max one spawn per specialist per TASK_ID unless `RE_AUDIT: yes`
- **Artifact-forward:** User summary = one line + `BRIEF_PATH`; no inline brief bodies in chat
- **Schema validation:** Reviewer flags missing required sections per `brief-schemas.md`
- **Sequential spawn:** Default; parallel only with explicit `PARALLEL_READ: YES`
- **HITL:** observability and compliance remediation require user approval for prod/legal actions
- **Supply-chain:** dependency-risk includes skill-poisoning awareness (OWASP ASI, MAS-01 context)
- **Legal:** compliance skill header + brief template include "not legal advice" disclaimer
- **Framework self-dogfood:** chaos-resilience + dependency-risk run on MAS protocol changes

---

## Risks & Open Questions

| Risk / Question | Impact | Planner/Architect decision |
|-----------------|--------|---------------------------|
| Should `security-auditor` block equivalently to reviewer? | Workflow termination semantics | Recommend advisory v1; `SECURITY_BLOCKER: yes` opt-in for user policy |
| Is `test-executor` allowed to fix failing tests inline? | Role boundary vs bug-fix | Recommend run-only v1; route failures to bug-fix |
| Datadog/PagerDuty MCP in default Cursor installs? | observability Phase C viability | Document optional MCP; degrade to imaginer + user |
| Bundle `a11y` + `i18n` for token savings? | Maintenance vs cost | Recommend separate (Option 2); revisit if spawn cost measured high |
| `compliance` legal disclaimer placement | Enterprise adoption | Skill header + brief template (both) |
| Reviewer step proliferation (0f–0j for new brief types) | Reviewer token cost | Add conditional read steps only when brief exists |
| Phase A increases full-chain agent count toward `MAX_CHAIN_AGENTS` | Cap violations | Coordinator may skip optional specialists in Lite; document priority order |
| False positives from security-auditor | Dev friction | Validation notes section required; candidate → validate → report pattern |

---

## Suggested Next

**planner** — Break Phase A into install tasks: four skill stubs, manifest entries, protocol file edits, routing table in `mas-coordinator/SKILL.md`, acceptance criteria per specialist, and regression checklist for mutual-exclusion with reviewer/release-readiness/test-strategy/ux-intelligence.
