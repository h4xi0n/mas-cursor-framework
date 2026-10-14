# Test Strategy — MAS-04

## Feature

MAS-04 Phase A (v1.2.0) — P0 audit quartet: `security-auditor`, `dependency-risk`, `api-contract`, `test-executor`. Logic-only framework upgrade: protocol extensions, four skill stubs, coordinator deterministic routing, manifest bump, mutual-exclusion vs `test-strategy` / `reviewer`. No Gradle/Android surfaces.

## Scope

| Layer | Paths |
|-------|-------|
| Protocol | `skills/multi-agent-system/protocol/brief-schemas.md`, `spawn-model-policy.md`, `read-order.md`, `handoff-format.md`, `handoff-format-lite.md`, `subagent-spawn.md`, `token-rules.md` |
| Coordinator / gates | `skills/mas-coordinator/SKILL.md`, `skills/mas-reviewer/SKILL.md`, `skills/mas-lite/SKILL.md`, `skills/mas-test-strategy/SKILL.md`, `skills/mas-release-readiness/SKILL.md` |
| P0 skill stubs | `skills/mas-security-auditor/SKILL.md`, `skills/mas-dependency-risk/SKILL.md`, `skills/mas-api-contract/SKILL.md`, `skills/mas-test-executor/SKILL.md` |
| Install | `skills/multi-agent-system/install/manifest.json`, `skills/multi-agent-system/install/export-mas-framework.ps1` |
| Context dirs | `.ai/context/security-audits/`, `api-contracts/`, `supply-chain/`, `test-runs/` |
| Architecture / plan | `.ai/context/architecture/MAS-04.md`, `.ai/context/plans/MAS-04.md` (A1–A5) |

**Out of scope (Phase A):** Phase B/C specialists, Gradle unit/UI tests, production app code, `mas-product`.

## Test Surfaces

`integration` (workflow chain, handoff predicates, artifact bus) · `manual` (dogfood `/mas` sessions) · `schema` (brief registry) · `bundle` (export/manifest)

No unit test pyramid — framework is markdown/skills only.

---

## Synthetic Fixture TASK_IDs

Use these **synthetic** IDs for Phase A dogfood and regression. Do not collide with live workflow `MAS-04`.

| Fixture ID | Purpose | Handoff flags / triggers | Expected P0 spawns |
|------------|---------|--------------------------|-------------------|
| `MAS-04-FIX-P0-ALL` | Plan task 20 — full quartet dogfood | `SECURITY_AUDIT: yes`, `API_CONTRACT: yes`, `SUPPLY_CHAIN: yes`, `RUN_TESTS: yes`; `SCOPE` includes auth + REST/BFF; `FILES` includes lockfile + OpenAPI stub | dependency-risk → api-contract → (test-strategy) → dev → security-auditor → test-executor |
| `MAS-04-FIX-DEPS` | Predicate P0-1 only | `FILES` includes `package-lock.json` or `install/manifest.json` delta; no other flags | dependency-risk only (early chain) |
| `MAS-04-FIX-API` | Predicate P0-2 only | `FILES` includes `openapi.yaml` (or GraphQL/Proto stub); `API_CONTRACT: yes` optional | api-contract after architect |
| `MAS-04-FIX-SEC` | Predicate P0-3 only | `SECURITY_AUDIT: yes` OR `SCOPE` auth/crypto/API; no deps/API files | security-auditor post-dev |
| `MAS-04-FIX-TEST` | Predicate P0-4 only | `test-strategies/MAS-04-FIX-TEST.md` exists OR `RUN_TESTS: yes` | test-executor post-dev; requires strategy brief or flag |
| `MAS-04-FIX-NONE` | Negative — no P0 spawns | Logic-only docs change; no flags; no lockfile/API/auth in `FILES`/`SCOPE` | Zero P0 specialists |
| `MAS-04-FIX-SELF` | MAS-self-scan | `SCOPE: mas-framework` or `TASK_ID` matches framework edit; `FILES` lists coordinator/protocol/skills | dependency-risk self-scan brief; optional chaos-resilience deferred to Phase C |
| `MAS-04-FIX-CAP` | MAX_CHAIN_AGENTS overflow | Full feature chain + all P0 flags + debate path if possible; projected count > 12 | Skips per order: test-executor → api-contract → dependency-risk → security-auditor; `skipped_specialists` in session JSON |
| `MAS-04-FIX-RE` | Idempotency | Re-run `MAS-04-FIX-P0-ALL` without `RE_AUDIT: yes` after completion | No duplicate specialist spawn; session `specialists_spawned` blocks re-entry |
| `MAS-04-FIX-LITE-L` | Lite L tier | `/mas-lite` L tier with `SEC:y`, `API:y`, `DEPS:y`, `TEST:y` within 12-line handoff | Subset of P0 per Lite cap (3 agents tier + overflow skip) |
| `MAS-04-FIX-SCHEMA` | Brief schema gaps | Manually create specialist brief missing required heading | Reviewer `Approved: NO` with schema gap note |
| `MAS-04-FIX-BOUNDARY` | test-strategy vs test-executor | Same as P0-ALL | test-strategy before dev; test-executor after dev; test-strategy never executes shell commands |

**Fixture artifact paths (expected after successful dogfood for `MAS-04-FIX-P0-ALL`):**

- `.ai/context/supply-chain/MAS-04-FIX-P0-ALL.md`
- `.ai/context/api-contracts/MAS-04-FIX-P0-ALL.md`
- `.ai/context/security-audits/MAS-04-FIX-P0-ALL.md`
- `.ai/context/test-runs/MAS-04-FIX-P0-ALL.md`
- `.ai/context/test-strategies/MAS-04-FIX-P0-ALL.md` (pre-dev, from test-strategy agent)
- `.ai/handoffs/MAS-04-FIX-P0-ALL-*.md` per spawned specialist

---

## Chain Permutation Matrix (Phase A)

Base mandatory chain (full `/mas` feature, no overflow):  
`coordinator → osint → brainstorm → planner → architect → [optional early deps] → [optional api-contract] → test-strategy → dev → [optional security-auditor] → [optional test-executor] → documenter → reviewer → [debate?] → [commit?]`

| # | Permutation | Triggers | Expected specialist order (P0 only) | Notes |
|---|-------------|----------|--------------------------------------|-------|
| 1 | Full P0 quartet | All four flags + matching FILES/SCOPE | dependency-risk (early) → api-contract → test-strategy → dev → security-auditor → test-executor | Plan task 20 acceptance |
| 2 | Deps + API only | `SUPPLY_CHAIN` + OpenAPI in FILES | dependency-risk → api-contract → test-strategy → dev → documenter → reviewer | No sec/test-executor |
| 3 | Sec + test only | `SECURITY_AUDIT` + strategy brief | test-strategy → dev → security-auditor → test-executor | No deps/api-contract |
| 4 | FILES-only deps | lockfile in FILES, no `SUPPLY_CHAIN` flag | dependency-risk (predicate P0-1) | Flag optional when FILES match |
| 5 | FILES-only API | OpenAPI in FILES, no `API_CONTRACT` flag | api-contract (predicate P0-2) | Post-architect slot |
| 6 | Strategy-only test trigger | Brief at `test-strategies/{ID}.md`, no `RUN_TESTS` | test-executor after dev | Predicate P0-4 second clause |
| 7 | RUN_TESTS without strategy | `RUN_TESTS: yes`, no strategy file | test-executor after dev | Explicit flag path |
| 8 | Design-time security | `SECURITY_AUDIT` + pre-dev SCOPE | security-auditor post-architect OR post-dev per coordinator table | Document which slot coordinator implements |
| 9 | Cap stress | Permutation 1 + maximum optional agents | Overflow skip: test-executor, api-contract, dependency-risk, security-auditor (in order) | Verify user summary + `skipped_specialists` |
| 10 | Lite S/M regression | `/mas-lite` S or M, no flags | No P0 spawns | Unchanged behavior |
| 11 | Lite L + flags | L tier, abbreviated flags | Up to tier cap; same skip order if overflow | SEC/API/DEPS/TEST abbreviations |
| 12 | Re-audit | `RE_AUDIT: yes` on second pass | Same specialist may spawn again | Idempotency exception |

**Ordering invariants (P0 — must hold for every permutation):**

1. `test-strategy` always **before** `dev` (general-dev / android-dev).
2. `test-executor` always **after** `dev`, **before** `documenter` (or pre-reviewer if documenter skipped).
3. `dependency-risk` early slot: after osint, before planner/architect when triggered early; OR pre-release per coordinator table.
4. `api-contract` after architect when in planning chain.
5. Max **one** spawn per P0 slug per TASK_ID unless `RE_AUDIT: yes`.
6. Reviewer remains sole `Approved:` authority; specialists never patch production code.

---

## Predicate Test Cases (P0 quartet)

| ID | Predicate | Handoff / context setup | Expected spawn | Expected brief path | Pass criteria |
|----|-----------|-------------------------|----------------|---------------------|---------------|
| P0-1a | `SUPPLY_CHAIN: yes` | Flag only; minimal FILES | dependency-risk | `supply-chain/{TASK_ID}.md` | Brief has Dependency delta, CVE summary, Blast radius, Remediation |
| P0-1b | lockfile/manifest in FILES | `FILES: package-lock.json` or `install/manifest.json`; no flag | dependency-risk | same | Predicate fires without explicit flag |
| P0-1c | MAS-self-scan | `SCOPE: mas-framework`; FILES list skills/protocol | dependency-risk | same | Brief covers skills, hooks, MCP manifest scope |
| P0-2a | `API_CONTRACT: yes` | Flag + architecture brief | api-contract | `api-contracts/{TASK_ID}.md` | Spec inventory, Breaking changes, Drift, Recommendations |
| P0-2b | OpenAPI in FILES | `FILES: openapi.yaml`; no flag | api-contract | same | FILES trigger without flag |
| P0-2c | REST/BFF in SCOPE | `SCOPE` mentions REST/BFF; no spec file | api-contract | same OR graceful skip note in coordinator log | If no spec: api-contract skill skips gracefully per plan A2 |
| P0-3a | `SECURITY_AUDIT: yes` | Flag on auth-related TASK | security-auditor | `security-audits/{TASK_ID}.md` | Threat model, Findings, Validation, Blockers |
| P0-3b | auth/crypto in SCOPE | `SCOPE: JWT refresh flow` | security-auditor | same | SCOPE trigger |
| P0-3c | Advisory v1 | Blockers in brief | reviewer reads 0f | — | Merge **not** blocked unless `SECURITY_BLOCKER: yes` |
| P0-4a | test-strategy brief exists | `test-strategies/{TASK_ID}.md` present | test-executor | `test-runs/{TASK_ID}.md` | Commands, Pass/fail, Failures, Gaps |
| P0-4b | `RUN_TESTS: yes` | No strategy file | test-executor | same | Explicit flag sufficient |
| P0-4c | Run-only boundary | test-executor on failing manual check | test-run brief + handoff to bug-fix | — | Executor documents failure; does **not** patch tests/code |
| P0-4d | Strategy skip documented | Strategy brief lists skip with rationale | test-executor | Gaps section cites strategy skip | No command execution for skipped rows |

**Spawn model policy (verify in `spawn-model-policy.md` after A1):**

| Slug | Expected `MODEL_CLASS` |
|------|------------------------|
| security-auditor | thinking |
| api-contract | normal |
| dependency-risk | fast |
| test-executor | normal |

---

## Tests to Write

| # | Type | Target | Scenario | Rationale | Priority | Flaky risk | Mitigation | Command hint |
|---|------|--------|----------|-----------|----------|------------|------------|--------------|
| 1 | manual | `MAS-04-FIX-P0-ALL` dogfood | Run full `/mas` with all four flags; verify chain order and four brief paths | Plan task 20 acceptance; core Phase A ship gate | P0 | LOW | Single coordinator session; record session JSON | Manual: `/mas` with synthetic handoff per fixture table |
| 2 | integration | `brief-schemas.md` registry | Spot-check each P0 type has required sections in registry table | Reviewer schema validation depends on registry | P0 | LOW | Read registry only | `rg "security-audit|api-contract|supply-chain|test-run" skills/multi-agent-system/protocol/brief-schemas.md` |
| 3 | integration | `handoff-format.md` flags | Verify `SECURITY_AUDIT`, `API_CONTRACT`, `SUPPLY_CHAIN`, `RUN_TESTS` documented with defaults | Zero-token routing inputs | P0 | LOW | — | `rg "SECURITY_AUDIT|API_CONTRACT|SUPPLY_CHAIN|RUN_TESTS" skills/multi-agent-system/protocol/handoff-format.md` |
| 4 | integration | Lite abbreviations | `handoff-format-lite.md` has `SEC:y`, `API:y`, `DEPS:y`, `TEST:y` | Lite L tier dogfood | P1 | LOW | — | `rg "SEC:y|DEPS:y|TEST:y" skills/multi-agent-system/protocol/handoff-format-lite.md` |
| 5 | integration | `subagent-spawn.md` | Four slug rows; `run_in_background: false` preserved | Task spawn contract | P0 | LOW | — | `rg "security-auditor|dependency-risk|api-contract|test-executor" skills/multi-agent-system/protocol/subagent-spawn.md` |
| 6 | integration | `read-order.md` | Subscription rows for all four P0 agents | Startup read contract | P1 | LOW | — | `rg "security-auditor|dependency-risk|api-contract|test-executor" skills/multi-agent-system/protocol/read-order.md` |
| 7 | integration | Coordinator predicate table | `mas-coordinator/SKILL.md` matches architecture P0-1–P0-4 priority | Deterministic routing | P0 | LOW | — | Manual: compare table to `.ai/context/architecture/MAS-04.md` |
| 8 | integration | MAX_CHAIN_AGENTS overflow | `MAS-04-FIX-CAP` projects >12 agents; verify skip order in coordinator + `token-rules.md` | Cap breach policy | P0 | MED | Pre-compute projected chain before spawn | Manual dogfood + inspect `workflow-sessions/MAS-04-FIX-CAP.json` |
| 9 | integration | Session JSON idempotency | `specialists_spawned` / `skipped_specialists` fields after A3 | Overflow audit + re-entry | P0 | LOW | — | Inspect `.ai/context/workflow-sessions/{FIXTURE}.json` |
| 10 | integration | `manifest.json` v1.2.0 | Version bump; four new skills in `skills` array | Install acceptance A4 | P0 | LOW | — | `Get-Content skills/multi-agent-system/install/manifest.json \| ConvertFrom-Json` |
| 11 | integration | Export bundle | Dry-run export includes four skill directories | Install bundle integrity | P0 | LOW | Temp output dir | `powershell -File skills/multi-agent-system/install/export-mas-framework.ps1 -OutputDir $env:TEMP\mas-export-test` |
| 12 | manual | Mutual exclusion | P0-ALL run: test-strategy plans only; test-executor runs only post-dev | Boundary vs reviewer/test-strategy | P0 | LOW | — | Compare handoff `NEXT_AGENT` chain + brief timestamps |
| 13 | manual | Reviewer conditional reads | When briefs exist, reviewer steps 0f/0g/0d-ext fire; when absent, no read | Token cost bound | P1 | LOW | — | Reviewer handoff + review output for fixture |
| 14 | integration | P0 skill stubs | Each `mas-*/SKILL.md` forbids Task spawn, code patch, independent `Approved:` | Specialist invariants | P0 | LOW | — | `rg "Never|never" skills/mas-security-auditor/SKILL.md` (repeat per stub) |
| 15 | manual | `MAS-04-FIX-NONE` | No flags, no trigger FILES | Negative predicate | P1 | LOW | — | Confirm zero P0 spawns in session steps |
| 16 | integration | Context dirs | `.gitkeep` or dirs exist for four brief types | Artifact bus | P1 | LOW | — | `Test-Path .ai/context/security-audits` (etc.) |
| 17 | manual | test-executor Gaps | Strategy brief marks rows skip; executor copies rationale to Gaps | Skip propagation | P1 | LOW | — | Compare `test-strategies` skip table vs `test-runs` Gaps |
| 18 | integration | `mas-test-strategy/SKILL.md` | Documents executor boundary (plans before dev; executor after) | A5 task 17 | P1 | LOW | — | `rg "test-executor" skills/mas-test-strategy/SKILL.md` |

---

## Tests to Skip

| # | Target | Reason | Covered by |
|----|--------|--------|------------|
| 1 | Gradle `:app:testDebugUnitTest` | Logic-only framework; no Android modules or JVM test sources in MAS repo | Manual dogfood + manifest/export verification |
| 2 | Compose/UI/instrumentation tests | `UI_SCOPE: logic-only`; no screens | N/A Phase A |
| 3 | Automated pytest/npm unit suite for skills | No test harness for markdown skills in repo; ROI << manual chain verification | Manual permutation matrix + reviewer schema check |
| 4 | Live CVE/OSV network calls in CI | Offline-friendly; dependency-risk documents bounded commands in brief | Manual brief review; optional one-off OSV when network available |
| 5 | Parallel specialist spawn tests | `PARALLEL_READ: YES` deferred (MAS-01) | Sequential chain matrix only |
| 6 | Phase B/C specialists (a11y, i18n, compliance, observability, migration, chaos) | Out of Phase A scope | Phase B/C dogfood (plan tasks 35, 48) |
| 7 | `SECURITY_BLOCKER: yes` blocking semantics | Deferred opt-in; advisory v1 only in Phase A | Manual note in P0-3c; full test when user opts in |
| 8 | `mas-product` | Watch list only; not implemented | N/A |
| 9 | Re-implementing MAS-01 debate/token-auditor | Extend-only per plan | MAS-01 regression separate |
| 10 | Full 10-specialist roster regression | Phase A ships quartet only | Plan task 51 after all phases |
| 11 | Production code patch verification by specialists | Specialists audit-only by design | Confirm no git diff from specialist agents during dogfood |
| 12 | E2E Cursor IDE automation | No stable CI for Task spawn in IDE | Manual `/mas` dogfood |

---

## Edge Cases

| Case | Layer | Test approach | Priority |
|------|-------|---------------|----------|
| All P0 flags but empty FILES | Coordinator | Flags alone should still spawn; briefs may note missing artifacts | P0 |
| FILES trigger without flags | Coordinator | lockfile/OpenAPI only — verify spawn without explicit flags | P0 |
| api-contract no spec in FILES/SCOPE | api-contract skill | Graceful skip; no empty schema brief or coordinator error | P0 |
| test-executor without strategy or `RUN_TESTS` | Coordinator | Should not spawn test-executor | P0 |
| test-strategy exists but `RUN_TESTS: no` | Coordinator | test-executor still spawns (brief exists predicate) | P1 |
| Cap at exactly 12 agents | Coordinator | No skips; `skipped_specialists` empty | P1 |
| Cap at 13+ with all optional | Coordinator | First skip = test-executor per architecture | P0 |
| Re-run same TASK_ID | Session JSON | No duplicate spawn without `RE_AUDIT: yes` | P0 |
| `RE_AUDIT: yes` second pass | Session JSON | Allowed re-spawn of same slug | P1 |
| Specialist brief missing section | Reviewer | `Approved: NO` + schema gap (`MAS-04-FIX-SCHEMA`) | P0 |
| security Blockers without `SECURITY_BLOCKER` | Reviewer | Findings only; not merge-blocking | P0 |
| test-executor failure | test-executor → bug-fix | Failure documented; route to bug-fix; no inline fix | P0 |
| Offline CVE lookup | dependency-risk | Brief degrades; bounded OSV commands documented | P1 |
| Lite handoff >12 lines | Lite coordinator | Abbreviated flags keep within cap | P1 |
| Existing handoff without new flags | Backward compat | Valid; no P0 spawn unless predicates match | P1 |
| MAS-self-scan on framework TASK_ID | dependency-risk | Scans skills, hooks, MCP manifest, rules | P1 |
| documenter skipped (lite) | Chain | test-executor still before reviewer in full `/mas` | P2 |

---

## Regression Risks

N/A — `.ai/context/daily-changelog.md` has no same-day task entries (empty log for 2026-07-28). **MAS-01** routing (`spawn-model-policy`, debate, token-auditor) must not regress when extending protocol tables — spot-check during reviewer pass on MAS-04.

**Cross-workflow:** Live `MAS-04` workflow session already has steps through architect; Phase A implementation must not break existing coordinator init or changelog rollover scripts.

---

## Flaky Test Risks

| Risk | Surface | Mitigation |
|------|---------|------------|
| Manual dogfood session drift | Chain verification | Use fixed fixture TASK_IDs; record `workflow-sessions/{FIXTURE}.json` as evidence |
| Export script path/env variance | Bundle test | Use `-OutputDir $env:TEMP\mas-export-test`; verify skill folder names not zip timestamps |
| Coordinator table vs architecture drift | Predicate tests | Single source: architecture brief; coordinator must mirror on implement |
| Reviewer token/load variance | Conditional reads | Test with brief present vs absent on same TASK_ID pattern |
| Network for CVE/OSV | dependency-risk | Mark optional; do not gate Phase A on live CVE |
| Cap projection miscount | Overflow | Pre-list mandatory agents; compare to `MAX_CHAIN_AGENTS=12` before first spawn |

---

## Recommended Commands

**No Gradle.** Logic-only verification:

```powershell
# Manifest version and skill registration
Get-Content skills/multi-agent-system/install/manifest.json | ConvertFrom-Json | Select-Object version, skills

# Protocol registry spot-checks
rg "security-audit|api-contract|supply-chain|test-run" skills/multi-agent-system/protocol/brief-schemas.md
rg "SECURITY_AUDIT|API_CONTRACT|SUPPLY_CHAIN|RUN_TESTS" skills/multi-agent-system/protocol/handoff-format.md
rg "security-auditor|dependency-risk|api-contract|test-executor" skills/multi-agent-system/protocol/subagent-spawn.md
rg "test-executor" skills/multi-agent-system/protocol/token-rules.md

# Context dirs
Test-Path .ai/context/security-audits, .ai/context/api-contracts, .ai/context/supply-chain, .ai/context/test-runs

# Export dry-run (folder only)
powershell -File skills/multi-agent-system/install/export-mas-framework.ps1 -OutputDir "$env:TEMP\mas-export-phase-a-test"
Get-ChildItem "$env:TEMP\mas-export-phase-a-test" -Recurse -Directory | Where-Object { $_.Name -match 'mas-security-auditor|mas-dependency-risk|mas-api-contract|mas-test-executor' }

# Session evidence after dogfood
Get-Content .ai/context/workflow-sessions/MAS-04-FIX-P0-ALL.json | ConvertFrom-Json | Select-Object specialists_spawned, skipped_specialists, steps
```

**Manual (primary P0 gate):**

1. `/mas` synthetic feature with handoff matching `MAS-04-FIX-P0-ALL` fixture.
2. Confirm spawn order per chain matrix row #1.
3. Confirm four brief files at expected paths with required headings.
4. Confirm no production/skill patches from specialist agents (audit-only).
5. Reviewer consumes `test-runs` evidence; `Approved` flow unchanged.

**test-executor** (post-dev on fixtures with strategy brief): execute only commands listed in this brief's Recommended Commands section for manifest/protocol/export — not Gradle.

---

## Overall Confidence

**HIGH** — Scope is protocol/skills/manifest only; architecture brief and plan A1–A5 define predicates, cap policy, and mutual-exclusion. Fixture matrix and skip rationale are actionable for general-dev and Phase A dogfood without Android test infrastructure.

---

## Files Reviewed

- `.ai/handoffs/MAS-04-test-strategy.md`
- `.ai/context/plans/MAS-04.md` (Phase A A0–A5)
- `.ai/context/architecture/MAS-04.md`
- `.ai/context/memory.md`
- `.ai/context/daily-changelog.md`
- `skills/mas-coordinator/SKILL.md` (partial — pre-Phase A implementation state)
- `skills/multi-agent-system/install/manifest.json`
- `skills/multi-agent-system/install/export-mas-framework.ps1` (header)
- `skills/multi-agent-system/protocol/token-rules.md` (grep)

---

## Open Questions

1. **Design-time security slot** — Architecture allows security-auditor post-architect OR post-dev; dogfood should record which slot coordinator implements (fixture `MAS-04-FIX-SEC` row 8).
2. **api-contract graceful skip** — When REST/BFF in SCOPE but no spec file: confirm whether coordinator spawns api-contract (skill skips) or coordinator skips spawn entirely.
3. **Export skill list** — If `export-mas-framework.ps1` hardcodes skills vs reads `manifest.json`, dev should align; verify during test #11.

---

## Usage Report

Model: default
Class: normal
Tokens: unknown

DONE
