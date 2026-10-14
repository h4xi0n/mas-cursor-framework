# Test Strategy — MAS-04-B

## Feature

MAS-04 Phase B (v1.2.1) — P1 depth trio: `a11y`, `i18n`, `compliance`. Logic-only framework upgrade: protocol extensions (brief schemas, spawn policy, read-order, handoff flags), three skill stubs, coordinator UI chain (Logic Flow C), `mas-ux-intelligence` / `mas-release-readiness` / `mas-reviewer` integration, manifest bump to `1.2.1`. No Gradle/Android surfaces.

## Scope

| Layer | Paths |
|-------|-------|
| Protocol | `skills/multi-agent-system/protocol/brief-schemas.md`, `spawn-model-policy.md`, `read-order.md`, `handoff-format.md`, `handoff-format-lite.md`, `subagent-spawn.md`, `token-rules.md` |
| Coordinator / gates | `skills/mas-coordinator/SKILL.md`, `skills/mas-reviewer/SKILL.md`, `skills/mas-lite/SKILL.md`, `skills/mas-ux-intelligence/SKILL.md`, `skills/mas-release-readiness/SKILL.md` |
| P1 skill stubs | `skills/mas-a11y/SKILL.md`, `skills/mas-i18n/SKILL.md`, `skills/mas-compliance/SKILL.md` |
| Install | `skills/multi-agent-system/install/manifest.json` |
| Context dirs | `.ai/context/a11y-reviews/`, `i18n-reviews/`, `compliance/` |
| Architecture / plan | `.ai/context/architecture/MAS-04.md` (Phase B topology, mutual-exclusion matrix), `.ai/context/plans/MAS-04.md` (tasks 21–35) |

**Out of scope (Phase B):** Phase C specialists (observability, migration, chaos-resilience), Gradle unit/UI tests, production app code, `mas-product`, `PARALLEL_READ: YES` parallel spawn.

## Test Surfaces

`integration` (workflow chain, handoff predicates, artifact bus) · `manual` (dogfood `/mas` sessions) · `schema` (brief registry, manifest) · `bundle` (export/manifest)

No unit test pyramid — framework is markdown/skills only.

---

## Synthetic Fixture TASK_IDs

Use these **synthetic** IDs for Phase B dogfood and regression. Do not collide with live workflow `MAS-04` or Phase A fixtures (`MAS-04-FIX-*`).

| Fixture ID | Purpose | Handoff flags / triggers | Expected P1 spawns |
|------------|---------|--------------------------|-------------------|
| `MAS-04-B-FIX-ALL` | Plan task 35 — full Phase B dogfood | `UI_CHANGES: yes`, `A11Y_AUDIT: yes`, `I18N_AUDIT: yes`, `COMPLIANCE_FRAMEWORK: GDPR`; `SCOPE` includes UI + locale strings; `FILES` includes interactive widget stub | ux-intelligence → a11y → i18n → compliance → test-executor |
| `MAS-04-B-FIX-UI-CHAIN` | Sequential UI chain only | `UI_CHANGES: yes`, `A11Y_AUDIT: yes`, `I18N_AUDIT: yes`; no `COMPLIANCE_FRAMEWORK` | ux-intelligence → a11y → i18n (strict order) |
| `MAS-04-B-FIX-A11Y` | Predicate P1-2 only | `A11Y_AUDIT: yes`; `UI_CHANGES: no`; interactive widgets in `FILES` | a11y only (post-dev, no ux-intelligence) |
| `MAS-04-B-FIX-I18N` | Predicate P1-3 only | `I18N_AUDIT: yes` OR `SCOPE` new strings/locale/RTL; no A11Y flag | i18n only |
| `MAS-04-B-FIX-COMP` | Predicate P1-4 only | `COMPLIANCE_FRAMEWORK: SOC2`; no UI/A11Y/I18N flags | compliance only |
| `MAS-04-B-FIX-NONE` | Negative — no P1 spawns | Logic-only protocol edit; no flags; no UI/strings/compliance in `FILES`/`SCOPE` | Zero P1 specialists |
| `MAS-04-B-FIX-RR-A11Y` | release-readiness FAIL routing | `release-readiness` Accessibility FAIL (simulated handoff or prior session); no `A11Y_AUDIT` flag | a11y spawned via P1-2 second clause |
| `MAS-04-B-FIX-RR-I18N` | release-readiness FAIL routing | Localization FAIL | i18n spawned via P1-3 second clause |
| `MAS-04-B-FIX-COMP-SKIP` | Compliance absent | `UI_CHANGES: yes`, `A11Y_AUDIT: yes`; no `COMPLIANCE_FRAMEWORK` | ux-intelligence → a11y; compliance **not** spawned |
| `MAS-04-B-FIX-CAP` | MAX_CHAIN_AGENTS overflow with P1 | Full feature + all P0 flags + Phase B flags; projected count > 12 | Skips per order: test-executor → … → a11y → i18n → compliance; `skipped_specialists` in session JSON |
| `MAS-04-B-FIX-RE` | Idempotency | Re-run `MAS-04-B-FIX-ALL` without `RE_AUDIT: yes` | No duplicate P1 spawn; session `specialists_spawned` blocks re-entry |
| `MAS-04-B-FIX-LITE-L` | Lite L tier P1 abbreviations | `/mas-lite` L tier with `A11Y:y`, `I18N:y`; no compliance (full `/mas` only) | Subset per Lite cap; compliance not available in lite |
| `MAS-04-B-FIX-SCHEMA` | Brief schema gaps | Manually create specialist brief missing required heading | Reviewer `Approved: NO` with schema gap note |
| `MAS-04-B-FIX-BOUNDARY` | ux-intelligence vs a11y/i18n | `UI_CHANGES: yes` + `A11Y_AUDIT: yes` | ux-intelligence friction only in ux-reviews; a11y WCAG table in a11y-reviews; no overlap |
| `MAS-04-B-FIX-EXECUTOR` | test-executor post-P1 chain | `MAS-04-B-FIX-ALL` with `RUN_TESTS: yes` + strategy brief | P1 trio completes before test-executor; executor does not spawn a11y/i18n |

**Fixture artifact paths (expected after successful dogfood for `MAS-04-B-FIX-ALL`):**

- `.ai/context/a11y-reviews/MAS-04-B-FIX-ALL.md`
- `.ai/context/i18n-reviews/MAS-04-B-FIX-ALL.md`
- `.ai/context/compliance/MAS-04-B-FIX-ALL.md`
- `.ai/context/test-runs/MAS-04-B-FIX-ALL.md` (if `RUN_TESTS: yes` or strategy brief exists)
- `.ai/context/test-strategies/MAS-04-B-FIX-ALL.md` (pre-dev, from test-strategy agent)
- `.ai/handoffs/MAS-04-B-FIX-ALL-*.md` per spawned specialist

**Optional fixture inputs (create under `.ai/fixtures/` if general-dev needs seed FILES):**

- `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md` — interactive widget description for P1-2 FILES trigger
- `.ai/fixtures/MAS-04-B-FIX-ALL/strings-stub.json` — string resource stub for P1-3 SCOPE trigger

---

## Chain Permutation Matrix (Phase B — Logic Flow C)

Base mandatory chain segment (post-dev, UI feature):  
`dev → [ux-intelligence?] → [a11y?] → [i18n?] → [compliance?] → [test-executor?] → documenter → reviewer`

| # | Permutation | Triggers | Expected specialist order (P1 segment) | Notes |
|---|-------------|----------|----------------------------------------|-------|
| 1 | Full P1 trio + UX | `UI_CHANGES`, `A11Y_AUDIT`, `I18N_AUDIT`, `COMPLIANCE_FRAMEWORK: GDPR` | ux-intelligence → a11y → i18n → compliance | Plan task 35 acceptance |
| 2 | UX + a11y + i18n (no compliance) | `UI_CHANGES`, `A11Y_AUDIT`, `I18N_AUDIT`; no framework flag | ux-intelligence → a11y → i18n | Compliance skipped when flag absent |
| 3 | a11y only (no UX) | `A11Y_AUDIT: yes`; `UI_CHANGES: no` | a11y (post-dev) | ux-intelligence skipped |
| 4 | i18n only | `I18N_AUDIT: yes`; no A11Y | i18n (post-dev) | No a11y prerequisite when A11Y not triggered |
| 5 | compliance only | `COMPLIANCE_FRAMEWORK: HIPAA` | compliance | No UI chain required |
| 6 | FILES-only a11y | interactive widgets in `FILES`; no `A11Y_AUDIT` flag | a11y | Predicate P1-2 third clause |
| 7 | SCOPE-only i18n | new strings/locale/RTL in `SCOPE`; no `I18N_AUDIT` flag | i18n | Predicate P1-3 second clause |
| 8 | release-readiness Accessibility FAIL | FAIL without `A11Y_AUDIT` flag | a11y | Routes from release-readiness, not re-audit in RR |
| 9 | release-readiness Localization FAIL | FAIL without `I18N_AUDIT` flag | i18n | Same pattern |
| 10 | Cap stress with P1 | Full chain + all P0 + all P1 flags | Overflow skip: a11y before i18n before compliance (per architecture skip order) | Verify user summary + `skipped_specialists` |
| 11 | Lite L + A11Y/I18N | `A11Y:y`, `I18N:y` in lite handoff | Up to tier cap; compliance not in lite | Compliance full `/mas` only |
| 12 | Re-audit | `RE_AUDIT: yes` on second pass | Same P1 specialist may spawn again | Idempotency exception |
| 13 | Phase A + B combined | All P0 flags + Phase B UI chain | P0 early/post-dev slots unchanged; P1 segment after dev per Logic Flow C | Phase A invariants still hold |

**Ordering invariants (P1 — must hold for every permutation):**

1. `ux-intelligence` **before** `a11y` when both `UI_CHANGES: yes` and a11y triggered.
2. `a11y` **before** `i18n` when both triggered (sequential only; no parallel).
3. `compliance` **after** i18n segment when both triggered; may spawn without UI chain when only `COMPLIANCE_FRAMEWORK` set.
4. `compliance` **never** spawns without `COMPLIANCE_FRAMEWORK` set (any value in allowed enum).
5. P1 segment completes **before** `test-executor` when test-executor triggered.
6. Max **one** spawn per P1 slug per TASK_ID unless `RE_AUDIT: yes`.
7. Reviewer remains sole `Approved:` authority; P1 specialists never patch production code.

---

## Predicate Test Cases (P1 trio)

| ID | Predicate | Handoff / context setup | Expected spawn | Expected brief path | Pass criteria |
|----|-----------|-------------------------|----------------|---------------------|---------------|
| P1-1a | `UI_CHANGES: yes` | Existing flag; UI FILES | ux-intelligence | `.ai/context/ux-reviews/{TASK_ID}.md` (if ux skill writes) | Behavioral friction only; no WCAG table |
| P1-2a | `A11Y_AUDIT: yes` | Flag on UI TASK | a11y | `a11y-reviews/{TASK_ID}.md` | WCAG table, Findings, Fix priority, Manual checklist |
| P1-2b | interactive widgets in FILES | `FILES` lists component; no flag | a11y | same | FILES trigger without explicit flag |
| P1-2c | release-readiness Accessibility FAIL | FAIL category in handoff/session | a11y | same | RR routes to a11y; RR does not duplicate WCAG table |
| P1-2d | ux-intelligence boundary | Both UX + A11Y on same TASK | ux-intelligence then a11y | separate brief paths | ux: friction; a11y: WCAG/ARIA/keyboard — no layout redesign in a11y |
| P1-3a | `I18N_AUDIT: yes` | Flag on localization TASK | i18n | `i18n-reviews/{TASK_ID}.md` | String inventory, Locale gaps, RTL, Recommendations |
| P1-3b | strings/locale/RTL in SCOPE | `SCOPE` mentions RTL; no flag | i18n | same | SCOPE trigger |
| P1-3c | release-readiness Localization FAIL | FAIL category | i18n | same | RR routes to i18n |
| P1-3d | sequential after a11y | Both A11Y + I18N flags + UI_CHANGES | a11y → i18n | both brief paths | i18n spawns only after a11y completes |
| P1-4a | `COMPLIANCE_FRAMEWORK: GDPR` | Framework set | compliance | `compliance/{TASK_ID}.md` | Framework map, Gaps, Evidence, Remediation, **Not legal advice** |
| P1-4b | `COMPLIANCE_FRAMEWORK: SOC2` | Alternate enum value | compliance | same | Enum parsing for all allowed values |
| P1-4c | No framework flag | `UI_CHANGES` + A11Y only | compliance **not** spawned | — | Plan task 35 negative case |
| P1-4d | Legal disclaimer | compliance brief written | reviewer reads 0i | — | Not legal sign-off; HITL for remediation |
| P1-4e | compliance vs security-auditor | `COMPLIANCE_FRAMEWORK` + `SECURITY_AUDIT` on auth TASK | both may spawn | separate brief paths | Security = exploitability; compliance = regulatory evidence |

**Spawn model policy (verify in `spawn-model-policy.md` after B0):**

| Slug | Expected `MODEL_CLASS` |
|------|------------------------|
| a11y | normal |
| i18n | normal |
| compliance | thinking |

---

## Mutual Exclusion vs ux-intelligence

| Dimension | ux-intelligence | a11y | i18n | Pass criteria |
|-----------|-----------------|------|------|---------------|
| Purpose | Behavioral friction — journey simulation | WCAG 2.2 AA conformance | Locale/string architecture | Each brief stays in lane |
| Owns | Task completion friction, confusing flows | ARIA, contrast, keyboard, screen-reader | ICU, locale tags, RTL, pluralization, extraction | No WCAG table in ux-reviews |
| Excludes | WCAG depth, layout redesign | Behavioral friction, cosmetic layout | Translation vendor workflow | `mas-ux-intelligence/SKILL.md` boundary note present |
| Chain position | Post-dev when `UI_CHANGES: yes` | After ux-intelligence when both | After a11y when both | Session steps show strict order |
| release-readiness | N/A (not RR category owner) | Accessibility FAIL → a11y | Localization FAIL → i18n | RR does not re-audit WCAG/locale depth |
| Reviewer reads | ux-reviews if exists | a11y-reviews (step 0h) | i18n-reviews (step 0h) | No duplicate friction + WCAG in same finding |

**Fixture `MAS-04-B-FIX-BOUNDARY` verification:**

1. ux-intelligence brief contains friction findings only (no WCAG criterion table).
2. a11y brief contains WCAG table; no behavioral journey narrative.
3. i18n brief contains string/locale audit; no translation vendor workflow.
4. Coordinator does not spawn a11y for friction-only requests without A11Y predicate.
5. `mas-a11y/SKILL.md` documents mutual exclusion vs ux-intelligence.

---

## Tests to Write

| # | Type | Target | Scenario | Rationale | Priority | Flaky risk | Mitigation | Command hint |
|---|------|--------|----------|-----------|----------|------------|------------|--------------|
| 1 | manual | `MAS-04-B-FIX-ALL` dogfood | Run `/mas` with `UI_CHANGES`, `A11Y_AUDIT`, `I18N_AUDIT`, `COMPLIANCE_FRAMEWORK: GDPR`; verify sequential spawn and three brief paths | Plan task 35 acceptance; core Phase B ship gate | P0 | LOW | Single coordinator session; record session JSON | Manual: `/mas` with synthetic handoff per fixture table |
| 2 | integration | `brief-schemas.md` registry | P1 types `a11y-review`, `i18n-review`, `compliance` with correct paths and required sections | Reviewer schema validation depends on registry | P0 | LOW | Bounded `rg` | See **Recommended Commands** §2 |
| 3 | integration | `handoff-format.md` flags | `A11Y_AUDIT`, `I18N_AUDIT`, `COMPLIANCE_FRAMEWORK` documented with enum values | Zero-token routing inputs | P0 | LOW | — | See **Recommended Commands** §3 |
| 4 | integration | `handoff-format-lite.md` | `A11Y:y`, `I18N:y` abbreviations; compliance absent (full `/mas` only) | Lite L tier B3 task 34 | P0 | LOW | — | See **Recommended Commands** §4 |
| 5 | integration | `subagent-spawn.md` | Three P1 slug rows; `run_in_background: false` preserved | Task spawn contract | P0 | LOW | — | See **Recommended Commands** §5 |
| 6 | integration | `read-order.md` | Subscription rows for a11y, i18n, compliance per architecture | Startup read contract | P0 | LOW | — | See **Recommended Commands** §6 |
| 7 | integration | `spawn-model-policy.md` | a11y→normal, i18n→normal, compliance→thinking | Model resolution | P0 | LOW | — | See **Recommended Commands** §7 |
| 8 | integration | Coordinator Logic Flow C | `mas-coordinator/SKILL.md` matches architecture Phase B chain: ux→a11y→i18n→compliance | Deterministic routing | P0 | LOW | Manual compare to architecture mermaid | See **Recommended Commands** §8 |
| 9 | integration | `mas-ux-intelligence/SKILL.md` | Boundary note: WCAG/ARIA→a11y; locale/strings→i18n | Mutual exclusion B2 task 30 | P0 | LOW | — | `rg "a11y|i18n|WCAG" skills/mas-ux-intelligence/SKILL.md` |
| 10 | integration | `mas-release-readiness/SKILL.md` | Accessibility FAIL→a11y; Localization FAIL→i18n routing map | B2 task 31 | P0 | LOW | — | `rg "a11y|i18n" skills/mas-release-readiness/SKILL.md` |
| 11 | integration | `mas-reviewer/SKILL.md` | Conditional read step 0h (a11y/i18n), 0i (compliance) when brief exists | Token cost bound | P0 | LOW | — | `rg "0h|0i|a11y-reviews|compliance" skills/mas-reviewer/SKILL.md` |
| 12 | integration | `manifest.json` v1.2.1 | Version bump; three new skills in `skills` array | Install acceptance B3 task 33 | P0 | LOW | JSON parse | See **Recommended Commands** §1 |
| 13 | manual | Sequential spawn order | `MAS-04-B-FIX-UI-CHAIN`: confirm ux-intelligence before a11y before i18n in session steps | Architecture spawn rule | P0 | LOW | Inspect session JSON step order | Inspect `workflow-sessions/MAS-04-B-FIX-UI-CHAIN.json` |
| 14 | manual | Compliance skip | `MAS-04-B-FIX-COMP-SKIP`: no compliance spawn without framework flag | Plan task 35 negative | P0 | LOW | — | Confirm `compliance` absent from `specialists_spawned` |
| 15 | integration | P1 skill stubs | Each `mas-a11y`, `mas-i18n`, `mas-compliance` SKILL forbids Task spawn, code patch, independent `Approved:` | Specialist invariants | P0 | LOW | — | `rg "Never|never" skills/mas-a11y/SKILL.md` (repeat per stub) |
| 16 | integration | compliance disclaimer | `mas-compliance/SKILL.md` header + brief schema require "not legal advice" | Enterprise/legal risk | P0 | LOW | — | `rg "not legal advice" skills/mas-compliance/SKILL.md` |
| 17 | integration | Context dirs | `.gitkeep` or dirs exist for a11y-reviews, i18n-reviews, compliance | Artifact bus B0 task 25 | P1 | LOW | — | See **Recommended Commands** §9 |
| 18 | integration | `token-rules.md` overflow | P1 skip order: a11y (5) → i18n (6) → compliance (7) after P0 skips | Cap policy | P1 | LOW | — | `rg "a11y|i18n|compliance" skills/multi-agent-system/protocol/token-rules.md` |
| 19 | manual | `MAS-04-B-FIX-NONE` | No P1 flags, no trigger FILES/SCOPE | Negative predicate | P1 | LOW | — | Zero P1 spawns in session |
| 20 | manual | Phase A regression | Re-run `MAS-04-FIX-P0-ALL` after Phase B merge | P0 quartet unchanged | P0 | LOW | — | Phase A dogfood still passes |
| 21 | integration | `mas-lite/SKILL.md` | Phase B abbreviations; compliance full `/mas` only documented | B3 task 34 | P1 | LOW | — | `rg "A11Y|I18N|compliance" skills/mas-lite/SKILL.md` |
| 22 | integration | Brief heading schema | Each P1 brief type required sections present in registry | Schema gap detection | P0 | LOW | Per-brief `rg` | See **Recommended Commands** §10 |

**test-executor boundary (Phase B):** Execute P0 schema/manifest rows (#12, #2–#7, #17) as bounded read-only checks. Manual dogfood rows (#1, #13–#14, #19–#20) are coordinator/reviewer evidence — not test-executor unless strategy brief exists for fixture with `RUN_TESTS: yes`.

---

## Tests to Skip

| # | Target | Reason | Covered by |
|----|--------|--------|------------|
| 1 | Gradle `:app:testDebugUnitTest` | Logic-only framework; no Android modules | Manual dogfood + manifest/protocol verification |
| 2 | Compose/UI/instrumentation tests | `UI_SCOPE: logic-only`; no screens | N/A Phase B |
| 3 | Automated pytest/npm unit suite for skills | No test harness for markdown skills; ROI << manual chain verification | Manual permutation matrix + reviewer schema check |
| 4 | Live WCAG automated scanner (axe, Lighthouse) | Specialists are brief-only; no browser in MAS repo | a11y brief manual checklist section |
| 5 | Translation vendor API calls | i18n does not own vendor workflow per plan | i18n brief recommendations only |
| 6 | Legal/compliance sign-off automation | HITL required; disclaimer-only v1 | compliance brief + reviewer step 0i |
| 7 | `PARALLEL_READ: YES` parallel spawn | Deferred (MAS-01) | Sequential chain matrix only |
| 8 | Phase C specialists (observability, migration, chaos-resilience) | Out of Phase B scope | Phase C dogfood (plan task 48) |
| 9 | Bundled a11y+i18n agent | Option 3 rejected; separate agents per architecture | Mutual exclusion matrix |
| 10 | E2E Cursor IDE automation | No stable CI for Task spawn in IDE | Manual `/mas` dogfood |
| 11 | Export script dry-run | Side-effect to temp dir; not Phase B gate | Manual install QA post-merge |
| 12 | Full 10-specialist roster regression | Phase B ships trio only; full matrix at plan task 51 | Deferred |
| 13 | `mas-product` | Watch list only | N/A |
| 14 | Re-implementing MAS-01 debate/token-auditor | Extend-only per plan | MAS-01 regression separate |
| 15 | ux-intelligence WCAG depth | Explicitly excluded — routes to a11y | Mutual exclusion fixture #9 |

---

## Edge Cases

| Case | Layer | Test approach | Priority |
|------|-------|---------------|----------|
| `UI_CHANGES: yes` but no A11Y/I18N flags | Coordinator | ux-intelligence only; no a11y/i18n | P0 |
| A11Y flag without `UI_CHANGES` | Coordinator | a11y spawns post-dev; ux-intelligence skipped | P0 |
| Both A11Y + I18N; verify a11y before i18n | Session JSON | Step timestamps/order: a11y < i18n | P0 |
| `COMPLIANCE_FRAMEWORK` without UI flags | Coordinator | compliance spawns; no ux/a11y/i18n required | P0 |
| Invalid `COMPLIANCE_FRAMEWORK` value | Coordinator | Coordinator rejects or ignores; no compliance spawn | P1 |
| release-readiness PASS but `A11Y_AUDIT: yes` | Coordinator | a11y runs optional depth (brainstorm edge case) | P1 |
| a11y brief missing WCAG table section | Reviewer | `Approved: NO` + schema gap (`MAS-04-B-FIX-SCHEMA`) | P0 |
| compliance brief missing "Not legal advice" | Reviewer | `Approved: NO` + schema gap | P0 |
| Cap at 13+ with P0 + P1 all triggered | Coordinator | First P1 skip = a11y per architecture skip order | P0 |
| Re-run same TASK_ID | Session JSON | No duplicate P1 spawn without `RE_AUDIT: yes` | P0 |
| Lite handoff with compliance flag | Lite coordinator | Compliance not spawned; full `/mas` only | P0 |
| Phase A chain + Phase B UI chain combined | Coordinator | P0 slots unchanged; P1 segment after dev | P0 |
| a11y reads ux-reviews when exists | a11y skill | read-order subscription; no friction duplication in output | P1 |
| security-auditor + compliance same TASK | Cross-specialist | Both briefs; distinct scope per exclusion matrix | P1 |
| test-executor before a11y completes | Coordinator | Invalid — test-executor after P1 segment | P0 |
| Existing handoff without new P1 flags | Backward compat | Valid; no P1 spawn unless predicates match | P1 |

---

## Regression Risks

**MAS-04** (2026-07-28, feature): Phase A v1.2.0 shipped P0 quartet, routing, manifest 1.2.0. Phase B must not regress P0 predicates, Phase A dogfood (`MAS-04-FIX-P0-ALL`), or MAS-01 routing (`spawn-model-policy`, debate, token-auditor).

**MAS-04-FIX-P0-ALL** (2026-07-28, feature): P0 spawn order validated; re-run after Phase B merge (test #20).

Spot-check: manifest retains all Phase A skills alongside new P1 trio; `test-strategy` before dev and `test-executor` after dev invariants unchanged.

---

## Flaky Test Risks

| Risk | Surface | Mitigation |
|------|---------|------------|
| Manual dogfood session drift | Chain verification | Fixed fixture TASK_IDs; record `workflow-sessions/{FIXTURE}.json` as evidence |
| Sequential spawn race (a11y/i18n) | Coordinator | Foreground spawn only (`run_in_background: false`); wait for Task return before next P1 slot |
| Coordinator table vs architecture drift | Predicate tests | Single source: architecture brief Phase B mermaid; coordinator must mirror on implement |
| Reviewer token/load variance | Conditional reads 0h/0i | Test with brief present vs absent on same TASK_ID pattern |
| Cap projection miscount with P0+P1 | Overflow | Pre-list mandatory agents; P1 skips at positions 5–7 in skip order |
| ux/a11y boundary blur in briefs | Mutual exclusion | Reviewer flags overlap; fixture `MAS-04-B-FIX-BOUNDARY` defines expected separation |
| Compliance enum parsing | Handoff | Document allowed values; invalid value → no spawn |

---

## Recommended Commands

**No Gradle.** Logic-only verification (repo root):

### §1 — Manifest JSON parse (P0, test #12)

```powershell
$m = Get-Content skills/multi-agent-system/install/manifest.json -Raw | ConvertFrom-Json
if ($m.version -ne '1.2.1') { throw "version mismatch: $($m.version)" }
$required = @('mas-a11y','mas-i18n','mas-compliance')
$missing = $required | Where-Object { $m.skills -notcontains $_ }
if ($missing) { throw "missing P1 skills: $($missing -join ', ')" }
# Phase A regression: P0 skills still present
$p0 = @('mas-security-auditor','mas-dependency-risk','mas-api-contract','mas-test-executor')
$p0Missing = $p0 | Where-Object { $m.skills -notcontains $_ }
if ($p0Missing) { throw "Phase A regression — missing P0: $($p0Missing -join ', ')" }
'PASS manifest parse v1.2.1'
```

### §2 — brief-schemas registry (P0, test #2)

```powershell
rg -n "a11y-review|i18n-review|compliance" skills/multi-agent-system/protocol/brief-schemas.md
```

**Pass criteria:** all three type strings appear; paths `a11y-reviews/`, `i18n-reviews/`, `compliance/` referenced.

### §3 — handoff routing flags (P0, test #3)

```powershell
rg -n "A11Y_AUDIT|I18N_AUDIT|COMPLIANCE_FRAMEWORK" skills/multi-agent-system/protocol/handoff-format.md
```

**Pass criteria:** all three flag strings match; `COMPLIANCE_FRAMEWORK` documents enum values (SOC2, GDPR, HIPAA, EU_AI_ACT, FedRAMP).

### §4 — Lite abbreviations (P0, test #4)

```powershell
rg -n "A11Y:y|I18N:y" skills/multi-agent-system/protocol/handoff-format-lite.md
```

**Pass criteria:** both abbreviations present; compliance not in lite format.

### §5 — subagent-spawn slugs (P0, test #5)

```powershell
rg -n "a11y|i18n|compliance" skills/multi-agent-system/protocol/subagent-spawn.md
```

**Pass criteria:** three slug rows; `run_in_background: false` on spawn template.

### §6 — read-order subscriptions (P0, test #6)

```powershell
rg -n "a11y|i18n|compliance" skills/multi-agent-system/protocol/read-order.md
```

### §7 — spawn-model-policy (P0, test #7)

```powershell
rg -n "a11y|i18n|compliance" skills/multi-agent-system/protocol/spawn-model-policy.md
```

**Pass criteria:** a11y→normal, i18n→normal, compliance→thinking.

### §8 — Coordinator Phase B chain (P0, test #8)

```powershell
rg -n "ux-intelligence|a11y|i18n|compliance|UI_CHANGES" skills/mas-coordinator/SKILL.md
```

**Pass criteria:** sequential ux→a11y→i18n documented; compliance after i18n segment when triggered.

### §9 — Context dirs (P1, test #17)

```powershell
@('.ai/context/a11y-reviews','.ai/context/i18n-reviews','.ai/context/compliance') | ForEach-Object {
  if (-not (Test-Path $_)) { throw "missing dir: $_" }
  $_
}
'PASS P1 context dirs'
```

### §10 — P1 brief required headings (P0, test #22)

```powershell
# Registry spot-check — required section names per architecture
$sections = @{
  'a11y-review' = @('WCAG','Findings','Fix priority','Manual checklist')
  'i18n-review' = @('String inventory','Locale gaps','RTL','Recommendations')
  'compliance' = @('Framework map','Gaps','Evidence','Remediation','Not legal advice')
}
rg -n "WCAG table|String inventory|Framework map|Not legal advice" skills/multi-agent-system/protocol/brief-schemas.md
```

### §11 — Session evidence after dogfood

```powershell
Get-Content .ai/context/workflow-sessions/MAS-04-B-FIX-ALL.json -Raw | ConvertFrom-Json |
  Select-Object specialists_spawned, skipped_specialists, steps
```

**Pass criteria for `MAS-04-B-FIX-ALL`:** `specialists_spawned` contains `a11y`, `i18n`, `compliance` in order after `ux-intelligence` (if UI_CHANGES); compliance only when framework flag set.

**Manual (primary P0 gate):**

1. `/mas` synthetic UI feature with handoff matching `MAS-04-B-FIX-ALL` fixture.
2. Confirm spawn order: ux-intelligence → a11y → i18n → compliance → test-executor (if triggered).
3. Confirm three P1 brief files at expected paths with required headings.
4. Confirm compliance brief includes "Not legal advice" section.
5. Confirm no production/skill patches from P1 specialist agents (audit-only).
6. Re-run `MAS-04-FIX-P0-ALL` to verify Phase A regression (test #20).

**test-executor safety constraints (when RUN_TESTS on Phase B fixture):**

- Read-only except writing `.ai/context/test-runs/{FIXTURE}.md`
- No `git`, network, or recursive repo scans
- Execute §1–§10 only; document manual dogfood rows in Gaps if not run

---

## Overall Confidence

**HIGH** — Scope is protocol/skills/manifest only; architecture brief and plan tasks 21–35 define Phase B predicates, sequential UI chain, mutual-exclusion vs ux-intelligence, and compliance opt-in. Fixture matrix and skip rationale are actionable for general-dev and Phase B dogfood (task 35) without Android test infrastructure. Phase A regression path (`MAS-04-FIX-P0-ALL`) is explicit.

---

## Files Reviewed

- `.ai/handoffs/MAS-04-B-test-strategy.md`
- `.ai/context/plans/MAS-04.md` (Phase B tasks 21–35)
- `.ai/context/architecture/MAS-04.md` (Phase B topology, mutual-exclusion matrix)
- `.ai/context/memory.md`
- `.ai/context/daily-changelog.md`
- `.ai/context/test-strategies/MAS-04.md` (Phase A fixture pattern)
- `.ai/context/test-strategies/MAS-04-FIX-P0-ALL.md` (executor command pattern)
- `.ai/context/brainstorms/MAS-04.md` (Logic Flow C, Domain & Contracts)
- `skills/multi-agent-system/install/manifest.json` (pre-Phase B state: v1.2.0)

---

## Open Questions

1. **ux-reviews path** — Confirm whether ux-intelligence writes `.ai/context/ux-reviews/{TASK_ID}.md` or another path; a11y read-order references "ux-reviews if exists."
2. **release-readiness FAIL handoff shape** — Document exact field/session JSON key coordinator uses for Accessibility/Localization FAIL → specialist routing (`MAS-04-B-FIX-RR-*` fixtures).
3. **Invalid `COMPLIANCE_FRAMEWORK` value** — Coordinator reject vs ignore vs user escalation; dogfood should record behavior.
4. **Export script** — If `export-mas-framework.ps1` hardcodes skills vs reads manifest, align during B3; verify three new skill dirs in bundle post-merge.

---

## Usage Report

Model: default
Class: normal
Tokens: unknown

DONE
