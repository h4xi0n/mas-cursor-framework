# Test Strategy — MAS-06

## Feature

MAS-06 (v1.4.0) — Post-dev **`mas-visual-fidelity`** read-only specialist with new **`visual-qa`** brief type, **Verification Contract** slice on `design-spec`, coordinator **P0-6** predicate, reviewer step **0k Design-Fidelity Verification**, and **`build-test-visual-qa.md`** artifact-backed gate. Logic-only framework upgrade: protocol extensions, skill stub, coordinator routing, downstream consumer subscriptions. No Compose screens, no production patches in MAS repo.

## Scope

| Layer | Paths |
|-------|-------|
| Protocol | `skills/multi-agent-system/protocol/brief-schemas.md`, `spawn-model-policy.md`, `read-order.md`, `handoff-format.md`, `handoff-format-lite.md`, `subagent-spawn.md`, `token-rules.md` |
| References | `skills/multi-agent-system/references/visual-fidelity-standards.md` (new), `figma-extraction-standards.md`, `build-test-visual-qa.md` |
| Coordinator / gates | `skills/mas-coordinator/SKILL.md`, `skills/mas-reviewer/SKILL.md`, `skills/mas-lite/SKILL.md` |
| New specialist | `skills/mas-visual-fidelity/SKILL.md` |
| Pre-dev consumer | `skills/mas-figma/SKILL.md` (Verification Contract §8) |
| Dev consumers | `skills/mas-android-dev/SKILL.md`, `skills/mas-general-dev/SKILL.md` |
| Post-dev consumers | `skills/mas-ux-intelligence/SKILL.md`, `skills/mas-a11y/SKILL.md`, `skills/mas-test-strategy/SKILL.md`, `skills/mas-test-executor/SKILL.md` |
| Install | `skills/multi-agent-system/install/manifest.json`, `skills/multi-agent-system/SKILL.md` |
| Context dirs | `.ai/context/visual-qa/`, `.ai/context/design-specs/` (Verification Contract slice) |
| Architecture / plan | `.ai/context/architecture/MAS-06.md`, `.ai/context/plans/MAS-06.md` |
| Dogfood fixtures | `.ai/fixtures/MAS-06-VFID-DOGFOOD/` |

**Out of scope:** Gradle/Android unit/UI tests in MAS framework repo, live Figma MCP in CI, live Paparazzi runs in MAS repo, production app code, commercial visual AI SDK integration.

## Test Surfaces

`integration` (workflow chain, P0-6 predicate, artifact bus) · `manual` (dogfood `/mas` sessions) · `schema` (visual-qa brief + Verification Contract headings) · `bundle` (export/manifest)

No unit test pyramid — framework is markdown/skills only. **Visual capture commands** documented as contract shapes for target Android projects only.

---

## Synthetic Fixture TASK_IDs

Use these **synthetic** IDs for MAS-06 dogfood and regression. Do not collide with live workflow `MAS-06`.

| Fixture ID | Purpose | Handoff flags / triggers | Expected mas-visual-fidelity behavior |
|------------|---------|--------------------------|--------------------------------------|
| `MAS-06-VFID-DOGFOOD` | Plan task 27 — primary dogfood | Pre-dev design-spec exists; dev `UI_CHANGES: YES`; `VISUAL_FIDELITY: auto` | Spawn once after dev; brief at `visual-qa/MAS-06-VFID-DOGFOOD.md`; chain before ux-intelligence |
| `MAS-06-VFID-NONE` | Negative — logic-only dev | design-spec exists; dev `UI_CHANGES: NO` | Zero mas-visual-fidelity spawn; reviewer 0k N/A |
| `MAS-06-VFID-NO-SPEC` | Negative — no design-spec | `UI_CHANGES: YES`; no `design-specs/{TASK_ID}.md` | Zero spawn; predicate fails |
| `MAS-06-VFID-EXPLICIT` | Force trigger | `VISUAL_FIDELITY: yes` + design-spec + UI changes | Spawn regardless of auto inference edge cases |
| `MAS-06-VFID-P0-BLOCK` | Iteration loop | visual-qa with P0 `blocker` row (color mismatch) | Coordinator → dev fix → `RE_VERIFY: yes` → re-spawn (≤ 2) |
| `MAS-06-VFID-ITER-CAP` | Iteration cap | Two failed fidelity passes | User escalation with P0 table attached |
| `MAS-06-VFID-MCP-BLOCK` | Baseline degrade | MCP unreachable; PNG age ≤ 7d + `BASELINE_STALE: no` | BLOCKED baseline note; P0 from metrics when extractable |
| `MAS-06-VFID-NO-CAPTURE` | Capture infra missing | No Paparazzi/Preview in target | BLOCKED Implementation Capture; reviewer 0k FAIL |
| `MAS-06-VFID-RE` | Idempotency | Re-run without `RE_VERIFY: yes` | No duplicate spawn; session blocks re-entry |
| `MAS-06-VFID-RE-VERIFY` | Re-verify override | Second pass with `RE_VERIFY: yes` | mas-visual-fidelity may spawn again |
| `MAS-06-VFID-LITE` | Lite skip | `/mas-lite` without `VFID:y`; design-spec exists | No spawn; coordinator warns "Figma fidelity unverified" |
| `MAS-06-VFID-LITE-L` | Lite explicit | `/mas-lite` L/L+ with `VFID:y` within cap | mas-visual-fidelity within tier cap |
| `MAS-06-VFID-CAP` | MAX_CHAIN_AGENTS stress | Full chain + mas-figma + mas-visual-fidelity; count > 12 | User escalation; neither protected specialist silently dropped |
| `MAS-06-VFID-OPTION6` | Option 6 fallback | User accepts cap relief per D12 | test-executor visual section; session `visual_fidelity_fallback: test-executor` |
| `MAS-06-VFID-MULTI` | Multi-screen (D6) | design-spec with > 3 screen states | `MODEL_CLASS: thinking`; sectioned single visual-qa brief |
| `MAS-06-VFID-SCHEMA` | Brief schema gaps | visual-qa missing required section | Reviewer 0k FAIL / `Approved: NO` |
| `MAS-06-VFID-P1-PARTIAL` | P1 degrade | Screenshot compare PARTIAL | Reviewer 0k PASS with Major note on regions |
| `MAS-06-VFID-IMMUTABLE` | Extraction immutability | Fidelity run after mas-figma | design-spec extraction sections unchanged; parity only in visual-qa |
| `MAS-06-VFID-RE-EXTRACT` | mas-figma re-extract | `RE_EXTRACT: yes` on mas-figma | Verification Contract overwritten; visual-qa untouched |

**Fixture artifact paths (expected after successful dogfood for `MAS-06-VFID-DOGFOOD`):**

- `.ai/context/design-specs/MAS-06-VFID-DOGFOOD.md` (pre-dev; includes Verification Contract)
- `.ai/context/visual-qa/MAS-06-VFID-DOGFOOD.md` (post-dev)
- `.ai/handoffs/MAS-06-VFID-DOGFOOD-mas-visual-fidelity.md` (or coordinator naming variant)
- `.ai/handoffs/MAS-06-VFID-DOGFOOD-general-dev.md` with `UI_CHANGES: YES` and capture paths in `FILES`
- `.ai/context/workflow-sessions/MAS-06-VFID-DOGFOOD.json` with `visual_fidelity_spawned: true`, `specialists_spawned` includes `mas-visual-fidelity`

**Fixture inputs (pre-created):**

- `.ai/fixtures/MAS-06-VFID-DOGFOOD/design-spec-stub.md` — design-spec + Verification Contract for offline validation
- `.ai/fixtures/MAS-06-VFID-DOGFOOD/visual-qa-expected-shape.md` — expected visual-qa schema shape
- `.ai/fixtures/MAS-06-VFID-DOGFOOD/handoff-stub.md` — dev/coordinator flag templates + capture command fixtures

---

## Chain Permutation Matrix

Base mandatory chain (full `/mas` UI-from-Figma feature with MAS-05 + MAS-06):  
`coordinator → osint → brainstorm → planner → architect → [mas-figma if P0-5] → general-dev|android-dev → [mas-visual-fidelity if P0-6] → [ux-intelligence → a11y → i18n per MAS-04 P1] → [test-executor] → documenter → reviewer`

| # | Permutation | Triggers | Expected specialist order (visual-fidelity focus) | Notes |
|---|-------------|----------|---------------------------------------------------|-------|
| 1 | Full UI-from-Figma + fidelity | design-spec + dev `UI_CHANGES: YES` | dev → **mas-visual-fidelity** → ux-intelligence → … → reviewer | Plan task 27 acceptance |
| 2 | Explicit `VISUAL_FIDELITY: yes` | Flag + design-spec | dev → mas-visual-fidelity | Force spawn |
| 3 | Auto predicate only | `VISUAL_FIDELITY: auto` + design-spec + `UI_CHANGES: YES` | dev → mas-visual-fidelity | P0-6 default |
| 4 | FILES inference | Composables/resources in FILES without explicit flag | dev → mas-visual-fidelity | Coordinator inference per D11 |
| 5 | Suppression — no UI changes | design-spec + `UI_CHANGES: NO` | dev → ux-intelligence (skip fidelity) | Negative control |
| 6 | Suppression — no design-spec | `UI_CHANGES: YES`; no design-spec | dev → ux (no fidelity) | Predicate fails |
| 7 | Pre-dev figma + post-dev fidelity | P0-5 + P0-6 both fire | mas-figma → dev → mas-visual-fidelity | Ordering invariant #2 |
| 8 | Fidelity before ux/a11y | Permutation 1 + UX/A11Y predicates | mas-visual-fidelity → ux-intelligence → a11y | D9 evidence-before-judgment |
| 9 | P0 blocker iteration | Permutation 1 + blocker row | fidelity → dev fix → `RE_VERIFY` → fidelity | Max 2 iterations |
| 10 | Iteration cap exceeded | Two failed fidelity passes | User escalation | P0 table attached |
| 11 | Lite without VFID:y | Lite tier; design-spec exists | No mas-visual-fidelity; warn | Lite regression |
| 12 | Lite L + VFID:y | Lite L with explicit flag | mas-visual-fidelity within cap | `VFID:y` |
| 13 | Cap stress | Permutation 7 + max optional agents | User escalation if > 12; no silent skip of protected slots | D8 |
| 14 | Option 6 fallback | User accepts D12 fallback | test-executor owns visual section; no fidelity spawn | v1.3.1 patch path |
| 15 | Reviewer after fidelity | P0-6 fired; iteration complete | reviewer 0k consumes visual-qa | Reviewer never before incomplete fidelity |
| 16 | test-executor boundary | Normal v1 path | test-executor after ux chain; no Figma re-baseline | D1 separation |
| 17 | RE_EXTRACT vs RE_VERIFY | mas-figma re-extract + fidelity re-verify | figma overwrites contract only; fidelity overwrites visual-qa | Immutable/mutable split |

**Ordering invariants (P0 — must hold for every permutation):**

1. `mas-visual-fidelity` always **after** android-dev/general-dev; **before** ux-intelligence/a11y/i11n when triggered.
2. `mas-visual-fidelity` always **after** mas-figma when both fire (pre-dev extraction before post-dev verify).
3. Max **one** mas-visual-fidelity spawn per `TASK_ID` unless `RE_VERIFY: yes`.
4. Parity results live in `visual-qa` only — design-spec extraction sections **immutable** after fidelity run.
5. Dev does **not** self-attest fidelity without visual-qa brief when design-spec exists.
6. Reviewer remains sole `Approved:` authority; mas-visual-fidelity never patches production code.
7. MCP scope: `get_screenshot` only — **forbidden:** `get_design_context`, whole-frame pulls.
8. Full `/mas`: mas-visual-fidelity protected-when-triggered — not in token-rules auto-skip list.
9. Reviewer 0k does **not** re-call Figma MCP or re-capture — consumes brief only.
10. When design-spec exists without visual-qa, Layout/Typography/Color/Spacing imagined rows → **N/A** (cannot PASS on imagination).

---

## Predicate Test Cases (P0-6 mas-visual-fidelity)

| ID | Predicate | Handoff / context setup | Expected spawn | Expected brief path | Pass criteria |
|----|-----------|-------------------------|----------------|---------------------|---------------|
| P0-6a | `VISUAL_FIDELITY: yes` | Flag + design-spec + UI changes | mas-visual-fidelity | `visual-qa/{TASK_ID}.md` | All six required sections present |
| P0-6b | Auto + design-spec + `UI_CHANGES: YES` | `VISUAL_FIDELITY: auto` | mas-visual-fidelity | same | Default auto predicate |
| P0-6c | FILES inference | Composables/resources/themes in FILES | mas-visual-fidelity | same | D11 coordinator inference |
| P0-6d | `UI_CHANGES: NO` | design-spec exists | **No** spawn | — | Suppression rule #1 |
| P0-6e | No design-spec | `UI_CHANGES: YES` | **No** spawn | — | Suppression rule #2 |
| P0-6f | Friction-only existing UI | No new impl from spec | **No** spawn | — | Suppression rule #3 spirit |
| P0-6g | MCP blocked | Network down; PNG ≤ 7d + `BASELINE_STALE: no` | mas-visual-fidelity → BLOCKED baseline | same with degrade notes | P0 from metrics if extractable |
| P0-6h | No capture infra | Missing Paparazzi/Preview | mas-visual-fidelity → BLOCKED capture | same | Implementation Capture empty → 0k FAIL |
| P0-6i | P0 color blocker | Token mismatch | mas-visual-fidelity | blocker row in Measurement Diff | Coordinator routes dev fix |
| P0-6j | Dimension drift ≤ 2px | Subpixel layout variance | mas-visual-fidelity | `severity: minor` | D4 tolerance |
| P0-6k | `FIGMA_COMPLEXITY: high` OR > 3 screens | Complexity / multi-screen | `MODEL_CLASS: thinking` | sectioned brief | spawn-model-policy row |
| P0-6l | Lite `VFID:y` | Lite L handoff | mas-visual-fidelity within tier | same | Lite compatibility |
| P0-6m | Lite without VFID:y | Lite S/M/L; design-spec exists | **No** spawn + warn | — | Lite regression |
| P0-6n | Idempotency | Re-run without `RE_VERIFY` | **No** second spawn | — | session JSON blocks |
| P0-6o | `RE_VERIFY: yes` | Second intentional pass after dev fix | mas-visual-fidelity re-spawn | updated brief | Allowed override |
| P0-6p | Iteration cap | Third fidelity attempt after 2 failures | **No** auto spawn | — | User escalation |

**Spawn model policy (verify after implement):**

| Slug | Expected `MODEL_CLASS` |
|------|------------------------|
| mas-visual-fidelity | normal (default); thinking on `FIGMA_COMPLEXITY: high` or > 3 screen states |

---

## Visual Capture Command Fixtures (Target Android)

MAS framework repo has **no Gradle modules**. Test-strategy documents **contract shapes** consumed by mas-visual-fidelity and test-executor (Option 6 only).

| Priority | Method | Command hint | Verification Contract field |
|----------|--------|--------------|----------------------------|
| 1 | Paparazzi | `./gradlew :app:verifyPaparazziDebug` | `FidelityCardPaparazziTest#fidelityCard_default` |
| 2 | Compose Preview Screenshot | `./gradlew :app:validateDebugScreenshotTest` | `@Preview(name = "FidelityCardDefault")` |
| 3 | Emulator screencap | `adb exec-out screencap -p > capture.png` | Manual path in Implementation Capture |

**Dogfood stub values** (from `design-spec-stub.md` Verification Contract):

```bash
# Paparazzi (P0 contract shape — run in target Android repo only)
./gradlew :app:verifyPaparazziDebug --tests "com.example.dogfood.FidelityCardPaparazziTest"

# Compose Preview Screenshot Testing
./gradlew :app:validateDebugScreenshotTest

# Targeted compile sanity (dev handoff)
./gradlew :app:compileDebugKotlin
```

**MAS repo verification:** Assert test-strategy brief and design-spec stub **document** these commands — do not execute Gradle in MAS framework repo.

---

## Mutual-Exclusion Regression Checklist

Record pass/fail in reviewer output or `.ai/context/test-runs/MAS-06-VFID-DOGFOOD.md` after dogfood.

| # | Case | Fixture | Expected | Pass criteria |
|---|------|---------|----------|---------------|
| ME-1 | design-spec + `UI_CHANGES: YES` → fidelity, not ux first | `MAS-06-VFID-DOGFOOD` | mas-visual-fidelity after dev; ux after fidelity | Session steps order |
| ME-2 | `UI_CHANGES: NO` skips fidelity | `MAS-06-VFID-NONE` | No mas-visual-fidelity spawn | reviewer 0k N/A |
| ME-3 | No design-spec skips fidelity | `MAS-06-VFID-NO-SPEC` | No spawn | Predicate fails |
| ME-4 | design-spec without visual-qa → imagined layout rows N/A | `MAS-06-VFID-SCHEMA` (no visual-qa) | Cannot `Approved: YES` on Figma UI layout rows | build-test-visual-qa.md |
| ME-5 | Fidelity run does not mutate design-spec extraction | `MAS-06-VFID-IMMUTABLE` | Node Map/Tokens unchanged post-fidelity | Diff design-spec before/after |
| ME-6 | `RE_EXTRACT` on mas-figma does not touch visual-qa | `MAS-06-VFID-RE-EXTRACT` | Contract updated; visual-qa separate | Idempotency |
| ME-7 | Max 2 dev↔fidelity iterations | `MAS-06-VFID-ITER-CAP` | Third attempt → escalation | session `iteration_count` |
| ME-8 | Reviewer 0k does not call Figma MCP | Any dogfood | Consumer-only | mas-reviewer SKILL |
| ME-9 | mas-visual-fidelity vs mas-figma boundary | Dogfood chain | figma pre-dev; fidelity post-dev | No same-hop overlap |
| ME-10 | mas-visual-fidelity vs test-executor boundary | Normal v1 | test-executor run-only; no measurement diff ownership | mas-test-executor SKILL |
| ME-11 | mas-visual-fidelity vs ux/a11y | Skill stubs | Objective parity before friction/WCAG | ux/a11y one-liner cross-ref |
| ME-12 | No production patches from mas-visual-fidelity | Dogfood session | Zero git diff from specialist on prod paths | Read-only invariant |
| ME-13 | Lite skip + warn | `MAS-06-VFID-LITE` | Warn "Figma fidelity unverified" | mas-lite SKILL |
| ME-14 | Protected-when-triggered under cap stress | `MAS-06-VFID-CAP` | No silent skip | token-rules.md |
| ME-15 | Option 6 fallback documented | `MAS-06-VFID-OPTION6` | test-runs visual section; session flag | D12 escape hatch only |

---

## Visual-QA Schema Validation (Fixture-Based)

Validate synthetic / stub briefs against `brief-schemas.md` **visual-qa** registry before and after dogfood.

### Required sections (all must be present)

| Section | Validation command / check | Stub coverage |
|---------|---------------------------|---------------|
| Viewport & State | `rg "^## Viewport & State" .ai/fixtures/MAS-06-VFID-DOGFOOD/visual-qa-expected-shape.md` | width, height, density, fontScale, uiMode, state-id |
| Baseline Source | `rg "^## Baseline Source" ...` | source, node-id, path, captured-at |
| Implementation Capture | `rg "^## Implementation Capture" ...` | path(s), capture-method, git-revision |
| Measurement Diff | `rg "^## Measurement Diff" ...` | property \| expected \| actual \| delta \| severity |
| Screenshot Compare | `rg "^## Screenshot Compare" ...` | result, regions[], diff-artifact-path |
| Open Questions / Accepted Debt | `rg "^## Open Questions" ...` | degrade / HITL notes |

### Verification Contract validation (design-spec slice)

| Field | Stub coverage |
|-------|---------------|
| Viewport | 360×800 @ mdpi in `design-spec-stub.md` |
| default state-id | `default` |
| Capture Recipe | Paparazzi + Preview class names |
| Baseline Policy | `re-fetch` default |
| Tolerance | 2px dimensions; color exact |
| Metric Keys | Node Map + Design Tokens columns |

### Schema gap scenarios (reviewer 0k)

| Scenario | Setup | Expected reviewer outcome |
|----------|-------|----------------------------|
| Missing Measurement Diff | Omit section from visual-qa copy | `Approved: NO` — schema gap |
| P0 blocker unresolved | blocker row present | `Approved: NO` (Major minimum) |
| Empty Implementation Capture | BLOCKED or missing paths | `Approved: NO` on Figma UI |
| P1 PARTIAL | Screenshot compare PARTIAL | PASS with Major note on regions |
| Valid expected shape | Copy stub to `visual-qa/MAS-06-VFID-DOGFOOD.md` | Schema pass (advisory on stub provenance) |
| design-spec exists, no visual-qa | Pre-fidelity state | Layout/Typography/Color/Spacing → N/A |

### Fixture-based validation commands

```powershell
$stub = '.ai/fixtures/MAS-06-VFID-DOGFOOD/visual-qa-expected-shape.md'
$sections = @('Viewport & State','Baseline Source','Implementation Capture','Measurement Diff','Screenshot Compare','Open Questions / Accepted Debt')
foreach ($s in $sections) {
  if (-not (Select-String -Path $stub -Pattern "^## $s" -Quiet)) { throw "missing section: $s" }
}
'PASS visual-qa expected shape schema'

$ds = '.ai/fixtures/MAS-06-VFID-DOGFOOD/design-spec-stub.md'
if (-not (Select-String -Path $ds -Pattern "^## Verification Contract" -Quiet)) { throw 'missing Verification Contract' }
'PASS design-spec Verification Contract slice'
```

---

## Tests to Write

| # | Type | Target | Scenario | Rationale | Priority | Flaky risk | Mitigation | Command hint |
|---|------|--------|----------|-----------|----------|------------|------------|--------------|
| 1 | manual | `MAS-06-VFID-DOGFOOD` dogfood | Run `/mas` with design-spec stub + dev `UI_CHANGES: YES`; verify chain order and visual-qa path | Plan task 27 primary ship gate | P0 | LOW | Single coordinator session; record session JSON | Manual: `/mas` per fixture table |
| 2 | integration | `brief-schemas.md` registry | `visual-qa` type row with six required sections + Verification Contract reference | Reviewer 0k schema validation | P0 | LOW | Read registry only | `rg "visual-qa" skills/multi-agent-system/protocol/brief-schemas.md` |
| 3 | integration | `handoff-format.md` flags | `VISUAL_FIDELITY`, `UI_CHANGES`, `RE_VERIFY`, `BASELINE_STALE` documented | Zero-token P0-6 routing | P0 | LOW | — | `rg "VISUAL_FIDELITY|UI_CHANGES|RE_VERIFY|BASELINE_STALE" skills/multi-agent-system/protocol/handoff-format.md` |
| 4 | integration | Lite `VFID:y` | `handoff-format-lite.md` documents abbreviated flag | Lite dogfood | P1 | LOW | — | `rg "VFID:y" skills/multi-agent-system/protocol/handoff-format-lite.md` |
| 5 | integration | `subagent-spawn.md` | `mas-visual-fidelity` slug row; `run_in_background: false` | Task spawn contract | P0 | LOW | — | `rg "mas-visual-fidelity" skills/multi-agent-system/protocol/subagent-spawn.md` |
| 6 | integration | `read-order.md` | mas-visual-fidelity subscription + reviewer 0k + dev Verification Contract read | Startup read contract | P0 | LOW | — | `rg "mas-visual-fidelity|visual-qa|Verification Contract" skills/multi-agent-system/protocol/read-order.md` |
| 7 | integration | Coordinator P0-6 predicate | `mas-coordinator/SKILL.md` matches architecture predicate table | Deterministic routing | P0 | LOW | — | Compare to `.ai/context/architecture/MAS-06.md` |
| 8 | integration | Protected-when-triggered | `token-rules.md` notes mas-visual-fidelity not auto-skipped in full `/mas` | D8 cap policy | P0 | LOW | — | `rg "mas-visual-fidelity" skills/multi-agent-system/protocol/token-rules.md` |
| 9 | integration | Iteration loop | P0 blocker → dev → `RE_VERIFY` → pass; max 2 | D11 iteration discipline | P0 | LOW | — | Inspect session `iteration_count` |
| 10 | integration | `manifest.json` v1.4.0 | Version bump; `mas-visual-fidelity` in skills array | Install acceptance | P0 | LOW | — | `Get-Content skills/multi-agent-system/install/manifest.json \| ConvertFrom-Json` |
| 11 | integration | `visual-fidelity-standards.md` | Three-tier table, tolerance D4, MCP scope | Shared reference | P0 | LOW | — | `Test-Path skills/multi-agent-system/references/visual-fidelity-standards.md` |
| 12 | integration | `mas-visual-fidelity/SKILL.md` invariants | Forbids Task spawn, code patch, `Approved:`, `get_design_context` | Specialist contract | P0 | LOW | — | `rg "Never|never|get_design_context" skills/mas-visual-fidelity/SKILL.md` |
| 13 | schema | Fixture visual-qa shape | `visual-qa-expected-shape.md` passes six-section check | Offline validation baseline | P0 | LOW | — | See **Visual-QA Schema Validation** commands |
| 14 | schema | Fixture Verification Contract | `design-spec-stub.md` includes Verification Contract | Pre-dev contract slice | P0 | LOW | — | See validation commands |
| 15 | manual | Mutual-exclusion checklist | Run ME-1 through ME-15 | Plan task 28 | P0 | LOW | — | Record in test-run or reviewer brief |
| 16 | manual | `MAS-06-VFID-NONE` | design-spec + `UI_CHANGES: NO` | Negative predicate | P0 | LOW | — | Zero mas-visual-fidelity in session |
| 17 | manual | `MAS-06-VFID-P0-BLOCK` | Simulated blocker iteration | Dev fix loop | P0 | LOW | — | `RE_VERIFY: yes` on second pass |
| 18 | manual | `MAS-06-VFID-MCP-BLOCK` | MCP blocked baseline fallback | Degrade path D3 | P1 | LOW | — | BLOCKED + PNG fallback |
| 19 | manual | `MAS-06-VFID-LITE` | Lite without `VFID:y` | Skip + warn | P1 | LOW | — | Coordinator summary text |
| 20 | integration | Reviewer step 0k | `mas-reviewer/SKILL.md` documents Design-Fidelity Verification | Gate preservation | P0 | LOW | — | `rg "0k|visual-qa" skills/mas-reviewer/SKILL.md` |
| 21 | integration | `build-test-visual-qa.md` | Imagined rows N/A when design-spec without visual-qa | Artifact-backed gate | P0 | LOW | — | `rg "visual-qa|N/A" skills/multi-agent-system/references/build-test-visual-qa.md` |
| 22 | integration | mas-figma Verification Contract | `mas-figma/SKILL.md` emits §8; no post-dev parity in design-spec | Immutable/mutable split | P0 | LOW | — | `rg "Verification Contract" skills/mas-figma/SKILL.md` |
| 23 | integration | Dev consumer skills | android-dev/general-dev read Verification Contract; declare `UI_CHANGES` | Dev startup contract | P0 | LOW | — | `rg "Verification Contract|UI_CHANGES" skills/mas-general-dev/SKILL.md` |
| 24 | integration | test-executor boundary | No Figma re-baseline in v1; Option 6 note only | D1 separation | P1 | LOW | — | `rg "visual.fidelity|Option 6" skills/mas-test-executor/SKILL.md` |
| 25 | integration | Context dir | `.ai/context/visual-qa/` exists | Artifact bus | P1 | LOW | — | `Test-Path .ai/context/visual-qa` |
| 26 | integration | Capture command fixtures | test-strategy stub documents Paparazzi/Preview commands | Downstream contract | P1 | LOW | — | `rg "verifyPaparazzi|validateDebugScreenshot" .ai/fixtures/MAS-06-VFID-DOGFOOD/` |
| 27 | manual | Option 6 fallback doc | `MAS-06-VFID-OPTION6` session shape | D12 escape hatch | P2 | LOW | — | Document only; not default path |
| 28 | integration | Export bundle | Dry-run includes `skills/mas-visual-fidelity/` | Bundle integrity | P1 | LOW | Temp output dir | `export-mas-framework.ps1 -OutputDir $env:TEMP\mas-export-mas06` |

---

## Tests to Skip

| # | Target | Reason | Covered by |
|----|--------|--------|------------|
| 1 | Gradle `:app:verifyPaparazziDebug` in MAS repo | No Android modules in framework repo | Capture command fixtures document contract shapes only |
| 2 | Compose/UI/instrumentation tests | `UI_SCOPE: logic-only`; no screens | N/A MAS-06 |
| 3 | Automated pytest/npm unit suite for skills | No test harness for markdown skills | Manual permutation matrix + schema checks |
| 4 | Live Figma `get_screenshot` in CI | Network + auth dependency; flaky | Fixture stub + optional manual MCP dogfood |
| 5 | Live pixel diff on real captures | No Compose output in MAS repo | visual-qa expected shape validates data contract |
| 6 | LLM image comparison for P0 | Architecture forbids LLM spatial reasoning on P0 | Structured measurement diff only |
| 7 | Commercial visual AI SDK (Applitools/SmartUI) | D10 — brief shape adapt only | visual-fidelity-standards.md |
| 8 | E2E Cursor IDE automation | No stable CI for Task spawn | Manual `/mas` dogfood |
| 9 | Full MAS-05 mas-figma regression | Separate fixtures (`MAS-05-FIGMA-DOGFOOD`) | Spot-check P0-5 unchanged; P0-6 additive |
| 10 | MAS-04 P1 trio ordering regression | Covered by ME-8 permutation | ux→a11y→i18n after fidelity when all fire |
| 11 | Paparazzi font rendering cross-device | Target-project concern | D4: 2px dimension slack; color exact |
| 12 | Motion/hover/loading states | D5 v1 scope = default state only | P2 reviewer imagined rows |

---

## Edge Cases

| Case | Layer | Test approach | Priority |
|------|-------|---------------|----------|
| Auto + explicit flags both set | Coordinator | Single spawn; explicit does not double-spawn | P0 |
| design-spec + `UI_CHANGES: NO` | Coordinator | Skip fidelity; 0k N/A | P0 |
| design-spec without Verification Contract | mas-visual-fidelity | Use Node Map defaults; flag Open Questions | P1 |
| MCP unreachable; PNG age > 7d | mas-visual-fidelity | BLOCKED baseline; no trust | P0 |
| MCP unreachable; PNG ≤ 7d + `BASELINE_STALE: no` | mas-visual-fidelity | Trust committed PNG; note in brief | P0 |
| Color token mismatch | Measurement Diff | P0 `blocker`; routes dev fix | P0 |
| Dimension drift 1–2px | Measurement Diff | `severity: minor` | P0 |
| P1 screenshot PARTIAL | Screenshot Compare | 0k PASS with Major note | P1 |
| No Paparazzi/Preview in target | Implementation Capture | BLOCKED; 0k FAIL | P0 |
| Iteration 1 fail → dev fix → pass | Coordinator | `RE_VERIFY: yes`; continue chain | P0 |
| Iteration 3 attempt | Coordinator | User escalation | P0 |
| `RE_EXTRACT` on mas-figma | design-spec | Contract overwritten; visual-qa untouched | P0 |
| Fidelity overwrites visual-qa on re-run | mas-visual-fidelity | Idempotent overwrite same path | P1 |
| Cap at 13+ with figma + fidelity | Coordinator | User escalation; Option 6 offer | P0 |
| Lite handoff >12 lines with VFID:y | Lite coordinator | Within cap or warn | P1 |
| Multi-screen > 3 states | Coordinator | `MODEL_CLASS: thinking` | P1 |
| test-executor Option 6 fallback | Session JSON | `visual_fidelity_fallback: test-executor` | P2 |
| a11y references P0 color rows | a11y | Read visual-qa; no re-capture | P1 |
| Dev self-attests without visual-qa | Dev SKILL | Forbidden when design-spec exists | P0 |
| mas-visual-fidelity patches protocol | Specialist | Forbidden — general-dev owns edits | P0 |

---

## Regression Risks

N/A — `.ai/context/daily-changelog.md` has no same-day task entries (empty log for 2026-09-28).

**Cross-workflow:**

- **MAS-05** P0-5 mas-figma chain and design-spec schema must not regress — P0-6 inserts post-dev slot only; pre-dev ordering unchanged.
- **MAS-04** Phase A/B routing (test-executor, ux→a11y→i18n) must remain intact — fidelity runs **before** ux/a11y when triggered.
- **MAS-04-FIX-P0-ALL** test-executor run-only boundary must not expand to Figma baseline unless Option 6 explicitly activated.

---

## Flaky Test Risks

| Risk | Surface | Mitigation |
|------|---------|------------|
| Live Figma MCP `get_screenshot` availability | Dogfood | Primary path uses fixtures; live MCP optional; PNG fallback ≤ 7d |
| Manual dogfood session drift | Chain verification | Fixed fixture TASK_IDs; `workflow-sessions/{FIXTURE}.json` evidence |
| Paparazzi JVM font rendering vs device | Target Android P0 | D4: 2px dimension slack only; color exact |
| Screenshot compare timing/async | P1 capture | Stable preview names; disable animations in capture recipe |
| Export script path variance | Bundle test | `-OutputDir $env:TEMP\mas-export-mas06` |
| Coordinator table vs architecture drift | Predicate tests | Architecture brief is source; coordinator mirrors on implement |
| Baseline PNG missing in stub | Schema validation | Path note acceptable without image file for offline validation |
| `rg` vs `Select-String` on Windows | Protocol checks | Use `rg` when available; bounded single-file patterns |
| MAX_CHAIN_AGENTS false cap failures | Cap stress dogfood | Document escalation path; never silent skip protected slots |

---

## Recommended Commands

**No Gradle in MAS framework repo.** Logic-only verification:

```powershell
# Manifest version and mas-visual-fidelity registration
$m = Get-Content skills/multi-agent-system/install/manifest.json -Raw | ConvertFrom-Json
if ($m.version -ne '1.4.0') { throw "version mismatch: $($m.version)" }
if ($m.skills -notcontains 'mas-visual-fidelity') { throw 'mas-visual-fidelity missing from skills array' }
'PASS manifest parse'

# Protocol registry
rg "visual-qa" skills/multi-agent-system/protocol/brief-schemas.md
rg "Verification Contract" skills/multi-agent-system/protocol/brief-schemas.md
rg "VISUAL_FIDELITY|UI_CHANGES|RE_VERIFY|BASELINE_STALE" skills/multi-agent-system/protocol/handoff-format.md
rg "VFID:y" skills/multi-agent-system/protocol/handoff-format-lite.md
rg "mas-visual-fidelity" skills/multi-agent-system/protocol/subagent-spawn.md
rg "mas-visual-fidelity|visual-qa" skills/multi-agent-system/protocol/read-order.md
rg "mas-visual-fidelity" skills/multi-agent-system/protocol/token-rules.md
rg "mas-visual-fidelity" skills/multi-agent-system/protocol/spawn-model-policy.md

# Reference + specialist skill
Test-Path skills/multi-agent-system/references/visual-fidelity-standards.md
Test-Path skills/mas-visual-fidelity/SKILL.md

# Context dir
Test-Path .ai/context/visual-qa

# Visual-qa expected shape schema (fixture-based)
$stub = '.ai/fixtures/MAS-06-VFID-DOGFOOD/visual-qa-expected-shape.md'
$sections = @('Viewport & State','Baseline Source','Implementation Capture','Measurement Diff','Screenshot Compare','Open Questions / Accepted Debt')
foreach ($s in $sections) {
  if (-not (Select-String -Path $stub -Pattern "^## $s" -Quiet)) { throw "missing section: $s" }
}
'PASS visual-qa expected shape schema'

# Verification Contract slice
$ds = '.ai/fixtures/MAS-06-VFID-DOGFOOD/design-spec-stub.md'
if (-not (Select-String -Path $ds -Pattern "^## Verification Contract" -Quiet)) { throw 'missing Verification Contract' }
'PASS design-spec Verification Contract slice'

# Mutual-exclusion cross-refs
rg "mas-visual-fidelity|visual-fidelity" skills/mas-ux-intelligence/SKILL.md
rg "mas-visual-fidelity|visual-qa" skills/mas-a11y/SKILL.md
rg "Verification Contract|UI_CHANGES" skills/mas-general-dev/SKILL.md
rg "0k|visual-qa" skills/mas-reviewer/SKILL.md
rg "visual-qa|N/A" skills/multi-agent-system/references/build-test-visual-qa.md

# Capture command fixtures documented
rg "verifyPaparazzi|validateDebugScreenshot" .ai/fixtures/MAS-06-VFID-DOGFOOD/

# Export dry-run
powershell -File skills/multi-agent-system/install/export-mas-framework.ps1 -OutputDir "$env:TEMP\mas-export-mas06"
Test-Path "$env:TEMP\mas-export-mas06/skills/mas-visual-fidelity/SKILL.md"

# Session evidence after dogfood
Get-Content .ai/context/workflow-sessions/MAS-06-VFID-DOGFOOD.json | ConvertFrom-Json | Select-Object visual_fidelity_spawned, iteration_count, specialists_spawned
```

**Target Android project (when dogfood includes real impl — not MAS repo):**

```bash
./gradlew :app:verifyPaparazziDebug --tests "com.example.dogfood.FidelityCardPaparazziTest"
# or
./gradlew :app:validateDebugScreenshotTest
```

**Manual (primary P0 gate — dogfood):**

1. `/mas` synthetic feature with handoff matching `MAS-06-VFID-DOGFOOD` fixture (`handoff-stub.md`).
2. Copy `design-spec-stub.md` → `design-specs/MAS-06-VFID-DOGFOOD.md` (or run mas-figma pre-dev).
3. Dev handoff with `UI_CHANGES: YES` and capture paths in `FILES`.
4. Confirm spawn order: dev → mas-visual-fidelity → ux-intelligence (per chain matrix row #1).
5. Confirm `visual-qa/MAS-06-VFID-DOGFOOD.md` exists with six required sections (live MCP or expected-shape copy).
6. Run mutual-exclusion checklist ME-1–ME-15; record pass/fail.
7. Confirm no production/skill patches from mas-visual-fidelity specialist (audit-only).
8. Reviewer 0k validates schema; unresolved P0 blockers → `Approved: NO`.

**Offline CI path:** Copy fixture stubs to context dirs; run schema validation commands; skip live MCP/capture dogfood.

---

## Overall Confidence

**HIGH** — Scope is protocol/skills/manifest only; architecture brief and plan define P0-6 predicate, three-tier verification, cap policy, iteration loop, mutual-exclusion, and visual-qa schema. Fixture TASK_IDs, chain permutation matrix, capture command contract shapes, degrade paths, and fixture-based schema validation are actionable for general-dev and dogfood without Android test infrastructure in the MAS repo.

---

## Files Reviewed

- `.ai/handoffs/MAS-06-test-strategy.md`
- `.ai/context/plans/MAS-06.md` (Phases 0–7)
- `.ai/context/architecture/MAS-06.md`
- `.ai/context/memory.md`
- `.ai/context/daily-changelog.md`
- `skills/multi-agent-system/references/test-strategy-standards.md` (via skill)
- `.ai/context/test-strategies/MAS-05.md` (format reference)

---

## Open Questions

1. **Dogfood TASK_ID handoff suffix** — Coordinator naming for mas-visual-fidelity handoff (`MAS-06-VFID-DOGFOOD-mas-visual-fidelity.md` vs `-visual-fidelity.md`); record actual pattern during dogfood.
2. **Mock brief merge approval** — Stub copy path is schema-valid but not live fidelity run; reviewer should flag stub provenance in Open Questions before `Approved: YES`.
3. **Export skill list** — Verify `export-mas-framework.ps1` reads `manifest.json` vs hardcoded list during general-dev implement.
4. **Option 6 ship decision** — If MAX_CHAIN_AGENTS blocks at ship time, confirm user escalation vs v1.3.1 fallback before dogfood assumes Option 5 only.

---

## Usage Report

Model: default
Class: normal
Tokens: unknown

DONE
