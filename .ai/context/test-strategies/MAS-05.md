# Test Strategy — MAS-05

## Feature

MAS-05 (v1.3.0) — Dedicated read-only `mas-figma` extraction specialist with new `design-spec` brief type. Logic-only framework upgrade: protocol extensions, `mas-figma` skill stub, coordinator P0-5 predicate, downstream consumer subscriptions (android-dev, general-dev, reviewer, ux-intelligence, a11y), manifest bump. No Compose screens, no production patches.

## Scope

| Layer | Paths |
|-------|-------|
| Protocol | `skills/multi-agent-system/protocol/brief-schemas.md`, `spawn-model-policy.md`, `read-order.md`, `handoff-format.md`, `handoff-format-lite.md`, `subagent-spawn.md`, `token-rules.md` |
| Coordinator / gates | `skills/mas-coordinator/SKILL.md`, `skills/mas-reviewer/SKILL.md`, `skills/mas-lite/SKILL.md` |
| New specialist | `skills/mas-figma/SKILL.md` |
| Dev consumers | `skills/mas-android-dev/SKILL.md`, `skills/mas-general-dev/SKILL.md` |
| Mutual-exclusion | `skills/mas-ux-intelligence/SKILL.md`, `skills/mas-a11y/SKILL.md` |
| Install | `skills/multi-agent-system/install/manifest.json`, `skills/multi-agent-system/install/export-mas-framework.ps1` |
| Context dirs | `.ai/context/design-specs/` |
| Architecture / plan | `.ai/context/architecture/MAS-05.md`, `.ai/context/plans/MAS-05.md` |
| Dogfood fixtures | `.ai/fixtures/MAS-05-FIGMA-DOGFOOD/` |

**Out of scope:** Gradle/Android unit/UI tests, live Figma MCP in CI, production app code, whole-frame `get_design_context` validation against real frames.

## Test Surfaces

`integration` (workflow chain, handoff predicates, artifact bus) · `manual` (dogfood `/mas` sessions) · `schema` (design-spec brief registry + section headings) · `bundle` (export/manifest)

No unit test pyramid — framework is markdown/skills only.

---

## Synthetic Fixture TASK_IDs

Use these **synthetic** IDs for MAS-05 dogfood and regression. Do not collide with live workflow `MAS-05`.

| Fixture ID | Purpose | Handoff flags / triggers | Expected mas-figma behavior |
|------------|---------|--------------------------|----------------------------|
| `MAS-05-FIGMA-DOGFOOD` | Plan task 18 — primary dogfood | `FIGMA_SPEC: yes`; `SOURCES_HINT` with node-id from `fixtures/MAS-05-FIGMA-DOGFOOD/figma-stub.md`; `SCOPE: ui-from-figma` | Spawn once after architect; brief at `design-specs/MAS-05-FIGMA-DOGFOOD.md`; dev handoff references `BRIEF_PATH` |
| `MAS-05-FIGMA-NONE` | Negative — no figma trigger | Logic-only protocol edit; no Figma flags/URL; `SCOPE` excludes ui-from-figma | Zero mas-figma spawn |
| `MAS-05-FIGMA-FRICTION` | Mutual-exclusion — friction only | Existing UI; `SCOPE: UX friction audit`; incidental Figma URL in FILES **without** implementation intent | Skip mas-figma; route ux-intelligence post-dev |
| `MAS-05-FIGMA-A11Y` | Mutual-exclusion — WCAG only | Existing UI; `A11Y_AUDIT: yes`; incidental Figma URL | Skip mas-figma; route a11y post-dev |
| `MAS-05-FIGMA-NO-NODE` | Degrade — missing node-id | `FIGMA_SPEC: yes`; URL without `node-id` | Blocked brief + Open Questions HITL; never guessed node |
| `MAS-05-FIGMA-REMOTE` | Degrade — remote MCP | Valid node-id; `get_variable_defs` unavailable | Raw token values + `tokens-unresolved (local MCP required)` in Open Questions |
| `MAS-05-FIGMA-RE` | Idempotency | Re-run `MAS-05-FIGMA-DOGFOOD` without `RE_EXTRACT: yes` | No duplicate spawn; session `specialists_spawned` blocks re-entry |
| `MAS-05-FIGMA-RE-EXTRACT` | Re-extract override | Second pass with `RE_EXTRACT: yes` | mas-figma may spawn again |
| `MAS-05-FIGMA-LITE-L` | Lite L tier | `/mas-lite` L with `FIG:y` + stub URL within 12-line handoff | mas-figma within tier cap; inspect-first preserved |
| `MAS-05-FIGMA-LITE-SM` | Lite S/M regression | `/mas-lite` S or M; no `FIG:y` | No mas-figma spawn |
| `MAS-05-FIGMA-CAP` | MAX_CHAIN_AGENTS stress | Full mandatory chain + `FIGMA_SPEC: yes`; projected count > 12 | User escalation (full `/mas`); mas-figma **not** silently dropped — protected-when-triggered |
| `MAS-05-FIGMA-SCHEMA` | Brief schema gaps | Manually create design-spec missing required section | Reviewer `Approved: NO` with schema-gap note |
| `MAS-05-FIGMA-MOCK` | Offline CI fallback | MCP unreachable; use `fixtures/MAS-05-FIGMA-DOGFOOD/design-spec-stub.md` | Mock brief copied with Open Questions noting stub provenance |

**Fixture artifact paths (expected after successful dogfood for `MAS-05-FIGMA-DOGFOOD`):**

- `.ai/context/design-specs/MAS-05-FIGMA-DOGFOOD.md`
- `.ai/handoffs/MAS-05-FIGMA-DOGFOOD-mas-figma.md` (or `MAS-05-FIGMA-DOGFOOD-figma.md` per coordinator naming)
- `.ai/handoffs/MAS-05-FIGMA-DOGFOOD-general-dev.md` (or android-dev) with upstream `BRIEF_PATH` to design-spec
- `.ai/context/workflow-sessions/MAS-05-FIGMA-DOGFOOD.json` with `mas-figma` in `specialists_spawned` / steps

**Fixture inputs (pre-created):**

- `.ai/fixtures/MAS-05-FIGMA-DOGFOOD/figma-stub.md` — Figma URL + node-id + handoff flag templates
- `.ai/fixtures/MAS-05-FIGMA-DOGFOOD/design-spec-stub.md` — minimal valid design-spec for offline schema validation

---

## Chain Permutation Matrix

Base mandatory chain (full `/mas` UI-from-Figma feature):  
`coordinator → osint → brainstorm → planner → architect → [mas-figma if P0-5] → general-dev|android-dev → [ux-intelligence → a11y → i18n per MAS-04 P1] → documenter → reviewer → [debate?] → [commit?]`

| # | Permutation | Triggers | Expected specialist order (mas-figma focus) | Notes |
|---|-------------|----------|---------------------------------------------|-------|
| 1 | Full UI-from-Figma | `FIGMA_SPEC: yes` OR node-id URL OR `SCOPE: ui-from-figma` | architect → **mas-figma** → general-dev → … → reviewer | Plan task 18 acceptance |
| 2 | FILES-only trigger | Figma URL + node-id in `FILES`; no `FIGMA_SPEC` flag | architect → mas-figma → dev | Predicate second clause |
| 3 | SCOPE-only trigger | `SCOPE: ui-from-figma`; no explicit flag | architect → mas-figma → dev | Predicate third clause |
| 4 | No trigger | `MAS-05-FIGMA-NONE` | architect → dev (skip mas-figma) | Negative control |
| 5 | Friction-only suppression | Existing UI + friction scope; incidental URL | architect → dev → ux-intelligence (no mas-figma) | Suppression rule |
| 6 | WCAG-only suppression | Existing UI + `A11Y_AUDIT`; incidental URL | architect → dev → a11y (no mas-figma) | Suppression rule |
| 7 | Post-dev audits after figma | Permutation 1 + UX/A11Y predicates | mas-figma (pre-dev) → dev → ux-intelligence → a11y | D9 ordering |
| 8 | Lite L + FIG:y | Lite L tier, abbreviated flag | mas-figma within cap | `FIG:y` in lite handoff |
| 9 | Lite S/M | No `FIG:y` | No mas-figma | Unchanged Lite behavior |
| 10 | Cap stress | Permutation 1 + max optional agents | User escalation if mandatory + mas-figma > 12; no silent skip | D8 protected-when-triggered |
| 11 | Re-extract | `RE_EXTRACT: yes` on second pass | mas-figma may spawn again | Idempotency exception |
| 12 | No node-id degrade | URL without node-id | mas-figma spawns → Blocked brief | HITL; never guess |
| 13 | Remote MCP degrade | Valid node-id; no variable defs | mas-figma → brief with tokens-unresolved flag | Continue node map + screenshot |
| 14 | Architect before figma | Greenfield UI | mas-figma never before architect | D3 ordering |
| 15 | Dev after figma | Any P0-5 trigger | dev never before mas-figma when triggered | Chain invariant |

**Ordering invariants (P0 — must hold for every permutation):**

1. `mas-figma` always **after** architect/planner; **before** android-dev/general-dev when triggered.
2. `mas-figma` **never** on same hop as ux-intelligence or a11y (different chain phase).
3. Max **one** mas-figma spawn per `TASK_ID` unless `RE_EXTRACT: yes`.
4. Architect brief does **not** duplicate design-spec sections (Node Map, Tokens, Layout).
5. Dev does **not** call Figma MCP when `design-specs/{TASK_ID}.md` exists.
6. Reviewer remains sole `Approved:` authority; mas-figma never patches production code.
7. Whole-frame `get_design_context` forbidden; Node Map from `get_metadata` is backbone.
8. Full `/mas`: mas-figma protected-when-triggered — not in token-rules auto-skip list.

---

## Predicate Test Cases (P0-5 mas-figma)

| ID | Predicate | Handoff / context setup | Expected spawn | Expected brief path | Pass criteria |
|----|-----------|-------------------------|----------------|---------------------|---------------|
| P0-5a | `FIGMA_SPEC: yes` | Flag only; stub URL in SOURCES_HINT | mas-figma | `design-specs/{TASK_ID}.md` | All seven required sections present |
| P0-5b | node-id in SOURCES_HINT | URL with `node-id=1-42`; no flag | mas-figma | same | Predicate fires without explicit flag |
| P0-5c | node-id in FILES | Figma URL in FILES | mas-figma | same | FILES trigger |
| P0-5d | `SCOPE: ui-from-figma` | Scope string only | mas-figma | same | SCOPE trigger |
| P0-5e | No node-id | URL without node-id | mas-figma → Blocked | same with Open Questions | HITL note; no invented coordinates |
| P0-5f | MCP unreachable | Network/MCP down | mas-figma → Blocked OR mock stub | Open Questions / mock path | No fabricated layout |
| P0-5g | Remote-only MCP | No `get_variable_defs` | mas-figma | same | `tokens-unresolved (local MCP required)` flag |
| P0-5h | No Code Connect | Repo-scan fallback | mas-figma | Reuse Table rows `repo-scan (unverified)` | D2 degrade |
| P0-5i | `FIGMA_COMPLEXITY: high` | Complexity flag on handoff | mas-figma with `MODEL_CLASS: thinking` | same | spawn-model-policy row |
| P0-5j | Lite `FIG:y` | Lite L handoff | mas-figma within tier | same | Lite compatibility |
| P0-5k | Suppression friction | Friction-only on existing UI | **No** mas-figma | — | ux-intelligence only |
| P0-5l | Suppression WCAG | WCAG-only on existing UI | **No** mas-figma | — | a11y only |
| P0-5m | Idempotency | Re-run without `RE_EXTRACT` | **No** second spawn | — | session JSON blocks |
| P0-5n | `RE_EXTRACT: yes` | Second intentional pass | mas-figma re-spawn | updated brief | Allowed override |

**Spawn model policy (verify after implement):**

| Slug | Expected `MODEL_CLASS` |
|------|------------------------|
| mas-figma | normal (default); thinking on `FIGMA_COMPLEXITY: high` |

---

## Mutual-Exclusion Regression Checklist

Record pass/fail in reviewer output or `.ai/context/test-runs/MAS-05-FIGMA-DOGFOOD.md` after dogfood.

| # | Case | Fixture | Expected | Pass criteria |
|---|------|---------|----------|---------------|
| ME-1 | UI-from-Figma triggers mas-figma, not ux-intelligence | `MAS-05-FIGMA-DOGFOOD` | mas-figma pre-dev; ux-intelligence only if post-dev predicate fires | Session steps show mas-figma before dev; ux-intelligence after dev if triggered |
| ME-2 | Friction-only on existing UI skips mas-figma | `MAS-05-FIGMA-FRICTION` | No mas-figma spawn | ux-intelligence routed; incidental URL ignored |
| ME-3 | WCAG-only on existing UI skips mas-figma | `MAS-05-FIGMA-A11Y` | No mas-figma spawn | a11y routed; incidental URL ignored |
| ME-4 | Architect brief does not duplicate design-spec sections | `MAS-05` architecture brief | No Node Map / Design Tokens / Layout Spec tables in architecture | `rg` on `architecture/MAS-05.md` — sections describe contracts only, not duplicate stub data |
| ME-5 | Dev does not call Figma MCP when design-spec exists | `MAS-05-FIGMA-DOGFOOD` dev handoff | Dev reads `design-specs/{TASK_ID}.md` at startup | general-dev/android-dev SKILL + read-order; no MCP in dev skill when brief present |
| ME-6 | Max one mas-figma spawn per TASK_ID | `MAS-05-FIGMA-RE` | Second run blocked | `specialists_spawned` contains mas-figma once |
| ME-7 | No node-id → Blocked brief + HITL | `MAS-05-FIGMA-NO-NODE` | Never guessed node | Open Questions documents missing node-id |
| ME-8 | mas-figma vs architect boundary | `MAS-05` | mas-figma extracts visual contract only | architect scopes nodes; mas-figma does not design architecture |
| ME-9 | mas-figma vs reviewer boundary | Any dogfood | mas-figma has no `Approved:` | Reviewer sole gate; mas-figma findings are spec input |
| ME-10 | ux-intelligence / a11y cross-ref | Skill stubs | One-line mutual-exclusion vs mas-figma | `rg "mas-figma" skills/mas-ux-intelligence/SKILL.md` and `mas-a11y/SKILL.md` |
| ME-11 | Reference-not-final | design-spec brief | Layout Spec marked reference | Dev SKILL states extracted code is not final |
| ME-12 | No production patches from mas-figma | Dogfood session | Zero git diff from specialist on prod paths | Audit-only invariant |

---

## Design-Spec Schema Validation (Fixture-Based)

Validate synthetic / stub briefs against `brief-schemas.md` **design-spec** registry before and after dogfood.

### Required sections (all must be present)

| Section | Validation command / check | Stub coverage |
|---------|---------------------------|---------------|
| Node Map | `rg "^## Node Map" .ai/fixtures/MAS-05-FIGMA-DOGFOOD/design-spec-stub.md` | Table with node-id, name, type, x, y, width, height, parent-id |
| Design Tokens | `rg "^## Design Tokens" ...` | Token name, category, raw value, MaterialTheme ref |
| Layout Spec | `rg "^## Layout Spec" ...` | Per-node blocks; **reference — not final code** marker |
| Component Reuse Table | `rg "^## Component Reuse Table" ...` | source column (code-connect \| repo-scan) |
| Asset Manifest | `rg "^## Asset Manifest" ...` | expiry flag column when URLs present |
| Screenshot Reference | `rg "^## Screenshot Reference" ...` | path + node-id |
| Open Questions | `rg "^## Open Questions" ...` | ambiguities / stub / degrade flags |

### Schema gap scenarios (reviewer)

| Scenario | Setup | Expected reviewer outcome |
|----------|-------|----------------------------|
| Missing Node Map | Delete `## Node Map` from stub copy | `Approved: NO` — schema gap |
| Missing Screenshot Reference | Omit section | `Approved: NO` |
| Monolithic Layout Spec | Single whole-frame dump without per-node breakdown | Flag as inspect-first violation |
| Fabricated tokens | Token names with no MCP/Open Questions note on remote degrade | Reviewer notes fidelity risk |
| Valid stub | `design-spec-stub.md` copied to `design-specs/MAS-05-FIGMA-DOGFOOD.md` | Schema pass (advisory on stub provenance) |

### Fixture-based validation commands

```powershell
$stub = '.ai/fixtures/MAS-05-FIGMA-DOGFOOD/design-spec-stub.md'
$sections = @('Node Map','Design Tokens','Layout Spec','Component Reuse Table','Asset Manifest','Screenshot Reference','Open Questions')
foreach ($s in $sections) {
  if (-not (Select-String -Path $stub -Pattern "^## $s" -Quiet)) { throw "missing section: $s" }
}
'PASS design-spec stub schema'
```

---

## Tests to Write

| # | Type | Target | Scenario | Rationale | Priority | Flaky risk | Mitigation | Command hint |
|---|------|--------|----------|-----------|----------|------------|------------|--------------|
| 1 | manual | `MAS-05-FIGMA-DOGFOOD` dogfood | Run full `/mas` with `FIGMA_SPEC: yes` + stub SOURCES_HINT; verify chain order and design-spec path | Plan task 18 acceptance; primary ship gate | P0 | LOW | Single coordinator session; record session JSON | Manual: `/mas` per fixture table |
| 2 | integration | `brief-schemas.md` registry | `design-spec` type row with seven required sections | Reviewer schema validation | P0 | LOW | Read registry only | `rg "design-spec" skills/multi-agent-system/protocol/brief-schemas.md` |
| 3 | integration | `handoff-format.md` flags | `FIGMA_SPEC`, `SOURCES_HINT`, `RE_EXTRACT`, `FIGMA_COMPLEXITY` documented | Zero-token routing | P0 | LOW | — | `rg "FIGMA_SPEC|SOURCES_HINT|RE_EXTRACT|FIGMA_COMPLEXITY" skills/multi-agent-system/protocol/handoff-format.md` |
| 4 | integration | Lite `FIG:y` | `handoff-format-lite.md` documents abbreviated flag | Lite L dogfood | P1 | LOW | — | `rg "FIG:y" skills/multi-agent-system/protocol/handoff-format-lite.md` |
| 5 | integration | `subagent-spawn.md` | `mas-figma` slug row; `run_in_background: false` | Task spawn contract | P0 | LOW | — | `rg "mas-figma" skills/multi-agent-system/protocol/subagent-spawn.md` |
| 6 | integration | `read-order.md` | mas-figma subscription + dev design-spec conditional read | Startup read contract | P0 | LOW | — | `rg "mas-figma|design-specs" skills/multi-agent-system/protocol/read-order.md` |
| 7 | integration | Coordinator P0-5 predicate | `mas-coordinator/SKILL.md` matches architecture predicate table | Deterministic routing | P0 | LOW | — | Compare to `.ai/context/architecture/MAS-05.md` |
| 8 | integration | Protected-when-triggered | `token-rules.md` notes mas-figma not auto-skipped in full `/mas` | D8 cap policy | P0 | LOW | — | `rg "mas-figma" skills/multi-agent-system/protocol/token-rules.md` |
| 9 | integration | Session JSON idempotency | `specialists_spawned` + `RE_EXTRACT` behavior | Idempotency audit | P0 | LOW | — | Inspect `workflow-sessions/MAS-05-FIGMA-DOGFOOD.json` |
| 10 | integration | `manifest.json` v1.3.0 | Version bump; `mas-figma` in skills array | Install acceptance | P0 | LOW | — | `Get-Content skills/multi-agent-system/install/manifest.json \| ConvertFrom-Json` |
| 11 | integration | Export bundle | Dry-run includes `skills/mas-figma/` | Bundle integrity | P1 | LOW | Temp output dir | `export-mas-framework.ps1 -OutputDir $env:TEMP\mas-export-mas05` |
| 12 | schema | Fixture stub schema | `design-spec-stub.md` passes seven-section check | Offline validation baseline | P0 | LOW | — | See **Design-Spec Schema Validation** commands |
| 13 | manual | Mutual-exclusion checklist | Run ME-1 through ME-12 | Plan task 19 | P0 | LOW | — | Record in test-run or reviewer brief |
| 14 | integration | `mas-figma/SKILL.md` invariants | Forbids Task spawn, code patch, `Approved:`, whole-frame context | Specialist contract | P0 | LOW | — | `rg "Never|never|whole-frame" skills/mas-figma/SKILL.md` |
| 15 | manual | `MAS-05-FIGMA-NONE` | No flags, no trigger URL/SCOPE | Negative predicate | P1 | LOW | — | Zero mas-figma in session |
| 16 | integration | Context dir | `.ai/context/design-specs/` exists | Artifact bus | P1 | LOW | — | `Test-Path .ai/context/design-specs` |
| 17 | integration | Dev consumer skills | android-dev/general-dev subscribe to design-spec | Dev startup contract | P0 | LOW | — | `rg "design-spec" skills/mas-general-dev/SKILL.md` |
| 18 | integration | Reviewer conditional read | Reviewer verifies design-spec sections when present | Gate preservation | P0 | LOW | — | `rg "design-spec" skills/mas-reviewer/SKILL.md` |
| 19 | manual | Degrade no node-id | `MAS-05-FIGMA-NO-NODE` | Blocked brief path | P0 | LOW | — | Open Questions HITL |
| 20 | manual | Offline mock fallback | Copy stub to design-specs when MCP down | CI-friendly path | P1 | LOW | — | `MAS-05-FIGMA-MOCK` fixture |

---

## Tests to Skip

| # | Target | Reason | Covered by |
|----|--------|--------|------------|
| 1 | Gradle `:app:testDebugUnitTest` | Logic-only framework; no Android modules | Manual dogfood + manifest verification |
| 2 | Compose/UI/instrumentation tests | `UI_SCOPE: logic-only`; no screens | N/A MAS-05 |
| 3 | Automated pytest/npm unit suite for skills | No test harness for markdown skills | Manual permutation matrix + schema checks |
| 4 | Live Figma MCP in CI | Network + auth dependency; flaky | Fixture stub + optional manual MCP dogfood |
| 5 | Whole-frame `get_design_context` on real frames | Context blow-up; skill forbids | Skill invariant review + reviewer flag |
| 6 | Pixel-perfect screenshot diff | No Compose output in MAS-05 | Deferred to future UI workflow |
| 7 | Code Connect live verification | External Figma project config | Repo-scan fallback path in stub |
| 8 | E2E Cursor IDE automation | No stable CI for Task spawn | Manual `/mas` dogfood |
| 9 | MAS-04 P0 quartet regression | Separate fixtures (`MAS-04-FIX-P0-ALL`) | Spot-check manifest still lists Phase A skills |
| 10 | Relay plugin integration | Relay model only; no plugin adoption | Architecture D2/D10 |

---

## Edge Cases

| Case | Layer | Test approach | Priority |
|------|-------|---------------|----------|
| All three triggers simultaneously | Coordinator | `FIGMA_SPEC` + URL + `SCOPE: ui-from-figma` → single mas-figma spawn | P0 |
| URL trigger without node-id | mas-figma | Blocked brief; coordinator still routes to mas-figma | P0 |
| MCP unreachable mid-pipeline | mas-figma | Blocked brief or mock stub path; no invented layout | P0 |
| Remote-only MCP | mas-figma | tokens-unresolved flag; node map + screenshot continue | P0 |
| No Code Connect | mas-figma | Reuse rows `repo-scan (unverified)` | P1 |
| Expired asset URL (~7 days) | design-spec | Asset Manifest expiry flag; dev download-and-commit instruction | P1 |
| Multi-screen frame | mas-figma | `get_metadata` sweep; per-child `get_design_context` only | P0 |
| `FIGMA_COMPLEXITY: high` | Coordinator | `MODEL_CLASS: thinking` on mas-figma handoff | P1 |
| Cap at exactly 12 with mas-figma | Coordinator | No silent skip of mas-figma when triggered | P0 |
| Cap at 13+ mandatory + mas-figma | Coordinator | User escalation per D8 | P0 |
| Re-run same TASK_ID | Session JSON | No duplicate without `RE_EXTRACT: yes` | P0 |
| design-spec missing section | Reviewer | `Approved: NO` schema gap | P0 |
| Dev handoff without design-spec when triggered | Chain | Fail — mas-figma should have run | P0 |
| Lite handoff >12 lines | Lite coordinator | `FIG:y` within cap | P1 |
| Backward-compat handoff without new flags | Coordinator | Valid; no mas-figma unless predicates match | P1 |
| Architect duplicates Node Map | Architecture brief | Reviewer/test-strategy flags duplication | P1 |
| mas-figma patches skills/protocol | Specialist | Forbidden — general-dev owns edits | P0 |

---

## Regression Risks

N/A — `.ai/context/daily-changelog.md` has no same-day task entries (empty log for 2026-08-05).

**Cross-workflow:** **MAS-04** Phase A/B routing (P0 quartet, ux→a11y→i18n chain) must not regress when extending protocol tables — spot-check manifest lists pre-MAS-05 skills alongside `mas-figma`. **MAS-01** coordinator init, debate, token-auditor unchanged.

---

## Flaky Test Risks

| Risk | Surface | Mitigation |
|------|---------|------------|
| Live Figma MCP availability | Dogfood | Primary path uses fixtures; live MCP optional; mock stub fallback |
| Manual dogfood session drift | Chain verification | Fixed fixture TASK_IDs; `workflow-sessions/{FIXTURE}.json` evidence |
| Export script path variance | Bundle test | `-OutputDir $env:TEMP\mas-export-mas05` |
| Coordinator table vs architecture drift | Predicate tests | Architecture brief is source; coordinator mirrors on implement |
| Asset URL expiry | design-spec / dev | Expiry flag in manifest; not gated on live URL |
| Screenshot file missing in stub | Schema validation | Screenshot Reference section with path note acceptable without image file |
| `rg` vs `Select-String` on Windows | Protocol checks | Use `rg` when available; bounded single-file patterns |

---

## Recommended Commands

**No Gradle.** Logic-only verification:

```powershell
# Manifest version and mas-figma registration
$m = Get-Content skills/multi-agent-system/install/manifest.json -Raw | ConvertFrom-Json
if ($m.version -ne '1.3.0') { throw "version mismatch: $($m.version)" }
if ($m.skills -notcontains 'mas-figma') { throw 'mas-figma missing from skills array' }
'PASS manifest parse'

# Protocol registry
rg "design-spec" skills/multi-agent-system/protocol/brief-schemas.md
rg "FIGMA_SPEC|SOURCES_HINT|RE_EXTRACT|FIGMA_COMPLEXITY" skills/multi-agent-system/protocol/handoff-format.md
rg "FIG:y" skills/multi-agent-system/protocol/handoff-format-lite.md
rg "mas-figma" skills/multi-agent-system/protocol/subagent-spawn.md
rg "mas-figma|design-spec" skills/multi-agent-system/protocol/read-order.md
rg "mas-figma" skills/multi-agent-system/protocol/token-rules.md
rg "mas-figma" skills/multi-agent-system/protocol/spawn-model-policy.md

# Context dir
Test-Path .ai/context/design-specs

# Design-spec stub schema (fixture-based)
$stub = '.ai/fixtures/MAS-05-FIGMA-DOGFOOD/design-spec-stub.md'
$sections = @('Node Map','Design Tokens','Layout Spec','Component Reuse Table','Asset Manifest','Screenshot Reference','Open Questions')
foreach ($s in $sections) {
  if (-not (Select-String -Path $stub -Pattern "^## $s" -Quiet)) { throw "missing section: $s" }
}
'PASS design-spec stub schema'

# Mutual-exclusion cross-refs
rg "mas-figma" skills/mas-ux-intelligence/SKILL.md
rg "mas-figma" skills/mas-a11y/SKILL.md
rg "design-spec" skills/mas-general-dev/SKILL.md
rg "design-spec" skills/mas-reviewer/SKILL.md

# Export dry-run
powershell -File skills/multi-agent-system/install/export-mas-framework.ps1 -OutputDir "$env:TEMP\mas-export-mas05"
Test-Path "$env:TEMP\mas-export-mas05/skills/mas-figma/SKILL.md"

# Session evidence after dogfood
Get-Content .ai/context/workflow-sessions/MAS-05-FIGMA-DOGFOOD.json | ConvertFrom-Json | Select-Object specialists_spawned, steps
```

**Manual (primary P0 gate — dogfood):**

1. `/mas` synthetic feature with handoff matching `MAS-05-FIGMA-DOGFOOD` fixture (`figma-stub.md`).
2. Confirm spawn order: architect → mas-figma → general-dev (per chain matrix row #1).
3. Confirm `design-specs/MAS-05-FIGMA-DOGFOOD.md` exists with seven required sections (live MCP or stub copy).
4. Confirm dev handoff references design-spec `BRIEF_PATH`.
5. Run mutual-exclusion checklist ME-1–ME-12; record pass/fail.
6. Confirm no production/skill patches from mas-figma specialist (audit-only).
7. Reviewer validates schema; `Approved` flow unchanged.

**Offline CI path:** Copy `design-spec-stub.md` to `design-specs/MAS-05-FIGMA-DOGFOOD.md`; run schema validation commands; skip live MCP dogfood.

---

## Overall Confidence

**HIGH** — Scope is protocol/skills/manifest only; architecture brief and plan define P0-5 predicate, cap policy, mutual-exclusion, and design-spec schema. Fixture TASK_IDs, chain permutation matrix, degrade paths, and fixture-based schema validation are actionable for general-dev and dogfood without Android test infrastructure.

---

## Files Reviewed

- `.ai/handoffs/MAS-05-test-strategy.md`
- `.ai/context/plans/MAS-05.md` (Phases 0–5)
- `.ai/context/architecture/MAS-05.md`
- `.ai/context/memory.md`
- `.ai/context/daily-changelog.md`
- `skills/multi-agent-system/references/test-strategy-standards.md` (via skill)
- `.ai/context/test-strategies/MAS-04.md` (format reference)

---

## Open Questions

1. **Dogfood TASK_ID naming** — Coordinator handoff suffix for mas-figma (`MAS-05-FIGMA-DOGFOOD-mas-figma.md` vs `-figma.md`); record actual pattern during dogfood.
2. **Mock brief merge approval** — Stub copy path is schema-valid but not live extraction; reviewer should flag stub provenance in Open Questions before `Approved: YES`.
3. **Export skill list** — Verify `export-mas-framework.ps1` reads `manifest.json` vs hardcoded list during general-dev implement.

---

## Usage Report

Model: default
Class: normal
Tokens: unknown

DONE
