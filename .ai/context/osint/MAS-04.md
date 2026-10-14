# OSINT Brief — MAS-04

## Research Mode

FEATURE

## Topic

What product-level specialist agents do production-grade AI dev systems (2025–2026) use that Cursor MAS v1.1 lacks — security, compliance, API contracts, migration, observability, product shaping, QA execution, a11y, i18n, dependency risk, chaos/resilience — and how should they integrate into deterministic Coordinator chains?

## Scope

Cursor MAS framework v1.1 — 19 specialist skills in `install/manifest.json` plus `mas-coordinator` and `mas-lite`. Compared against Devin/Cognition Security Swarm, GitHub Copilot cloud/SDK custom agents, Factory Droid security-reviewer and Missions, SWE-agent/AgentForge role decomposition, OWASP ASI/LLM Top 10, enterprise compliance layers, and OSS specialist kits (a11y-agents, api-contract-validator, agent-bom). **Excludes** orchestration/token/debate topics covered in MAS-01 OSINT.

## Research Summary

Production AI SDLC platforms converge on **narrow specialists with scoped tools and artifact outputs**, not broader generalists. Security (STRIDE + OWASP LLM), API contract drift, supply-chain blast-radius, and compliance evidence are **separate roles** from code review and release checklists. Test **execution** is distinct from test **strategy**. Deep WCAG/i18n audits exceed release-readiness category sweeps. SRE/observability agents triage production signals; migration agents preserve behavioral specs across rewrites. MAS already covers planning, implementation, review, perf, UX friction, release gate, and token/debate micro-chains — but lacks eight high-impact product-delivery specialists. Highest ROI additions: **security-auditor**, **api-contract**, **dependency-risk**, **test-executor**, **a11y** — each writes a brief, runs read-only or CI commands, and routes findings to dev/bug-fix/reviewer without duplicating existing gates.

## Sources Consulted

| # | Source | Tier | Date | Version | Notes |
|---|--------|------|------|---------|-------|
| 1 | https://cognition.com/blog/devin-fedramp-high-in-process | official | 2026-07 | Devin Cloud | Security Swarm, SBOM, vulnerability remediation PRs |
| 2 | https://factory.ai/news/automated-security-review | official | 2026-07 | Droid | STRIDE security-reviewer subagent, supply-chain in PR pass |
| 3 | https://docs.github.com/en/copilot/responsible-use/agents | official | 2026-07 | Copilot SDK | Custom agents, CodeQL/secret/dependency scan on codegen |
| 4 | https://github.com/github/copilot-sdk/blob/main/docs/features/custom-agents.md | official | 2026-07 | Copilot SDK | Scoped tools, infer-based delegation, sub-agent isolation |
| 5 | https://cheatsheetseries.owasp.org/cheatsheets/AI_Agent_Security_Cheat_Sheet.html | official | 2026-07 | OWASP | Tool allowlists, HITL, multi-agent security, testing |
| 6 | https://arxiv.org/html/2603.00195v1 | official | 2026-03 | SkillFortify | Agent skill supply chain, ASBOM, SAT resolution |
| 7 | https://github.com/msaad00/agent-bom | maintained OSS | 2026-07 | agent-bom | CVE → MCP → agent blast radius, CycloneDX 1.6 |
| 8 | https://arxiv.org/pdf/2604.13120 | official | 2026-04 | AgentForge | Planner/Coder/Tester/Debugger/Critic roles |
| 9 | https://www.pagerduty.com/eng/inside-pagerdutys-sre-agent-how-we-built-deep-incident-investigation/ | official | 2026-07 | PagerDuty SRE Agent | Multi-hypothesis sub-agents, live RCA |
| 10 | https://github.com/Community-Access/accessibility-agents | maintained OSS | 2026-07 | accessibility-agents | WCAG 2.2 specialist roster + MCP scanners |
| 11 | https://github.com/robotijn/ctoc/blob/main/agents/specialized/api-contract-validator.md | maintained OSS | 2026-07 | api-contract-validator | OpenAPI lint/diff/conformance pattern |
| 12 | https://doi.org/10.48550/arxiv.2605.17535 | official | 2026-05 | AgentModernize | Extraction → spec → transform → validation migration loop |
| 13 | https://zylos.ai/research/2026-04-09-chaos-engineering-ai-agent-systems/ | community | 2026-04 | Zylos/ReliabilityBench | Agent fault injection, rate-limit as top failure mode |

## Findings

| # | Source | Context | Pattern/Fix | Tradeoffs | Applicability | Recommendation | Confidence |
|---|--------|---------|-------------|-----------|---------------|----------------|------------|
| 1 | Devin Security Swarm + Factory security-reviewer | PR-time and repo-wide vulnerability validation with exploitability proof | Dedicated **security-reviewer** traces data flows (auth, validation, DB, network, LLM boundaries); STRIDE + OWASP Top 10 + OWASP LLM Top 10; candidate → validate → report; posts remediation handoff not inline patches in gate mode | Extra spawn per security-sensitive change; false-positive tuning needed | MAS `reviewer` checks change quality; `debate` security-persona is capped micro-chain only; `release-readiness` lacks deep threat modeling | **adapt** — add `mas-security-auditor` | HIGH |
| 2 | GitHub Copilot cloud agent + SDK | Automated security during codegen | CodeQL + secret scanning + dependency analysis on **new** code before merge; custom agents with **tool allowlists** per specialist | Requires CI integration; not all stacks have CodeQL | MAS dev agents have full tool access — no security-scoped read pass | **adapt** — security-auditor read-only + optional CI command refs in brief | HIGH |
| 3 | OWASP ASI Top 10 + Agent Security Cheat Sheet | Multi-agent orchestration risks | Per-agent tool registry, memory isolation, HITL for destructive ops, structured audit metadata; **specialist security testing** before production | Policy maintenance overhead | Directly applies to MAS skill/MCP expansion (MAS-01 noted skill poisoning) | **adapt** — `mas-dependency-risk` for framework + app deps | HIGH |
| 4 | agent-bom / ai-bom / Phoenix 2026 corpus | AI supply chain beyond CVE tables | Map CVE → package → MCP server → agent → credentials → tools; scan `.cursorrules`, skills, hooks for hidden instructions; CycloneDX ASBOM | New tooling; may need network for OSV/NVD | Critical for MAS framework distributing 20+ skills | **adopt** — `mas-dependency-risk` specialist | HIGH |
| 5 | api-contract-validator + OpenAPI drift tools | Silent client breaks from schema drift | Lint spec (Spectral), diff breaking changes (oasdiff), conformance vs live impl; migration guide for consumers | Needs OpenAPI/GraphQL/Proto in scope | API-heavy backends, BFF, mobile clients | **adopt** — `mas-api-contract` | HIGH |
| 6 | AgentForge Tester + Copilot integration-tester | Test role separate from planner/coder | **Tester** agent produces/runs tests, **Critic** reviews; execution-grounded loop | Token cost if runs full suite | MAS `test-strategy` plans only; `reviewer` may run tests but not own strategy+execution | **adapt** — `mas-test-executor` | HIGH |
| 7 | accessibility-agents + a11y-agents-kit | WCAG 2.2 AA enforcement beyond checklist | Dedicated a11y specialists: ARIA, contrast, keyboard, screen-reader simulation, RTL/i18n-a11y overlap; MCP axe/Pa11y tools | Does not replace user testing with assistive tech | `release-readiness` Accessibility = PASS/FAIL sweep; `ux-intelligence` = behavioral friction not WCAG | **adapt** — `mas-a11y` | HIGH |
| 8 | i18n-specialist / maestro patterns | Multilingual delivery | ICU MessageFormat, locale tags, `dir`, logical CSS, pluralization, string extraction audit | Niche unless i18n in scope | `release-readiness` Localization category is shallow | **adapt** — `mas-i18n` | MEDIUM |
| 9 | Sentrik / Aguardic / Devin FedRAMP | Regulatory evidence for AI-generated code | Map changes to framework clauses (GDPR, SOC2, HIPAA, EU AI Act); runtime scope enforcement; audit exports | Enterprise-only; policy packs vary | `release-readiness` Play policy ≠ full compliance mapping | **adapt** — `mas-compliance` | MEDIUM |
| 10 | PagerDuty/Datadog/Dynatrace SRE agents 2026 | Production incident triage | Orchestrator spawns hypothesis sub-agents (logs, metrics, deploys); HITL for remediation; writes RCA brief | Needs observability MCP/credentials | MAS `imaginer` traces local code paths; no production telemetry agent | **adapt** — `mas-observability` | MEDIUM |
| 11 | AgentModernize + Factory Missions + EY 2026 | Legacy/migration programs | Pipeline: discovery → behavioral spec graph → transform → differential validation → strangler retirement; human gates on BSG artifacts | Large scope; not every TASK_ID | No MAS role for framework/library upgrades or legacy parity | **adapt** — `mas-migration` | MEDIUM |
| 12 | ReliabilityBench + AgentChaos + agentfuzz | Agent/system resilience under fault | Inject tool timeouts, malformed JSON, rate limits, schema drift, prompt injection; score pass-rate per fault class | Meta — tests orchestrator not app under dev | Valuable for MAS framework hardening; lower frequency for feature chains | **adapt** — `mas-chaos-resilience` (framework QA) | MEDIUM |
| 13 | Factory GA + product kits | Product/spec shaping before build | Research + spec agents answer complex questions, write quality specs/tickets; distinct from implementer | Overlap with brainstorm/spec-reader if poorly bounded | `spec-reader` ingests existing docs; `brainstorm` compares internal options | **adapt** — `mas-product` for greenfield shaping | MEDIUM |

## Recommended Approach

Add **eight primary specialists** (v1.2 roster) plus **two qualified specialists** (enterprise/niche). Each follows MAS conventions: read-only audit or bounded CI commands, brief on disk, Coordinator deterministic routing, no inline brief bodies in chat.

### Differentiation from existing MAS agents

| Existing | Gap | New agent |
|----------|-----|-----------|
| `reviewer` | Change-set approval, not STRIDE threat model | `security-auditor` |
| `debate` security-persona | 2-round critic only on rejection | `security-auditor` |
| `release-readiness` | 17-category PASS/FAIL ship gate | `a11y`, `i18n`, `compliance` deep dives |
| `test-strategy` | Plans tests, no execution ownership | `test-executor` |
| `ux-intelligence` | Interaction friction, not WCAG | `a11y` |
| `imaginer` | Local code/data-flow trace | `observability` (prod signals) |
| `osint` | External prior art | specialists consume osint, not replace |
| `perf-optimizer` | Slowness/jank primary | `chaos-resilience` (fault injection) |

---

### Proposed specialist roster (prioritized)

#### 1. `mas-security-auditor` — P0

| Field | Value |
|-------|-------|
| **Trigger** | Handoff `SECURITY_AUDIT: yes`; API/auth/crypto changes; `reviewer` flags security; user `/mas` security intent; pre-release optional alongside `release-readiness` |
| **Deliverable** | `.ai/context/security-audits/{TASK_ID}.md` |
| **MODEL_CLASS** | `thinking` |
| **Chain** | `architect` or `dev` prep → **security-auditor** → `dev`/`bug-fix` (findings only) → `reviewer`; or post-dev pre-reviewer |
| **Brief sections** | Threat model summary, Findings table (severity, CWE/OWASP ref, exploit path, suggested fix), Validation notes, Blockers |
| **Never** | Patch code; replace `reviewer` gate |

Pattern: Factory `security-reviewer` — trace untrusted input across boundaries; validate candidates before reporting (adapt).

---

#### 2. `mas-api-contract` — P0

| Field | Value |
|-------|-------|
| **Trigger** | OpenAPI/GraphQL/Proto files in `FILES`; REST/BFF changes; `SCOPE` mentions API versioning; breaking-change fear |
| **Deliverable** | `.ai/context/api-contracts/{TASK_ID}.md` |
| **MODEL_CLASS** | `normal` |
| **Chain** | `architect` → **api-contract** (if API surface designed) → `dev`; or post-dev pre-`reviewer` when API files changed |
| **Brief sections** | Spec inventory, Breaking changes table, Drift findings, Safe evolution recommendations, Consumer impact |
| **Never** | Replace `architect` contract design; patch handlers |

Pattern: Spectral lint + oasdiff breaking detection + conformance matrix (adapt).

---

#### 3. `mas-dependency-risk` — P0

| Field | Value |
|-------|-------|
| **Trigger** | Dependency upgrades; new npm/PyPI/Gradle coords; MCP/skills/hooks added; `SCOPE: supply-chain`; MAS framework manifest changes |
| **Deliverable** | `.ai/context/supply-chain/{TASK_ID}.md` |
| **MODEL_CLASS** | `fast` |
| **Chain** | Early in chain after `osint` for upgrade tasks: **dependency-risk** → `planner`/`architect`; or pre-`commit`/`release-readiness` |
| **Brief sections** | Dependency delta, CVE/EPSS summary, Blast radius (package→runtime→secrets), Skill/MCP trust notes, Remediation priority |
| **Never** | Auto-bump versions without handoff |

Pattern: agent-bom blast-radius graph + skill poisoning awareness (adapt). Critical for MAS skill distribution surface.

---

#### 4. `mas-test-executor` — P0

| Field | Value |
|-------|-------|
| **Trigger** | `test-strategy` brief exists; `reviewer` requests test evidence; handoff `RUN_TESTS: yes`; post-dev verification |
| **Deliverable** | `.ai/context/test-runs/{TASK_ID}.md` |
| **MODEL_CLASS** | `normal` |
| **Chain** | `test-strategy` → `dev` → **test-executor** → `reviewer` (optional skip if dev ran all P0 tests) |
| **Brief sections** | Commands run, Pass/fail summary, Failed test analysis, Flaky notes, Coverage gaps vs strategy |
| **Never** | Replace `test-strategy` planning; write new production code |

Pattern: AgentForge Tester role — execution-grounded feedback to dev (adapt).

---

#### 5. `mas-a11y` — P1

| Field | Value |
|-------|-------|
| **Trigger** | UI/`FILES` include components/screens; `release-readiness` Accessibility FAIL; user a11y intent; new interactive widgets |
| **Deliverable** | `.ai/context/a11y-reviews/{TASK_ID}.md` |
| **MODEL_CLASS** | `normal` |
| **Chain** | `ux-intelligence` ∥ optional **a11y** (sequential spawn only — Coordinator picks primary); → `dev` → `reviewer` |
| **Brief sections** | WCAG criterion table, Component findings, Keyboard/screen-reader notes, Fix priority, Manual test checklist |
| **Never** | Cosmetic/layout redesign (same boundary as ux-intelligence) |

Pattern: accessibility-agents WCAG 2.2 specialist decomposition (adapt).

---

#### 6. `mas-compliance` — P1 (enterprise-qualified)

| Field | Value |
|-------|-------|
| **Trigger** | `COMPLIANCE_FRAMEWORK:` on handoff (GDPR, SOC2, HIPAA, EU AI Act, FedRAMP); regulated industry in `project.md`; AI-agent governance changes |
| **Deliverable** | `.ai/context/compliance/{TASK_ID}.md` |
| **MODEL_CLASS** | `thinking` |
| **Chain** | Post-`architect` or pre-`release-readiness`: **compliance** → `dev`/`documenter`; evidence for audit bundles |
| **Brief sections** | Framework mapping, Control gaps, Evidence needed, AI-agent-specific notes (scope, logging, PII), Remediation tasks |
| **Never** | Legal advice; auto-approve compliance |

Pattern: Sentrik/Aguardic clause-mapped enforcement + evidence export (adapt).

---

#### 7. `mas-i18n` — P1

| Field | Value |
|-------|-------|
| **Trigger** | New user-facing strings; locale/RTL work; `release-readiness` Localization FAIL; `SCOPE: i18n` |
| **Deliverable** | `.ai/context/i18n-reviews/{TASK_ID}.md` |
| **MODEL_CLASS** | `normal` |
| **Chain** | Parallel to **a11y** when both triggered (sequential spawn): **i18n** → `dev` |
| **Brief sections** | String inventory, Locale/tag gaps, RTL/logical layout, Pluralization/date/number, Extraction recommendations |
| **Never** | Translation vendor workflow; patch unless handoff routes to dev |

Pattern: i18n-specialist ICU/locale architecture audit (adapt).

---

#### 8. `mas-observability` — P2

| Field | Value |
|-------|-------|
| **Trigger** | Production incident handoff; `SYMPTOM: prod`; logs/metrics/traces in `SOURCES_HINT`; on-call triage before `imaginer` |
| **Deliverable** | `.ai/context/observability/{TASK_ID}.md` |
| **MODEL_CLASS** | `thinking` |
| **Chain** | **observability** → `imaginer` (local confirm) → `bug-fix`; or **observability** → `bug-fix` when trace pinpoints code |
| **Brief sections** | Hypothesis tree, Signal correlation, Ruled-out causes, Likely root cause, Suggested code areas, Runbook actions (HITL) |
| **Never** | Autonomous prod remediation without explicit handoff approval |

Pattern: PagerDuty SRE Agent multi-hypothesis sub-investigation (adapt).

---

#### 9. `mas-migration` — P2 (qualified)

| Field | Value |
|-------|-------|
| **Trigger** | `MIGRATION_TYPE:` (framework upgrade, API migration, legacy rewrite, strangler); large dependency major versions; COBOL/legacy mentioned |
| **Deliverable** | `.ai/context/migrations/{TASK_ID}.md` |
| **MODEL_CLASS** | `thinking` |
| **Chain** | `osint` → **migration** → `planner` → `architect` → dev chain; behavioral spec graph as input to `test-strategy` |
| **Brief sections** | Source inventory, Behavioral rules, Parity risks, Phased waves, Validation strategy, Rollback plan |
| **Never** | Big-bang rewrite without phased plan |

Pattern: AgentModernize extraction→spec→transform→validation loop (adapt).

---

#### 10. `mas-chaos-resilience` — P3 (framework/meta)

| Field | Value |
|-------|-------|
| **Trigger** | MAS protocol/skill changes; `SCOPE: mas-framework`; post-implementation hardening; Coordinator `CHAOS_AUDIT: yes` |
| **Deliverable** | `.ai/context/resilience/{TASK_ID}.md` |
| **MODEL_CLASS** | `normal` |
| **Chain** | After protocol changes: **chaos-resilience** → `reviewer`; advisory, non-blocking |
| **Brief sections** | Fault scenarios tested, Pass rates by fault class, Orchestrator weak points, Cap/limit recommendations, Retry storm risks |
| **Never** | Production fault injection; block workflow |

Pattern: ReliabilityBench fault taxonomy + agentfuzz seam-breaking (adapt). Meta-agent for MAS reliability.

---

#### Deferred: `mas-product` (watch list)

Shapes PRD/user outcomes before `brainstorm` on greenfield. Overlaps `spec-reader` + `brainstorm` if triggers are loose. **Defer v1.2** unless user explicitly requests product discovery mode; use handoff `PRODUCT_SHAPING: yes` when added.

---

### Chain integration summary

```
Feature (API + UI, full /mas):
Coordinator → osint → brainstorm → planner → architect
  → api-contract (if API) → test-strategy → dev
  → security-auditor (if auth/API) → test-executor → a11y/i18n (if UI)
  → documenter → reviewer → [debate loop per MAS-01] → commit

Dependency upgrade:
Coordinator → osint → dependency-risk → planner → dev → test-executor → reviewer

Production bug:
Coordinator → observability → imaginer → bug-fix → test-executor → reviewer

Release:
Coordinator → release-readiness (+ optional compliance, dependency-risk, security-auditor)

MAS framework change:
Coordinator → planner → dev → chaos-resilience → reviewer → token-auditor
```

### `spawn-model-policy.md` additions (sketch)

| Agent slug | `MODEL_CLASS` |
|------------|---------------|
| security-auditor | `thinking` |
| api-contract | `normal` |
| dependency-risk | `fast` |
| test-executor | `normal` |
| a11y | `normal` |
| i18n | `normal` |
| compliance | `thinking` |
| observability | `thinking` |
| migration | `thinking` |
| chaos-resilience | `normal` |

### `brief-schemas.md` additions (sketch)

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

### Subscription matrix extensions (sketch)

| Agent | Reads at startup |
|-------|------------------|
| security-auditor | osint, architecture, plans, changed FILES |
| api-contract | osint, architecture, api specs in FILES |
| dependency-risk | osint, plans, lockfiles/manifest in FILES |
| test-executor | test-strategies, plans, handoff FILES |
| a11y | ux-reviews, plans, UI FILES |
| i18n | plans, string/resource FILES |
| compliance | osint, architecture, compliance handoff FRAMEWORK |
| observability | osint, imaginations, SOURCES_HINT telemetry |
| migration | osint, brainstorms, migrations (prior), architecture |
| chaos-resilience | protocol/skills in FILES, workflow session JSON |

## Priority Order

1. **security-auditor** — Highest production risk gap; industry standard on every PR (Factory/Devin/Copilot); distinct from Reviewer and debate persona.
2. **dependency-risk** — Unique 2026 attack surface (skills, MCP, hooks); protects MAS distributors and app upgrades.
3. **api-contract** — Silent client breaks are P0 in API-driven delivery; schema-first CI is consensus 2026.
4. **test-executor** — Closes plan-vs-execution gap; AgentForge and enterprise Factory patterns treat Tester as separate role.
5. **a11y** — WCAG depth beyond release-readiness checkbox; regulatory and store requirements.
6. **compliance** — Enterprise blocker for FedRAMP/SOC2 customers; evidence artifacts not covered by release-readiness.
7. **i18n** — Needed when localization is in scope; medium frequency.
8. **observability** — High value for prod bugs; needs observability credentials/MCP.
9. **migration** — High value when triggered; low frequency.
10. **chaos-resilience** — Meta-agent for MAS framework quality; defer blocking gate.

## Anti-Patterns Avoided

- **Duplicating Reviewer** — Security/compliance agents audit and brief; Reviewer remains sole change-set approval gate.
- **Replacing release-readiness** — Ship gate stays holistic; specialists feed fix routing with depth.
- **Security persona in debate only** — Production systems run continuous security pass, not just 2nd rejection.
- **Monolithic “enterprise agent”** — Factory/Copilot pattern: scoped tools per specialist, not one compliance+security+QA agent.
- **Autonomous prod remediation** — PagerDuty/Datadog pattern: HITL for remediation; MAS observability agent advises only.
- **Copying OSS agent markdown** — Pattern adaptation only; no verbatim skill paste from ctoc/accessibility-agents.

## Implementation Guidance

### For Brainstorm agent (NEXT_AGENT)

- Propose **phased roster**: Phase A (security-auditor, dependency-risk, api-contract, test-executor); Phase B (a11y, i18n, compliance); Phase C (observability, migration, chaos-resilience).
- Define Coordinator routing predicates (handoff flags above) in `mas-coordinator/SKILL.md` — deterministic, zero-token.
- Extend `install/manifest.json`, `brief-schemas.md`, `spawn-model-policy.md`, `read-order.md`, `handoff-format.md`.
- Keep **sequential spawn** — no parallel security+a11y unless user `PARALLEL_READ: YES` (MAS-01 defer).
- `dependency-risk` and `chaos-resilience` should include MAS-self-scan mode for framework TASK_IDs.

### Routing flags (handoff extensions)

```
SECURITY_AUDIT: yes
API_CONTRACT: yes
SUPPLY_CHAIN: yes
RUN_TESTS: yes
A11Y_AUDIT: yes
I18N_AUDIT: yes
COMPLIANCE_FRAMEWORK: SOC2 | GDPR | HIPAA | EU_AI_ACT | FedRAMP
OBSERVABILITY_MODE: prod-triage
MIGRATION_TYPE: framework | api | legacy | strangler
CHAOS_AUDIT: yes
```

Lite abbreviation: `SEC:y`, `API:y`, `DEPS:y`, `TEST:y`, `A11Y:y`, `I18N:y` on 12-line cap.

## License / Copy Guardrails

- Cited OSS (agent-bom, accessibility-agents, api-contract-validator, AgentChaos) — MIT/Apache patterns only.
- Do not paste Factory skills, Copilot agent.md, or ctoc agent wrappers into MAS skills.
- OWASP cheat sheets and ASI papers — prose guidance only.

## Regression Notes

N/A (feature research mode)

## Local Files Referenced

- `skills/multi-agent-system/install/manifest.json`
- `skills/multi-agent-system/protocol/spawn-model-policy.md`
- `skills/multi-agent-system/protocol/brief-schemas.md`
- `skills/mas-release-readiness/SKILL.md`
- `skills/mas-test-strategy/SKILL.md`
- `skills/mas-ux-intelligence/SKILL.md`
- `.ai/context/osint/MAS-01.md`
- `.ai/context/brainstorms/MAS-01.md`

## Open Questions

- Should `security-auditor` block merge equivalently to `reviewer`, or advisory-only v1?
- Is `test-executor` allowed to fix tests inline, or always route to `bug-fix`?
- Does Cursor expose Datadog/PagerDuty MCP for `observability` agent in default installs?
- Bundle `a11y` + `i18n` into single `mas-inclusive-design` for token savings, or keep separate?
- `compliance` legal disclaimer placement — skill header vs brief template?

## Overall Confidence

**HIGH** for security, API contract, dependency risk, test-executor, and a11y — multiple official platforms (Devin, Factory, GitHub Copilot) and maintained OSS kits agree on role separation. **MEDIUM** for compliance, observability, migration, and chaos-resilience — strong vendor patterns but stack/credential dependent and lower frequency in typical app feature chains.
