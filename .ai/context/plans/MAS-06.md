# Plan Brief — MAS-06

## Plan

Goal:
Implement **Option 5 — Composite** (per `.ai/context/brainstorms/MAS-06.md` Recommended and `.ai/context/osint/MAS-06.md` Recommended Approach): add post-dev **`mas-visual-fidelity`** specialist, new **`visual-qa`** brief type at `.ai/context/visual-qa/{TASK_ID}.md`, slim **Verification Contract** slice on `design-spec`, reviewer step **0k Design-Fidelity Verification** (consumer-only), and **`build-test-visual-qa.md`** artifact-backed gate — so Figma-driven UI cannot pass review on imagined Visual QA alone. **Logic-only** — no Compose screens; protocol/skill contracts only. Closes the deferred hole from MAS-05 ("downstream visual QA") using the MAS-04 advisory specialist pattern.

**Resolved open questions (D1–D5):**

| ID | Decision | Rationale |
|----|----------|-----------|
| D1 | **New `mas-visual-fidelity` specialist** (not extend `test-executor` for v1) | Clean evidence/judgment split; test-executor remains run-only. **Option 6 fallback:** if `MAX_CHAIN_AGENTS` blocks at ship time, document `test-runs` visual section extension as v1.3.1 stepping stone — architect confirms. |
| D2 | Capture infra is **target-project dependent**; fidelity agent writes `BLOCKED` + HITL when missing | Architect inventories Paparazzi / Compose Preview Screenshot Testing / emulator path per dogfood repo; no MAS-framework Gradle changes. |
| D3 | **Re-fetch `get_screenshot`** at fidelity gate by default; trust committed design-spec PNG only when MCP unreachable **and** PNG exists with age **≤ 7 days** | OSINT Finding #3; stale pre-dev baseline anti-pattern. Handoff flag `BASELINE_STALE: no` optional override. |
| D4 | **2px slack on dimensions only**; **zero tolerance** on colors/tokens | TSH / buildmvpfast measurement-first pattern; font rendering variance on dimensions → `minor` not `blocker`. |
| D5 | **v1 scope = default UI state only** | Interaction/hover/motion gaps remain P2 reviewer imagined rows. |

**Version target:** `1.4.0` (new protected specialist + brief type; architect may recommend `1.3.1` if treating as additive patch).

**NEXT_AGENT:** architect

Tasks:

### Phase 0 — Architect gate (pre-implementation)

1. **Architect confirms post-dev fidelity topology, capture contract, and chain ordering** — Validate predicate table, chain position (after dev, **before** ux-intelligence), `MAX_CHAIN_AGENTS` impact (+1 protected slot alongside `mas-figma`), mutual-exclusion matrix, iteration loop (max 2), and D1–D5 resolutions above.
   - **Files:** `.ai/context/architecture/MAS-06.md` (new)
   - **Decisions required:**
     - Chain slot: `mas-visual-fidelity` protected-when-triggered (same policy as `mas-figma` per `token-rules.md`)
     - Predicate: `VISUAL_FIDELITY: auto` when `design-specs/{TASK_ID}.md` exists AND dev handoff `UI_CHANGES: YES` (or `FILES` touch Composables/resources)
     - Suppression: skip when `UI_CHANGES: NO` or no design-spec; skip when only friction/WCAG on existing UI (no new impl from spec)
     - Multi-screen design-spec: one `visual-qa` brief with per-screen sections vs one brief per screen (default: sectioned single brief; `thinking` when > 3 screens)
     - Capture method priority for dogfood: Paparazzi > Compose Preview Screenshot Testing > emulator `adb screencap`
     - Option 6 fallback trigger conditions if chain cap blocks Option 5 at ship
     - Semver: `1.4.0` vs `1.3.1`
   - **Acceptance:** Architecture brief documents three-tier verification (P0/P1/P2), immutable extraction vs mutable verification separation, specialist invariants (read-only, `get_screenshot` only, no `Approved:`), and references brainstorm Domain & Contracts §1–6.

### Phase 1 — Protocol foundation

2. **Extend `brief-schemas.md`** — Register `visual-qa` brief type and `design-spec` Verification Contract slice.
   - **Files:** `skills/multi-agent-system/protocol/brief-schemas.md`
   - **New type:** `visual-qa` → `.ai/context/visual-qa/{TASK_ID}.md`
   - **Required sections:** Viewport & State, Baseline Source, Implementation Capture, Measurement Diff, Screenshot Compare, Open Questions / Accepted Debt
   - **design-spec enhancement:** Add optional **Verification Contract** subsection (required when `FIGMA_SPEC` / design-spec exists at fidelity gate): viewport (w×h), density, `fontScale` variants, default `state-id`, Capture Recipe, Baseline Policy (`re-fetch` | `trust-committed` + max age 7d), Tolerance (2px dimensions, color exact), Metric Keys for P0 diff
   - **Invariant:** Parity results live in `visual-qa` only — never append mutable verification rows to design-spec extraction sections
   - **Acceptance:** Registry rows added; field contracts referenced (not pasted); Reviewer validation guidance notes 0k dependency.

3. **Extend `spawn-model-policy.md`** — Add `mas-visual-fidelity` MODEL_CLASS row.
   - **Files:** `skills/multi-agent-system/protocol/spawn-model-policy.md`
   - **Map:** `mas-visual-fidelity` → default `normal`; escalate `thinking` when `FIGMA_COMPLEXITY: high` or multi-screen (> 3 states)
   - **Acceptance:** Table row present; lite `MC:` cross-ref if applicable.

4. **Extend `read-order.md`** — Subscription matrix for fidelity pipeline.
   - **Files:** `skills/multi-agent-system/protocol/read-order.md`
   - **mas-visual-fidelity reads:** design-specs, plans, dev handoff `FILES`, test-strategies (visual capture commands slice)
   - **reviewer add:** `visual-qa/{TASK_ID}.md` at step 0k (after 0j design-spec)
   - **android-dev / general-dev add:** design-spec **Verification Contract** at startup when present
   - **Acceptance:** Matrix complete; conditional reads documented.

5. **Extend `handoff-format.md` + lite format** — Document visual-fidelity routing fields.
   - **Files:** `skills/multi-agent-system/protocol/handoff-format.md`, `skills/multi-agent-system/protocol/handoff-format-lite.md`
   - **Flags (full):** `VISUAL_FIDELITY: yes` | `VISUAL_FIDELITY: auto` (coordinator predicate); `BASELINE_STALE: no` (trust committed PNG); `RE_VERIFY: yes` (idempotent re-run override, mirrors `RE_EXTRACT`)
   - **Lite:** `VFID:y` (explicit only — no auto predicate in lite); skip spawn + warn "Figma fidelity unverified"
   - **Triggers:** explicit flag **or** `VISUAL_FIDELITY: auto` when design-spec exists AND `UI_CHANGES: YES`
   - **Suppression:** `UI_CHANGES: NO` → skip; no design-spec → skip
   - **Acceptance:** Flags documented; dev handoff must declare `UI_CHANGES` for auto predicate.

6. **Extend `subagent-spawn.md`** — Register `mas-visual-fidelity` slug with Task spawn template.
   - **Files:** `skills/multi-agent-system/protocol/subagent-spawn.md`
   - **Acceptance:** Slug row includes `mas-visual-fidelity`; `run_in_background: false`.

7. **Extend `token-rules.md`** — Protected-when-triggered policy for `mas-visual-fidelity`.
   - **Files:** `skills/multi-agent-system/protocol/token-rules.md`
   - **Rule:** Same as `mas-figma` — not on auto-skip list in full `/mas`; cap breach → user escalation with unresolved P0 table attached
   - **Acceptance:** Policy paragraph added; Lite skip behavior cross-referenced.

8. **Create deliverable context directory** — Ensure visual-qa brief path exists.
   - **Files:** `.ai/context/visual-qa/.gitkeep`
   - **Acceptance:** Directory present.

### Phase 2 — Reference standards + `mas-visual-fidelity` skill

9. **Create `visual-fidelity-standards.md`** — Shared reference for fidelity specialist, dev, test-strategy, reviewer.
   - **Files:** `skills/multi-agent-system/references/visual-fidelity-standards.md` (new)
   - **Content:** Three-tier verification table (P0 measurement, P1 screenshot pair, P2 subjective); baseline resolve order (re-fetch `get_screenshot` → trust committed PNG); capture method matrix (Paparazzi / Compose Preview Screenshot Testing / emulator); measurement diff row shape (`property | expected | actual | delta | severity`); tolerance policy (D4); iteration loop; MCP scope (`get_screenshot` only — **forbidden:** `get_design_context`, whole-frame pulls); Android baseline import contract (Figma PNG → `screenshotTest/reference/`)
   - **Acceptance:** Referenced from skill + `build-test-visual-qa.md`; no commercial SDK paste (Applitools/SmartUI patterns only).

10. **Create `skills/mas-visual-fidelity/SKILL.md`** — Post-dev read-only design fidelity auditor.
    - **Responsibilities:** Consume design-spec + Verification Contract; resolve baseline; capture implementation per recipe; emit P0 measurement diff + P1 screenshot compare; write `.ai/context/visual-qa/{TASK_ID}.md`; return summary + `BRIEF_PATH`
    - **Pipeline (mandate in skill):**
      1. Read design-spec (all sections + Verification Contract), dev `FILES`, test-strategy visual commands
      2. Baseline resolve — `get_screenshot` on design-spec `node-id` (default re-fetch); fallback design-spec Screenshot Reference if MCP blocked + age ≤ 7d
      3. Implementation capture per Capture Recipe (match Node Map width/height + `fontScale` from contract)
      4. P0 structured measurement diff — no LLM spatial reasoning on images
      5. P1 screenshot pair compare — PASS/FAIL/PARTIAL + region summary
      6. On P0 `blocker` rows → handoff notes for dev fix loop (Coordinator routes; max 2 iterations)
    - **Never:** patch production code; spawn Task; issue `Approved:`; call `get_design_context`
    - **Degrade paths:** MCP unreachable, no capture infra, missing preview — write `BLOCKED` brief + HITL; P0 measurement still runs when metrics extractable
    - **Acceptance:** Startup reads handoff → skill → read-order → upstream BRIEF_PATH slices; output matches `visual-qa` schema.

### Phase 3 — Design-spec Verification Contract (mas-figma output enhancement)

11. **Extend `figma-extraction-standards.md`** — Add Verification Contract section template for mas-figma to populate at extraction time.
    - **Files:** `skills/multi-agent-system/references/figma-extraction-standards.md`
    - **Fields:** Viewport from Node Map root dimensions; default `state-id: default`; Capture Recipe placeholder (dev/test-strategy fills); Baseline Policy default `re-fetch`; Tolerance defaults; Metric Keys = Design Tokens + Node Map dimension columns
    - **Acceptance:** mas-figma can emit contract without guessing capture commands; Open Questions flags when viewport ambiguous.

12. **Update `mas-figma/SKILL.md`** — Emit Verification Contract as eighth section (optional until predicate; recommended always for new extractions).
    - **Files:** `skills/mas-figma/SKILL.md`
    - **Rule:** Do not store post-dev parity results in design-spec; contract is read-only input for fidelity agent
    - **Acceptance:** Extraction pipeline step 8 documented; `RE_EXTRACT` overwrites contract with fresh viewport/tokens.

### Phase 4 — Coordinator routing + downstream consumers

13. **Update `mas-coordinator/SKILL.md`** — Add P0-6 visual-fidelity predicate and chain position.
    - **Predicate:**

    | Priority | Predicate (any true) | Specialist | Default chain position |
    |----------|----------------------|------------|------------------------|
    | P0-6 | `VISUAL_FIDELITY: yes` OR (`VISUAL_FIDELITY: auto` AND `design-specs/{TASK_ID}.md` exists AND dev `UI_CHANGES: YES`) | mas-visual-fidelity | After android-dev/general-dev; **before** ux-intelligence |

    - **Updated UI-from-Figma chain:** `… → mas-figma → dev → [mas-visual-fidelity?] → ux-intelligence → a11y → i18n → … → test-executor → documenter → reviewer`
    - **Iteration loop:** P0 blockers → dev fix handoff (lists delta rows) → re-spawn visual-fidelity (`RE_VERIFY: yes`); max 2 iterations → user escalation
    - **Session JSON:** `visual_fidelity_spawned`, `p0_blockers`, `iteration_count`
    - **Lite:** Skip spawn; warn "Figma fidelity unverified"
    - **Acceptance:** Zero-token routing; handoff includes `BRIEF_PATH`, `MODEL_CLASS`, upstream design-spec ref.

14. **Update `mas-lite/SKILL.md`** — Register `VFID:y` flag; document skip + warn (no auto predicate).
    - **Acceptance:** L/L+ tiers unchanged unless `VFID:y` explicit; cap breach warns recommend full `/mas`.

15. **Update `mas-android-dev/SKILL.md` + `mas-general-dev/SKILL.md`** — Read Verification Contract at startup; implement capture recipe hooks (preview names, Paparazzi test class, baseline PNG commit path).
    - **Acceptance:** Dev documents capture paths in handoff `FILES`; does not self-attest fidelity without visual-qa brief downstream.

16. **Update `mas-ux-intelligence/SKILL.md` + `mas-a11y/SKILL.md`** — Mutual-exclusion cross-reference (one line each).
    - **Boundary:** visual-fidelity = objective layout/token parity; ux-intelligence = behavioral friction; a11y = WCAG (may reference P0 color rows from visual-qa)
    - **Ordering:** visual-fidelity runs **before** ux/a11y when triggered.

17. **Update `mas-test-strategy/SKILL.md`** — Align visual capture commands with Verification Contract and visual-qa capture recipe.
    - **Acceptance:** test-strategy brief may recommend Paparazzi/`@PreviewTest` class names consumed by fidelity agent; does not replace fidelity specialist.

18. **Update `mas-test-executor/SKILL.md`** — Boundary note: may run screenshot validate commands from test-strategy but does **not** own Figma baseline re-fetch or measurement diff (unless Option 6 fallback activated).
    - **Acceptance:** No scope expansion in v1 unless architect documents fallback.

### Phase 5 — Reviewer + Visual QA reference

19. **Update `build-test-visual-qa.md`** — Artifact-backed Visual QA when design-spec exists.
    - **Files:** `skills/multi-agent-system/references/build-test-visual-qa.md`
    - **Rules:**
      | Condition | Visual QA behavior |
      |-----------|-------------------|
      | No design-spec | Imagined checklist (unchanged) |
      | design-spec exists, no visual-qa brief | Layout/Typography/Color/Spacing rows → **N/A** (cannot PASS on imagination) |
      | visual-qa brief exists | P0/P1 sourced from brief; P2 polish rows remain imagined |
    - **Acceptance:** Agent Responsibilities Summary table updated; approval blockers reference 0k.

20. **Update `mas-reviewer/SKILL.md`** — Add step **0k Design-Fidelity Verification** (after 0j).
    - **Startup read #15:** When `visual-qa/{TASK_ID}.md` exists — run 0k
    - **0k workflow:**
      1. No design-spec → 0k N/A
      2. design-spec exists → require `visual-qa` brief with all schema sections
      3. P0 rows with `severity: blocker` unresolved → `Approved: NO` (Major minimum)
      4. Reviewer does **not** re-call Figma MCP or re-capture — consumes brief only
      5. Implementation Capture paths must exist and be non-empty for `Approved: YES` on Figma UI
    - **Acceptance:** 0j unchanged; 0k documented with PASS/FAIL template; imagined layout/typography/color/spacing rows downgrade per build-test-visual-qa.md.

### Phase 6 — Install + manifest + top-level roster

21. **Update `install/manifest.json`** — Register `mas-visual-fidelity`; version bump to `1.4.0` (or architect-chosen).
    - **Files:** `skills/multi-agent-system/install/manifest.json`
    - **Add:** `mas-visual-fidelity`
    - **Acceptance:** `skills` array includes entry; export script copies skill tree.

22. **Update export/install scripts** — Include `mas-visual-fidelity` if skill list is hardcoded.
    - **Files:** `skills/multi-agent-system/install/export-mas-framework.ps1` (if applicable)
    - **Acceptance:** Dry-run export includes new skill.

23. **Update `multi-agent-system/SKILL.md`** — Roster section for MAS-06 visual-fidelity layer.
    - **Content:** Specialist role, `VISUAL_FIDELITY`/`VFID:y` flags, `visual-qa/` path, chain position, three-tier verification summary, protected-when-triggered note
    - **Acceptance:** Cross-links to `visual-fidelity-standards.md` and protocol files.

### Phase 7 — Test strategy, documentation, dogfood

24. **test-strategy brief** — Synthetic fixture TASK_ID with design-spec stub + Verification Contract; chain permutation matrix.
    - **Files:** `.ai/context/test-strategies/MAS-06.md`
    - **Cases:** visual-fidelity triggered vs skipped (`UI_CHANGES: NO`, no design-spec); P0 blocker iteration loop; MCP blocked baseline fallback; Lite `VFID:y` skip; Option 6 fallback path if documented
    - **Acceptance:** Expected spawn order, schema validation checkpoints, capture command fixtures.

25. **Create dogfood fixture** — Stub design-spec + Verification Contract for dry-run without live Figma.
    - **Files:** `.ai/fixtures/MAS-06-VFID-DOGFOOD/design-spec-stub.md`, `.ai/fixtures/MAS-06-VFID-DOGFOOD/visual-qa-expected-shape.md`
    - **Acceptance:** Fixtures validate brief-schemas headings; usable by reviewer dogfood.

26. **Documenter pass** — README + daily-changelog entry policy.
    - **Content:** MAS-06 closes post-dev fidelity gap; `mas-visual-fidelity` + `visual-qa` brief; when auto predicate fires; Lite warning text
    - **Acceptance:** User-facing docs list specialist and triggers.

27. **Dogfood workflow** — Manual `/mas` run on `MAS-06-VFID-DOGFOOD` TASK_ID.
    - **Acceptance:** visual-fidelity spawns after dev when design-spec + `UI_CHANGES: YES`; brief written to `.ai/context/visual-qa/{TASK_ID}.md`; P0 iteration loop routes to dev once; reviewer 0k validates schema; no specialist patches code; mutual-exclusion vs mas-figma/ux-intelligence verified.

28. **Regression checklist** — Document in architecture or test-strategy brief.
    - **Cases:** design-spec without UI changes skips fidelity; imagined Visual QA cannot PASS layout rows when design-spec exists; design-spec extraction sections unchanged after fidelity run; `RE_EXTRACT` on mas-figma does not mutate visual-qa; chain cap escalation path
    - **Acceptance:** Checklist pass recorded in reviewer or test-run brief.

## Dependencies

| Task | Depends on | Reason |
|------|------------|--------|
| 2–8 (protocol foundation) | 1 (architect) | Predicate table, capture contract, semver, Option 6 fallback gate |
| 9–10 (skill + reference) | 2, 4 | Schema + read-order define output contract |
| 11–12 (design-spec contract) | 1, 2 | Verification Contract fields must align with brief-schemas |
| 13–18 (coordinator + consumers) | 1, 5, 10 | Handoff flags and chain order must match skill behavior |
| 19–20 (reviewer + visual QA ref) | 2, 9 | 0k consumes visual-qa schema; build-test-visual-qa rules reference standards |
| 21–23 (manifest + roster) | 10 | Skill must exist before manifest registration |
| 24–28 (test-strategy, dogfood) | 2–23 | End-to-end validation |

**External dependency:** `plugin-figma-figma` MCP for `get_screenshot` at fidelity gate; target Android project capture infra (Paparazzi or Compose Preview Screenshot Testing) for P1 — architect inventories in Task 1.

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| `MAX_CHAIN_AGENTS` (12) with mas-figma + visual-fidelity + P1 trio | Protected slots stack; user escalation frequency rises | Both protected-when-triggered; document Option 6 fallback; never silent skip in full `/mas` |
| No screenshot infra in target Android repo | P1 BLOCKED; reviewer 0k FAIL without artifacts | HITL in brief; test-strategy recommends infra setup; P0 measurement may still run from layout metrics |
| Font rendering variance (JVM vs device) | False P0 blockers on typography | D4: 2px dimensions only; color/token zero tolerance; `minor` for subpixel dimension drift |
| MCP unreachable at fidelity gate | Stale Figma baseline | Trust committed PNG ≤ 7d; flag in Open Questions; optional `RE_EXTRACT` for token refresh (separate mas-figma spawn) |
| Dev re-maps tokens despite spec | Layout looks right but tokens wrong | P0 measurement diff catches token table drift; routes to dev |
| Commercial tool temptation (Applitools/SmartUI) | Vendor lock-in | Adapt brief shape only; no SDK in v1 (architect confirms) |
| Conflating extraction + verification in design-spec | Idempotency breaks; RE_EXTRACT conflicts | Immutable/mutable separation enforced in tasks 2, 11, 12 |
| Lite users assume fidelity verified | False confidence | Explicit skip warning in coordinator summary |

## Build & Test Plan

**Gradle / compile:** N/A — `UI_SCOPE: logic-only`; no Android modules touched in MAS framework repo.

**Verification surfaces:**

| Surface | Command / action | Owner |
|---------|------------------|-------|
| Manifest JSON validity | Parse `install/manifest.json` after edit | general-dev |
| Protocol cross-links | Grep `mas-visual-fidelity`, `visual-qa`, `VISUAL_FIDELITY`, `0k` across protocol files | reviewer |
| Schema compliance | Synthetic visual-qa brief vs `brief-schemas.md` headings | reviewer |
| design-spec contract | Verification Contract fields in fixture stub | reviewer |
| Chain dogfood | `/mas` with design-spec + `UI_CHANGES: YES` on `MAS-06-VFID-DOGFOOD` | test-strategy → reviewer |
| Lite skip | `/mas-lite` without `VFID:y` when design-spec exists — warn present | reviewer |
| Iteration loop | Simulated P0 blocker → dev → `RE_VERIFY` → pass | coordinator dogfood |

**test-strategy agent:** Task 24 — fixture TASK_ID, trigger/skip matrix, P0 iteration cases, MCP-blocked baseline fallback.

**Target Android project (dogfood consumer, not MAS repo):** When dogfood includes real impl, test-strategy should specify:

```bash
./gradlew :<module>:validateDebugScreenshotTest
# or
./gradlew :<module>:verifyPaparazziDebug
```

Architect selects module/command in Task 1 based on dogfood repo inventory.

## Visual QA Scenarios

N/A — `UI_SCOPE: logic-only` for MAS framework changes. The `visual-qa` brief *describes* viewport/capture/diff data shapes only.

**Reviewer dogfood imagination (protocol validation only):**

| Config | State | Expected gate |
|--------|-------|---------------|
| design-spec present, no visual-qa brief | default | Layout/Typography/Color/Spacing → N/A; cannot `Approved: YES` on Figma UI |
| visual-qa with P0 blocker | default | 0k FAIL → `Approved: NO` |
| visual-qa PASS, P1 PARTIAL | default | 0k PASS with Major note on regions |
| `UI_CHANGES: NO` | — | visual-fidelity skipped; 0k N/A |
| Lite mode | default | spawn skipped; coordinator warns |

## Required Agents

| Agent | When | Scope |
|-------|------|-------|
| **architect** | Task 1 — before protocol edits | Topology, capture contract, chain ordering, D1–D5 confirmation, Option 6 fallback gate, semver |
| **test-strategy** | Task 24 — after architect, parallel with Phase 2–5 | Fixture TASK_ID, chain permutation matrix, capture command fixtures, iteration cases |
| **general-dev** | Tasks 2–23 | Protocol files, `mas-visual-fidelity` skill, standards ref, coordinator/reviewer/dev consumer edits, mas-figma contract slice, manifest |
| **documenter** | Task 26 — after routing + manifest | README, multi-agent-system SKILL roster, Lite warning text |
| **reviewer** | Tasks 27–28 — after dogfood | Schema compliance, 0k gate, mutual-exclusion regression, no-code-patch invariant |

**Not required for MAS-06:** android-dev in MAS repo (no Compose impl here); ux-intelligence/a11y/i18n unless dogfooding ordering; security-auditor; api-contract; commit (unless user opts in post-approval).

## Acceptance criteria (workflow-level)

1. **Specialist delivery:** `mas-visual-fidelity` registered in manifest with complete skill stub and protocol touchpoints (brief-schemas, read-order, handoff-format, spawn-model-policy, subagent-spawn, token-rules).
2. **Deterministic routing:** Coordinator spawns only when predicate matches (`VISUAL_FIDELITY: yes` | auto + design-spec + `UI_CHANGES: YES`); suppression when `UI_CHANGES: NO`.
3. **Chain position:** After dev, before ux-intelligence; protected-when-triggered in full `/mas`.
4. **Idempotency:** Re-run overwrites `visual-qa/{TASK_ID}.md`; does not mutate design-spec extraction sections; `RE_VERIFY: yes` allows re-spawn.
5. **Artifact-forward:** Specialist return = one line + `BRIEF_PATH`; brief validates against `visual-qa` schema.
6. **Three-tier verification:** P0 structured measurement (deterministic gate); P1 screenshot pair; P2 subjective remains reviewer imagined.
7. **Reviewer consumer-only:** Step 0k validates visual-qa brief; no Figma MCP re-fetch at review; unresolved P0 blockers → `Approved: NO`.
8. **Imagined Visual QA downgrade:** When design-spec exists, layout/typography/color/spacing rows cannot PASS without visual-qa brief (`build-test-visual-qa.md`).
9. **Immutable extraction:** Verification Contract on design-spec is input-only; parity results live in visual-qa only.
10. **Gate preservation:** Reviewer remains sole `Approved:` authority; specialist never patches production code.
11. **Iteration discipline:** Max 2 dev↔fidelity loops before user escalation with P0 table attached.
12. **Lite parity:** Skip spawn + explicit "Figma fidelity unverified" warning.
13. **D1–D5 resolved:** Documented in plan and architecture brief; Option 6 fallback documented if chain cap blocks.

## Usage Report

Model: default
Class: normal
Tokens: unknown

DONE
