# Brainstorm Brief — MAS-06

## Problem & User Outcome

**Problem:** MAS v1.3.0 closes the **pre-dev** Figma gap (`mas-figma` → `design-spec`) but leaves the **post-dev** fidelity gap open. After `android-dev`/`general-dev` implements from the spec, `reviewer` runs **imagined** Visual QA (`build-test-visual-qa.md`) — mentally rendering Compose trees with no Figma baseline comparison, no implementation screenshots, and no measured token/layout deltas. Dev self-attests 1:1 fidelity against the design-spec Screenshot Reference; drift in spacing, typography, and theme token mapping is undetectable at the gate. This is the exact anti-pattern OSINT flags: approval without verifiable visual evidence when a design contract exists.

**User outcome:** A `/mas` workflow with `design-specs/{TASK_ID}.md` produces **artifact-backed design fidelity evidence** before reviewer approval — structured measurement deltas (P0), paired screenshot baselines (P1), and a dedicated brief the reviewer consumes (like `a11y-reviews` / `test-runs`) — so Figma-driven UI cannot pass review on imagination alone.

**UI scope:** `logic-only` (per handoff). This task designs **MAS protocol/skill contracts** — capture recipes, brief schemas, coordinator predicates, reviewer verification steps, iteration loops. It describes *what fidelity data* flows (viewport metadata, delta tables, capture paths) — not Compose layouts, pixel styling, or screen design.

**OSINT delta:** OSINT (`.ai/context/osint/MAS-06.md`) converges on artifact-mandatory gates (HIGH), measurement-first diff over LLM screenshot eyeballing (HIGH), dedicated post-dev specialist slot mirroring Lane C evidence-before-judgment (HIGH), and Compose Preview Screenshot Testing as Android-native baseline storage (MEDIUM). This brief operationalizes those findings into four evaluated options and a composite recommendation. Does **not** re-research externally.

**Prior-art delta:** MAS-05 shipped `mas-figma` + `design-spec` and explicitly deferred downstream visual QA. MAS-04 established the advisory specialist pattern (brief-only, no `Approved:`, reviewer consumes). MAS-06 closes the deferred hole using the same file-touch pattern (`brief-schemas.md`, `read-order.md`, `handoff-format.md`, `spawn-model-policy.md`, `install/manifest.json`, coordinator predicates).

---

## Options

| # | Option | Pros | Cons | Risk | Effort | Fits memory? |
|---|--------|------|------|------|--------|--------------|
| 1 | **Extend `mas-figma` with post-dev fidelity mode** — same specialist, new handoff flag (`FIDELITY_PASS: yes` / `RE_VERIFY: yes`); re-reads design-spec, optionally re-invokes `get_screenshot`, captures implementation, emits measurement + screenshot diff into design-spec or appended section | Single Figma MCP owner; pre/post symmetry in one skill; no new manifest entry; reuses node-id + Screenshot Reference from extraction | Violates narrow-specialist invariant (extract ≠ verify); skill bloat; coordinator must distinguish pre-dev vs post-dev spawn (two visits per TASK_ID); mixes immutable extraction artifact with mutable verification output; protected-when-triggered policy harder to reason about | M | M | N |
| 2 | **New `mas-visual-fidelity` specialist** — read-only post-dev auditor; consumes `design-specs/{TASK_ID}.md`; writes `.ai/context/visual-qa/{TASK_ID}.md`; may call Figma MCP for fresh `get_screenshot` only (not `get_design_context`); runs measurement diff + optional pixel compare; no `Approved:` authority | Clean MAS-04 boundary (objective evidence → reviewer judgment); mirrors `mas-figma` pre/post symmetry without conflating roles; Lane C ordering; reviewer step 0k consumes brief like a11y/osint; protect-when-triggered predicate possible | +1 chain slot toward `MAX_CHAIN_AGENTS` (12); new skill + 6 protocol touchpoints; requires capture tooling contract (Compose preview / emulator / Paparazzi); Android platform variance (fonts, density) | L | M | Y |
| 3 | **Extend `reviewer` to perform fidelity verification** — reviewer captures screenshots, diffs tokens, optionally calls Figma MCP; imagined Visual QA rows become artifact-backed when design-spec exists | Zero new agents; no chain cap pressure; single gate | Reviewer already overloaded (0a–0j + build + tests + imagined QA); mixes objective measurement production with subjective `Approved:` judgment; violates MAS-04 "specialists produce evidence, reviewer gates" split; Figma MCP in reviewer expands token cost at approval time; harder to route P0 failures back to dev without reviewer-as-fixer confusion | H | S | N |
| 4 | **Enhance `design-spec` schema only** — add required `Verification Contract` section (viewport, capture recipe, tolerance policy, baseline freshness rules, expected metric keys) + optional `Parity Record` template; dev/test-executor populate post-dev; reviewer validates schema presence | Strengthens the artifact bus without new agent; dev knows exactly what to measure; lowest routing complexity if paired with existing `test-executor`; backward-compatible as optional section until predicate fires | Schema alone does not enforce capture or diff — without an executor specialist, dev self-attestation persists; conflates immutable design intent (pre-dev) with mutable verification state (post-dev) in one file; re-extract idempotency (`RE_EXTRACT`) conflicts with appended parity rows; does not solve "who runs the diff" | M | S | Partial |
| 5 | **Composite: Option 2 + Option 4 + reviewer consumer extension (not producer)** — new `mas-visual-fidelity` + new `visual-qa` brief type; design-spec gains a slim **Verification Contract** slice (read-only inputs for fidelity agent); reviewer adds step **0k Design-Fidelity Verification** (schema + P0 delta gate only); `build-test-visual-qa.md` downgrades imagined rows to N/A when `visual-qa` brief exists | Best of specialist boundary + schema contract + zero reviewer scope creep; matches OSINT priority order; iteration loop (P0 fail → dev → re-run) clean; Lite mode can skip spawn with explicit warn | Highest initial file-touch count; still +1 agent; D2/D3/D4 open questions remain for planner/architect | L | M | Y |
| 6 | **v1 minimal: extend `mas-test-executor` instead of new agent** — visual-fidelity commands in test-strategy; executor runs Paparazzi/Compose screenshot validate + emits visual section in `test-runs/{TASK_ID}.md` | Reuses P0 chain slot; no new skill; aligns with Finding #5 Android screenshot testing | test-executor is run-only v1 — no Figma MCP, no measurement diff logic without skill expansion; blurs "test pass/fail" with "design parity"; weak Figma baseline re-fetch story | M | S | Partial |

**Fits existing patterns?** Options 2, 5, 6: Y — extend MAS-04 advisory specialist / test-run evidence model. Options 1, 3: N — collapse boundaries MAS-04/MAS-05 deliberately kept narrow.

---

## Recommended

**Option 5 — Composite: new `mas-visual-fidelity` specialist + new `visual-qa` brief type + slim `Verification Contract` on design-spec + reviewer step 0k as consumer-only.**

**Rationale vs alternatives:**

- **vs Option 1 (extend mas-figma):** Pre-dev extraction and post-dev verification have opposite data flows (Figma→brief vs impl→diff→brief). Co-locating them recreates the architect/ux-intelligence overload anti-pattern MAS-05 rejected. Keep `mas-figma` immutable per `TASK_ID` unless `RE_EXTRACT: yes`.
- **vs Option 3 (extend reviewer):** Reviewer must remain the sole `Approved:` gate but not the measurement producer. MAS-04 dogfood confirmed advisory specialists + reviewer consumption works; reviewer producing fidelity artifacts would break mutual-exclusion and inflate approval-time tokens.
- **vs Option 4 (schema only):** Necessary but insufficient. A verification contract without a mandated executor reverts to dev self-attestation. Schema enhancement is a **component** of Option 5, not a standalone fix.
- **vs Option 6 (test-executor only):** Acceptable **v1.3.1 stepping stone** if chain cap blocks Option 5 immediately — but test-executor cannot own Figma re-baseline (`get_screenshot`) without violating its run-only scope expansion. Plan Option 5 as target; Option 6 as documented fallback in planner.

**v1 scope boundary:** Default state only (per OSINT D5). Interaction/hover/motion gaps remain P2 imagined reviewer rows.

---

## Logic Flow

### A. Three-tier verification (cheapest first — OSINT Finding #2)

| Tier | Name | Input | Output | Producer |
|------|------|-------|--------|----------|
| P0 | Token/layout measurement diff | design-spec Design Tokens + Node Map dimensions vs captured layout metrics | `property \| expected \| actual \| delta \| severity` table | `mas-visual-fidelity` |
| P1 | Screenshot pair compare | Figma baseline PNG vs implementation PNG at Verification Contract viewport | PASS/FAIL/PARTIAL + region summary | `mas-visual-fidelity` |
| P2 | Subjective polish | Gaps tiers 1–2 cannot catch (motion feel, micro-interaction) | Reviewer imagined rows (unchanged) | `reviewer` |

When `design-specs/{TASK_ID}.md` exists, reviewer **Layout / Typography / Color / Spacing** imagined rows → **N/A** unless `visual-qa/{TASK_ID}.md` artifacts present.

### B. Post-dev fidelity pipeline (`mas-visual-fidelity`)

1. **Predicate fire.** Coordinator: `VISUAL_FIDELITY: auto` when `design-specs/{TASK_ID}.md` exists AND dev handoff indicates UI changes (`UI_CHANGES: YES` or `FILES` touch Composables/resources). Lite: skip spawn + warn.
2. **Startup reads.** design-spec (all sections + Verification Contract), dev handoff `FILES`, test-strategy visual commands if any, architecture/plan slices for screen identity only.
3. **Baseline resolve.** Prefer fresh `get_screenshot` on design-spec node-id (re-baseline at review — OSINT Finding #3). Fallback: design-spec Screenshot Reference if handoff `BASELINE_STALE: no` or age `< N` days (planner sets N; default 7).
4. **Implementation capture.** Per Verification Contract recipe: Compose Preview Screenshot Testing (`@PreviewTest`), Paparazzi, or emulator `adb screencap` — match Node Map width/height + `fontScale` variants from contract.
5. **P0 measurement diff.** Diff token table + node dimensions against captured metrics (structured JSON + markdown table). No LLM spatial reasoning on raw images for P0 gate.
6. **P1 screenshot compare.** Pixel diff or layout summary; flag regions; tolerate 1–2px on dimensions only (OSINT D4 — colors/tokens zero tolerance).
7. **Write brief** to `.ai/context/visual-qa/{TASK_ID}.md`; return summary + `BRIEF_PATH`. On P0 failures → Coordinator routes to dev (max 2 iterations per MAS cap discipline).
8. **Mutual exclusion:** read-only; no production patches; no `Approved:`; does not call whole-frame `get_design_context`.

### C. Coordinator chain position (full `/mas`, Figma-driven UI)

```
… → mas-figma → android-dev | general-dev
  → mas-visual-fidelity (if VISUAL_FIDELITY: auto)
  → ux-intelligence → a11y → i18n → compliance (per predicates)
  → test-executor → documenter → reviewer
```

`mas-visual-fidelity` runs **after dev, before ux-intelligence** — objective layout parity before behavioral friction review. Protected-when-triggered (same policy as `mas-figma`).

### D. Reviewer consumption (Option 3 partial — consumer only)

New step **0k Design-Fidelity Verification** (after 0j Design-Spec Verification):

1. If no `design-spec` → 0k N/A.
2. If `design-spec` exists → require `visual-qa/{TASK_ID}.md` with schema sections (below).
3. P0 rows with `severity: blocker` unresolved → `Approved: NO` (Major minimum).
4. Reviewer does **not** re-call Figma MCP or re-capture — consumes fidelity brief only.

### E. Design-spec schema enhancement (Option 4 slice)

Add **optional until predicate fires; required when `FIGMA_SPEC` triggered** section to design-spec:

| Field | Purpose |
|-------|---------|
| `Verification Contract` | Viewport (w×h), density, `fontScale` variants, default state id |
| `Capture Recipe` | Command template (Paparazzi class, `@Preview` name, or emulator script) |
| `Baseline Policy` | `re-fetch` \| `trust-committed` + max age |
| `Tolerance` | Dimension px slack (default 2), color exact |
| `Metric Keys` | Which design-spec token rows participate in P0 diff |

**Do not** store mutable parity results in design-spec — those live in `visual-qa` brief only (immutable extraction vs mutable verification separation).

### F. Iteration loop

```
dev DONE → visual-fidelity → P0 blockers?
  yes → dev fix (handoff lists delta rows) → re-capture → visual-fidelity (iteration ≤ 2)
  no  → continue chain → reviewer 0k PASS → imagined P2 only
```

---

## Domain & Contracts

### 1. New brief type — `visual-qa` (register in `brief-schemas.md`)

| Type | Path pattern | Required sections |
|------|--------------|-------------------|
| visual-qa | `.ai/context/visual-qa/{TASK_ID}.md` | Viewport & State, Baseline Source, Implementation Capture, Measurement Diff, Screenshot Compare, Open Questions / Accepted Debt |

**Section data shapes (logic contracts, not UI):**

| Section | Fields |
|---------|--------|
| Viewport & State | `width`, `height`, `density`, `fontScale`, `uiMode`, `state-id` (default/loading/etc.) |
| Baseline Source | `source: figma-mcp \| design-spec-png`, `node-id`, `path`, `captured-at` |
| Implementation Capture | `path(s)`, `capture-method: paparazzi \| compose-preview \| emulator`, `git-revision` |
| Measurement Diff | `property \| expected \| actual \| delta \| severity(blocker\|major\|minor)` |
| Screenshot Compare | `result: PASS\|FAIL\|PARTIAL`, `regions[]`, `diff-artifact-path` |
| Open Questions / Accepted Debt | Class-C constraints with evidence only |

### 2. New specialist — `mas-visual-fidelity`

| Attribute | Value |
|-----------|-------|
| Role | Post-dev read-only design fidelity auditor |
| Authority | Advisory — no `Approved:`, no code patches |
| MCP scope | `get_screenshot` on design-spec node-id only; **forbidden:** `get_design_context`, whole-frame pulls |
| Brief output | `.ai/context/visual-qa/{TASK_ID}.md` |
| MODEL_CLASS | `normal`; escalate `thinking` when `FIGMA_COMPLEXITY: high` or multi-screen |

### 3. Coordinator handoff flags

| Flag (full `/mas`) | Lite | Fires when |
|--------------------|------|-----------|
| `VISUAL_FIDELITY: yes` | `VFID:y` | Explicit, **or** `VISUAL_FIDELITY: auto` predicate |
| `VISUAL_FIDELITY: auto` | — | `design-specs/{TASK_ID}.md` exists AND UI changes in dev handoff |

### 4. `build-test-visual-qa.md` contract change

| Condition | Visual QA behavior |
|-----------|-------------------|
| No design-spec | Imagined checklist (unchanged) |
| design-spec exists | Layout/Typography/Color/Spacing rows → N/A without visual-qa brief; P2 polish rows remain imagined |
| visual-qa brief exists | P0/P1 rows sourced from brief; reviewer 0k validates |

### 5. Android capture contract (for planner/dev tasks)

| Method | When | Notes |
|--------|------|-------|
| Compose Preview Screenshot Testing | Component/screen previews exist | Import Figma baseline PNG to `screenshotTest/reference/` per MAS-05 asset contract |
| Paparazzi | JVM-fast component tests | Preferred for CI; host-side font variance flagged in Open Questions |
| Emulator `adb screencap` | Integration-critical full screens | test-executor or visual-fidelity; higher cost |

### 6. Read-order subscription

| Agent | Reads |
|-------|-------|
| mas-visual-fidelity | design-specs, plans, dev handoff FILES, test-strategies (visual commands) |
| reviewer | visual-qa (step 0k), design-specs (step 0j) |
| android-dev | design-specs Verification Contract at startup (when present) |

---

## Edge Cases

| Case | Handling |
|------|----------|
| design-spec exists but dev declares `UI_CHANGES: NO` | Skip visual-fidelity spawn; reviewer 0k N/A |
| MCP unreachable at fidelity gate | visual-qa brief `BLOCKED` + trust committed baseline only if PNG exists; P0 measurement still runs; flag in Open Questions |
| No Compose preview / Paparazzi in target project | Degrade to emulator capture or `BLOCKED` with HITL; reviewer 0k FAIL without artifacts |
| Font rendering delta within 2px | P0 dimension rows `minor`; color/token mismatch → `blocker` |
| Design changed in Figma after extraction | Re-baseline via `get_screenshot` catches drift; optional `RE_EXTRACT: yes` for token table refresh (separate mas-figma spawn) |
| Multi-screen design-spec | One visual-qa brief per screen state OR sectioned brief; planner decides; complexity triggers `thinking` |
| Chain cap exceeded | Protected-when-triggered → user escalation (same as mas-figma); never silent skip in full `/mas` |
| Lite mode | Skip visual-fidelity; warn "Figma fidelity unverified" |
| Iteration cap (2) exceeded | Coordinator user escalation with unresolved P0 table attached |

---

## Quality Bar

- **Idempotency:** Re-running visual-fidelity overwrites `visual-qa/{TASK_ID}.md`; does not mutate design-spec extraction sections.
- **Evidence chain:** Reviewer `Approved: YES` on Figma UI requires visual-qa brief with non-empty Measurement Diff + Implementation Capture paths.
- **Determinism:** P0 gate is structured data diff — not LLM image comparison.
- **Security:** Screenshot paths stay in repo workspace; no PII in fidelity briefs.
- **Observability:** Coordinator session JSON: `visual_fidelity_spawned`, `p0_blockers`, `iteration_count`.
- **Tests:** Planner should task Paparazzi/Compose screenshot tests for stable screens; test-strategy aligns P1 commands with visual-qa capture recipe.
- **Lite parity:** Explicit fidelity skip warning in coordinator summary.

---

## Risks & Open Questions

| ID | Question | Owner | Default if unresolved |
|----|----------|-------|----------------------|
| D1 | `mas-visual-fidelity` vs extend `test-executor` for v1 | Planner | New specialist (Option 5); test-executor fallback documented |
| D2 | Target Android project screenshot infra (Paparazzi / Compose preview / CI emulator) | Architect + user | BLOCKED brief + HITL when missing |
| D3 | Baseline staleness: always re-fetch `get_screenshot` vs trust committed PNG | Planner | Re-fetch at fidelity gate; trust only when MCP blocked |
| D4 | Pixel tolerance policy | Planner | 2px dimensions only; zero on colors/tokens |
| D5 | v1 scope: default state only | Planner | Yes — interaction states P2 imagined |
| R1 | `MAX_CHAIN_AGENTS` pressure with mas-figma + visual-fidelity | Coordinator | Protected-when-triggered; user escalation |
| R2 | Dev re-maps tokens despite spec (root drift) | visual-fidelity P0 | Catches at measurement diff; routes to dev |
| R3 | Commercial tool temptation (Applitools/SmartUI) | Architect | Adapt brief shape only; no SDK dependency in v1 |

---

## Suggested Next

**planner** — break Option 5 into file-touch tasks (skill, brief-schemas, read-order, handoff-format, coordinator predicate, build-test-visual-qa, mas-reviewer 0k, install/manifest); resolve D1–D5; define v1.3.1 vs v1.4.0 phasing (Option 6 fallback if chain cap blocks).
