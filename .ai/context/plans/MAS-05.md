# Plan Brief — MAS-05

## Plan

Goal:
Implement **Option 1 — Dedicated read-only `mas-figma` extraction specialist with a new `design-spec` brief type** (per `.ai/context/brainstorms/MAS-05.md` Recommended and `.ai/context/osint/MAS-05.md` Recommended Approach): add one narrow specialist that turns a Figma URL/`node-id` into a bounded, token-mapped, reuse-aware design-spec brief at `.ai/context/design-specs/{TASK_ID}.md`, with deterministic Coordinator routing, protocol registration, and mutual-exclusion boundaries vs `architect`, `ux-intelligence`, `a11y`, and dev. **Logic-only** — no Compose screens, no production patches. `mas-figma` extracts and briefs only; `android-dev`/`general-dev` implement from the spec.

**NEXT_AGENT:** architect

Tasks:

### Phase 0 — Architect gate (pre-implementation)

1. **Architect confirms routing topology, transport assumptions, and chain ordering** — Validate predicate table, chain position (after `architect`/`planner`, before `android-dev`/`general-dev`), `MAX_CHAIN_AGENTS` impact, mutual-exclusion matrix vs `ux-intelligence`/`a11y`/`architect`/dev, and resolve open questions from brainstorm Risks table.
   - **Files:** `.ai/context/architecture/MAS-05.md` (new)
   - **Decisions required:**
     - MCP transport: local desktop (required for `get_variable_defs`) vs remote degrade path
     - Code Connect availability in target Android repo vs repo-scan-only reuse fallback
     - Greenfield UI: confirm **after architect, before dev** (not before architect)
     - v1 reuse model: per-task reuse table only (no knowledge-graph ledger)
     - `MODEL_CLASS`: default `normal`; `thinking` escalation via complexity flag on handoff
   - **Acceptance:** Architecture brief documents predicate table, chain slot, degrade-gracefully matrix, specialist invariants (read-only, no `Approved:`, no Task spawn), and references `design-spec` section contracts from brainstorm Domain & Contracts.

### Phase 1 — Protocol foundation

2. **Extend `brief-schemas.md`** — Register `design-spec` brief type.
   - **Files:** `skills/multi-agent-system/protocol/brief-schemas.md`
   - **Type:** `design-spec` → `.ai/context/design-specs/{TASK_ID}.md`
   - **Required sections:** Node Map, Design Tokens, Layout Spec, Component Reuse Table, Asset Manifest, Screenshot Reference, Open Questions
   - **Acceptance:** Registry row added; section field contracts referenced (not pasted); Reviewer validation guidance unchanged.

3. **Extend `spawn-model-policy.md`** — Add `mas-figma` MODEL_CLASS row.
   - **Files:** `skills/multi-agent-system/protocol/spawn-model-policy.md`
   - **Map:** `mas-figma` → default `normal`; escalate `thinking` when handoff complexity flag set (node count / variant depth / unbound values threshold — architect to set v1 heuristic)
   - **Acceptance:** Table row present; lite `MC:` cross-ref documented if applicable.

4. **Extend `read-order.md`** — Subscription matrix for `mas-figma` and downstream dev reads.
   - **Files:** `skills/multi-agent-system/protocol/read-order.md`
   - **mas-figma reads:** osint, architecture, plans for `{TASK_ID}`; handoff `SOURCES_HINT`/`FILES` (Figma URL/node-id)
   - **android-dev / general-dev add:** `.ai/context/design-specs/{TASK_ID}.md` at startup when present
   - **Acceptance:** Matrix complete; dev subscription conditional on brief existence.

5. **Extend `handoff-format.md` + lite format** — Document Figma routing fields.
   - **Files:** `skills/multi-agent-system/protocol/handoff-format.md`, `skills/multi-agent-system/protocol/handoff-format-lite.md`
   - **Flags:** `FIGMA_SPEC: yes` (full); lite `FIG:y`; `SOURCES_HINT` (Figma URL with `node-id`); `RE_EXTRACT: yes` (idempotent re-run); optional complexity flag for MODEL_CLASS escalation
   - **Triggers:** explicit flag **or** Figma URL/`node-id` in `SOURCES_HINT`/`FILES` **or** `SCOPE: ui-from-figma`
   - **Acceptance:** Flags documented; handoffs without flags remain valid; `node-id` requirement explicit.

6. **Extend `subagent-spawn.md`** — Register `mas-figma` slug with Task spawn template.
   - **Files:** `skills/multi-agent-system/protocol/subagent-spawn.md`
   - **Acceptance:** Slug row includes `mas-figma`; `run_in_background: false`; model resolution order unchanged.

7. **Create deliverable context directory** — Ensure design-spec brief path exists.
   - **Files:** `.ai/context/design-specs/.gitkeep`
   - **Acceptance:** Directory present; init/export scripts create it if project uses automation.

### Phase 2 — Skill stub (`mas-figma`)

8. **Create `skills/mas-figma/SKILL.md`** — Read-only Figma extraction specialist.
   - **Responsibilities:** Ordered MCP recipe (inspect-first, token-bounded); write `.ai/context/design-specs/{TASK_ID}.md`; return one-line summary + `BRIEF_PATH`
   - **MCP pipeline (mandate in skill):**
     1. Resolve `node-id` from handoff — **Blocked** if missing (never guess)
     2. `get_metadata` → Node Map backbone
     3. `get_variable_defs` → token names (note local-server requirement; degrade to raw values + flag if remote-only)
     4. `get_design_context` **per chosen child node** only (never whole frame) — reference not final code
     5. `get_code_connect_map` + repo scan → Component Reuse Table
     6. `get_screenshot` → Screenshot Reference
     7. Asset manifest with expiry flag (~7 days)
   - **Prerequisite:** Honor Cursor `figma-design-to-code` skill before `get_design_context` (hint priority: Code Connect > component docs > annotations > tokens > raw hex)
   - **Never:** patch production code; spawn Task; route workflows; issue `Approved:`
   - **Degrade paths:** MCP unreachable, no `node-id`, remote-only server, no Code Connect, expired asset URLs — write Blocked/Open Questions brief + HITL note; never fabricate coordinates or token names
   - **Token mapping contract:** Relay *model* only (figma style → intermediate token → `MaterialTheme.colorScheme/typography/shapes` + `CompositionLocal` for spacing) — no Relay plugin adoption
   - **Acceptance:** Startup reads handoff → skill → read-order → optional upstream BRIEF_PATH slices; output matches `design-spec` schema; lite short-form when `MODE: LITE`.

### Phase 3 — Coordinator routing + downstream consumers

9. **Update `mas-coordinator/SKILL.md`** — Add deterministic predicate row and chain position.
   - **Predicate:**

   | Flag / condition | Specialist | Chain position |
   |------------------|------------|----------------|
   | `FIGMA_SPEC: yes` OR Figma URL/`node-id` in `SOURCES_HINT`/`FILES` OR `SCOPE: ui-from-figma` | mas-figma | After architect/planner; **before** android-dev/general-dev |

   - **Rules:** First-match wins; max one `mas-figma` spawn per `TASK_ID` unless `RE_EXTRACT: yes`; skip when UI exists and only friction/WCAG needed (route `ux-intelligence`/`a11y` instead)
   - **Chain (UI-from-Figma, full `/mas`):** Coordinator → osint → brainstorm → planner → architect → **mas-figma** (if triggered) → android-dev|general-dev → [ux-intelligence → a11y → i18n per MAS-04 predicates] → documenter → reviewer → commit
   - **Acceptance:** Zero-token routing; handoff includes `SOURCES_HINT`, `MODEL_CLASS`, upstream `BRIEF_PATH` refs, `SPAWN_STATUS: spawned`.

10. **Update `mas-lite/SKILL.md`** — Register `mas-figma` in Lite tier table.
    - **Lite flag:** `FIG:y`; abbreviated handoff within 12-line cap; inspect-first recipe preserved
    - **Acceptance:** Lite S/M unchanged unless `FIG:y`; document skip under chain cap if `MAX_CHAIN_AGENTS` threatened.

11. **Update `android-dev` / `general-dev` skill stubs** (if separate startup read lists exist outside `read-order.md`) — Subscribe to `design-specs/{TASK_ID}.md`; treat extracted code as reference; validate 1:1 vs Screenshot Reference; download-and-commit assets per Asset Manifest.
    - **Files:** `skills/mas-android-dev/SKILL.md` and/or `skills/mas-general-dev/SKILL.md` (whichever exist in manifest)
    - **Acceptance:** Dev startup explicitly reads design-spec when present; "reference not final" contract stated.

12. **Update `mas-reviewer/SKILL.md`** — Conditional read step for design-spec brief.
    - **When:** `design-specs/{TASK_ID}.md` exists
    - **Verify:** Required sections per `brief-schemas.md`; flag missing Node Map / tokens / screenshot; note reuse-table gaps; do not re-extract
    - **Acceptance:** Reviewer remains sole `Approved:` gate; mas-figma findings are spec input only.

13. **Update `mas-ux-intelligence/SKILL.md` + `mas-a11y/SKILL.md`** — Mutual-exclusion cross-reference (one line each).
    - **Boundary:** mas-figma = layout/token extraction; ux-intelligence = behavioral friction; a11y = WCAG (may consume contrast token values from design-spec)
    - **Acceptance:** No routing overlap when only friction/WCAG in scope.

### Phase 4 — Install + manifest

14. **Update `install/manifest.json`** — Register `mas-figma` skill; version bump (recommend `1.3.1` or next minor per architect semver decision).
    - **Files:** `skills/multi-agent-system/install/manifest.json`
    - **Add:** `mas-figma`
    - **Acceptance:** `skills` array includes entry; export script copies skill tree.

15. **Update export/install scripts** — Include `mas-figma` in bundle if skill list is hardcoded.
    - **Files:** `skills/multi-agent-system/install/export-mas-framework.ps1` (if applicable)
    - **Acceptance:** Dry-run export includes `skills/mas-figma/`.

### Phase 5 — Test strategy, documentation, dogfood

16. **test-strategy brief** — Synthetic fixture TASK_ID with Figma URL/node-id stub; chain permutation matrix (mas-figma triggered vs skipped; degrade paths: no node-id, remote-only MCP, RE_EXTRACT).
    - **Files:** `.ai/context/test-strategies/MAS-05.md`
    - **Acceptance:** Documents expected spawn order, skip cases, and schema validation checkpoints for reviewer.

17. **Documenter pass** — README + `skills/multi-agent-system/SKILL.md` roster section.
    - **Content:** `mas-figma` role, `FIGMA_SPEC`/`FIG:y` flags, `design-specs/` path, chain position, local MCP requirement for tokens
    - **Acceptance:** User-facing docs list specialist and triggers; no inline brief examples in chat rules.

18. **Dogfood workflow** — Manual `/mas` run on synthetic `MAS-05-FIGMA-DOGFOOD` TASK_ID with `FIGMA_SPEC: yes` and stub `SOURCES_HINT` (or mock brief if MCP unavailable in CI).
    - **Acceptance:** mas-figma spawns once; brief written to `.ai/context/design-specs/{TASK_ID}.md`; dev handoff references `BRIEF_PATH`; no specialist patches code; mutual-exclusion vs ux-intelligence/a11y/architect verified; reviewer flags schema gaps on incomplete brief.

19. **Mutual-exclusion regression checklist** — Document in architecture or test-strategy brief.
    - **Cases:** UI-from-Figma triggers mas-figma not ux-intelligence; friction-only skips mas-figma; architect brief does not duplicate design-spec sections; dev does not call Figma MCP when design-spec exists
    - **Acceptance:** Checklist pass recorded in reviewer or test-run brief.

## Dependencies

| Task | Depends on | Reason |
|------|------------|--------|
| 2–7 (protocol foundation) | 1 (architect) | Routing order, transport degrade rules, MODEL_CLASS heuristic, semver bump |
| 8 (mas-figma skill) | 2, 4 | Schema + read-order define skill output contract |
| 9–13 (coordinator + consumers) | 1, 5, 8 | Predicate table and handoff fields must match skill behavior |
| 14–15 (manifest) | 8 | Skill must exist before manifest registration |
| 16 (test-strategy) | 1, 9 | Chain permutations need confirmed topology |
| 17 (documenter) | 9, 14 | Docs reflect final routing + manifest version |
| 18–19 (dogfood + regression) | 2–17 | End-to-end validation |

**External dependency:** `plugin-figma-figma` MCP available in Cursor workspace; local desktop server strongly preferred for `get_variable_defs`.

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Remote-only Figma MCP (no `get_variable_defs`) | Token names missing; design-system fidelity reduced | Degrade path in skill + brief Open Questions; architect documents local MCP as recommended |
| No Code Connect in Android repo | Reuse table entries unverified | Repo-scan fallback marked "scan-inferred (unverified)" |
| Whole-frame `get_design_context` temptation | ~25k context blow-up | Skill forbids; reviewer flags if Layout Spec appears monolithic |
| Asset URL expiry (~7 days) | Broken dev builds | Asset Manifest expiry flag; dev must download-and-commit |
| `MAX_CHAIN_AGENTS` pressure | mas-figma skipped on long chains | Document priority; skippable in Lite; optional overflow order (architect to align with MAS-04 skip table) |
| MCP tool schema drift | Skill references stale tool params | Skill references tool names + `figma-design-to-code` prereq; verify descriptors at install |
| Complexity-score mis-tiering | Wrong MODEL_CLASS | v1: simple node-count threshold; optional flag override |

## Build & Test Plan

**Gradle / compile:** N/A — `UI_SCOPE: logic-only`; no Android modules touched.

**Verification surfaces:**

| Surface | Command / action | Owner |
|---------|------------------|-------|
| Manifest JSON validity | Parse `install/manifest.json` after edit | general-dev |
| Protocol cross-links | Grep `mas-figma`, `design-spec`, `FIGMA_SPEC` across protocol files | reviewer |
| Schema compliance | Synthetic design-spec brief vs `brief-schemas.md` headings | reviewer |
| Chain dogfood | `/mas` with `FIGMA_SPEC: yes` + Figma stub | test-strategy → reviewer |
| Lite cap | `/mas-lite` with `FIG:y` within 12-line handoff | reviewer |

**test-strategy agent:** Task 16 — fixture TASK_ID, trigger/skip matrix, degrade-path cases (no node-id, remote MCP, RE_EXTRACT).

## Visual QA Scenarios

N/A — `UI_SCOPE: logic-only`. No Compose screens. Design-spec brief *describes* layout/token data shapes only; downstream Android visual QA is out of scope for MAS-05 (deferred to a future UI implementation workflow consuming the brief).

## Required Agents

| Agent | When | Scope |
|-------|------|-------|
| **architect** | Task 1 — before protocol edits | Routing topology, transport/Code Connect assumptions, chain ordering, MODEL_CLASS heuristic, mutual-exclusion matrix |
| **test-strategy** | Task 16 — after architect, parallel with Phase 2–3 | Fixture TASK_ID, chain permutation matrix, degrade-path test cases |
| **general-dev** | Tasks 2–15 | Protocol files, `mas-figma` skill, coordinator/reviewer/lite/dev consumer edits, manifest |
| **documenter** | Task 17 — after routing + manifest | README, multi-agent-system SKILL roster, local MCP note |
| **reviewer** | Tasks 18–19 — after dogfood | Schema compliance, mutual-exclusion regression, no-code-patch invariant |

**Not required for MAS-05:** android-dev (no Compose implementation), ux-intelligence/a11y/i18n (unless dogfooding exclusion cases), security-auditor, api-contract, perf-optimizer, commit (unless user opts in post-approval).

## Acceptance criteria (workflow-level)

1. **Single specialist delivery:** `mas-figma` registered in manifest with complete skill stub and protocol touchpoints (7 files per brainstorm Domain & Contracts §2).
2. **Deterministic routing:** Coordinator spawns `mas-figma` only when predicate matches (`FIGMA_SPEC: yes` | Figma URL/node-id | `SCOPE: ui-from-figma`); no LLM-based specialist selection.
3. **Chain position:** After architect/planner, before android-dev/general-dev; skipped when only friction/WCAG in scope.
4. **Idempotency:** Max one spawn per `TASK_ID` unless `RE_EXTRACT: yes`.
5. **Artifact-forward:** Specialist chat return = one line + `BRIEF_PATH`; brief validates against `design-spec` schema in `brief-schemas.md`.
6. **Inspect-first invariant:** Whole-frame `get_design_context` forbidden; Node Map from `get_metadata` is the positional backbone.
7. **Reference-not-final:** Extracted MCP code treated as spec reference; dev re-maps to Compose + project tokens.
8. **Gate preservation:** `reviewer` remains sole `Approved:` authority; `mas-figma` never patches production code.
9. **Mutual exclusion:** mas-figma vs ux-intelligence (behavior) / a11y (WCAG) / architect (system design) / dev (implementation) — boundaries enforced in skills.
10. **Degrade-safe:** MCP/node-id/transport failures produce Blocked/Open Questions brief + HITL; no fabricated layout or token names.
11. **Lite compatibility:** `FIG:y` flag works within lite handoff cap; inspect-first recipe preserved.
12. **No external code copy:** OSS patterns (composer, Relay, SK-agent) described only; no vendored source.

## Usage Report

Model: default
Class: normal
Tokens: unknown

DONE
