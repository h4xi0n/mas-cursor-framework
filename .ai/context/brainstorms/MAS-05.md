# Brainstorm Brief — MAS-05

## Problem & User Outcome

**Problem:** MAS routes UI work to `android-dev`/`general-dev` with no structured design contract. When a Figma screen is the source of truth, dev either (a) eyeballs a screenshot and hallucinates dimensions/tokens, or (b) pastes raw MCP React+Tailwind output into a Kotlin/Compose project. Both bypass the design system, waste the ~25k-token MCP context on whole-frame pulls, and produce drift. MAS has feeder specialists that precede dev (`api-contract`, `ux-intelligence`, `architect`) but none that turns a Figma node into a bounded, token-mapped, reuse-aware **design spec**.

**User outcome:** A `/mas` workflow given a Figma URL/`node-id` produces one on-disk **design-spec brief** — node map (dimensions/positions/hierarchy), design tokens mapped to `MaterialTheme`/`CompositionLocal`, per-node layout spec, a component-reuse table, an asset manifest, and a screenshot reference — that `android-dev`/`general-dev` reads at startup and implements 1:1, without the extraction agent ever patching code or holding an approval gate.

**UI scope:** `logic-only` (per handoff `UI_SCOPE: logic-only`). This task designs a **MAS protocol/skill specialist**, not a screen. In scope: MCP extraction data flow, brief schema/contracts, coordinator routing predicates, dev handoff contract, mutual-exclusion boundaries. The brief *describes what design data the spec carries* (dimensions, token names, layout structure as data fields) — it does **not** author Compose layouts, pixel values, or visual design. The downstream implementation UI is deferred to `android-dev`/`general-dev` via the design-spec brief.

**OSINT delta:** OSINT (`.ai/context/osint/MAS-05.md`) confirms the two-phase "inspect-first" MCP pattern, the "reference not final" translation gate, token-first extraction, reuse-first via Code Connect, and a canonical spec manifest as the artifact-bus contract — all HIGH confidence from official Figma docs + Cursor `figma-design-to-code` + maintained OSS pipelines + Google Relay. This brief operationalizes those findings into a concrete `mas-figma` skill contract, brief schema, and routing table. It does **not** re-research externally.

**Prior-art delta:** Follows the MAS-04 specialist-addition file-touch pattern (`brief-schemas.md`, `read-order.md`, `spawn-model-policy.md`, `install/manifest.json`, coordinator predicate table) and the `ux-intelligence`/`api-contract` feeder-to-dev role model (advisory, brief-only, no `Approved:` authority).

---

## Options

| # | Option | Pros | Cons | Risk | Effort | Fits memory? |
|---|--------|------|------|------|--------|--------------|
| 1 | **Dedicated read-only extraction specialist + new `design-spec` brief type** (OSINT-recommended). `mas-figma` runs pre-dev, feeds android-dev/general-dev via `.ai/context/design-specs/{TASK_ID}.md`. | Clean role split (extract vs implement); bounded token cost via inspect-first; mirrors MAS-04 `api-contract`/`ux-intelligence` feeder pattern; matches user rule "reuse existing components before creating new"; testable contract | One new skill + 6 protocol touchpoints; MCP transport/Code-Connect assumptions; another chain slot toward `MAX_CHAIN_AGENTS` | L | M | Y |
| 2 | **Fold Figma extraction into `architect`** — architect emits design spec as part of module design. | No new agent/brief type; fewer manifest edits | Violates mutual-exclusion (architect = system/module design, not visual extraction); `thinking`-class every time is token-costly for mechanical extraction; overloads architect scope | M | S | N |
| 3 | **Inline extraction inside `android-dev`/`general-dev`** — dev calls Figma MCP itself, no separate agent. | Zero routing/schema work; one fewer spawn | Whole-frame pulls blow dev's context (the exact anti-pattern OSINT flags); no reusable artifact; no separation of "spec" vs "implementation"; every dev run re-extracts | M | S | N |
| 4 | **Two-agent split — `figma-extractor` (raw pull) + `figma-mapper` (token/Compose mapping)**. | Maximal separation; each stage independently testable | Over-engineered for v1; double spawn cost; two briefs to keep in sync; premature for single-project use | M | L | N |
| 5 | **Extend `ux-intelligence` to also carry design specs.** | Reuses an existing UI-facing feeder | Blurs the MAS-04 boundary (ux = behavioral friction, *not* design extraction); mixes advisory-review output with a build contract | M | S | N |

**Fits existing patterns?** Option 1: Y — extends `brief-schemas.md`, `read-order.md`, `spawn-model-policy.md`, `handoff-format.md`, `install/manifest.json`, and coordinator predicate table exactly as MAS-04 did. Options 2–5: N — each collapses a boundary MAS-04 deliberately kept narrow.

---

## Recommended

**Option 1 — Dedicated read-only `mas-figma` extraction specialist with a new `design-spec` brief type.**

**Rationale vs alternatives:** Option 1 is the only choice that preserves the MAS-04 narrow-specialist invariant (audit/extract → brief → feed dev; never patch, never gate) while directly enforcing OSINT Finding #1 (inspect-first token bounding) and Finding #4 (reference-not-final role split). Option 2/5 collapse deliberate boundaries (architect = architecture; ux-intelligence = behavior) and pay `thinking`/review cost for mechanical extraction. Option 3 reproduces the exact whole-frame anti-pattern OSINT ranks #1 to avoid and yields no reusable artifact. Option 4 is the right *eventual* shape but premature; a single `mas-figma` skill can internally sequence extract→map and be split later if cross-screen volume justifies it.

**Boundary (extraction/spec, not implementation):** `mas-figma` reads Figma via the `plugin-figma-figma` MCP, writes one design-spec brief per `TASK_ID`, and returns a one-line summary + `BRIEF_PATH`. It never patches production code, never routes workflows, and holds no `Approved:` authority — identical invariants to `osint`/`api-contract`.

---

## Logic Flow

### A. Extraction pipeline (token-bounded, inspect-first) — the MCP recipe the skill mandates

Ordered stages; each stage's output is a **data record in the brief**, not code. Honor Cursor's `figma-design-to-code` skill as a **mandatory prerequisite before `get_design_context`** (or replicate its hint-priority order: Code Connect > component docs > annotations > variables/tokens > raw hex).

1. **Resolve target.** Parse `node-id` from the handoff `SOURCES_HINT`/`FILES` Figma URL. **If no `node-id` → Blocked** (write brief with Open-Questions + HITL note; never guess a node).
2. **Structural sweep — `get_metadata`** on the target node → sparse node map (`id`, `name`, `type`, `x`, `y`, `width`, `height`, hierarchy). This *is* the dimensions/positions/hierarchy backbone. Keeps context small; no whole-frame `get_design_context`.
3. **Token extraction — `get_variable_defs`** → colors/spacing/typography/sizing/radii recorded **by token name**. Note the **local-desktop-server requirement**; if only the remote server (`mcp.figma.com`) is available, degrade gracefully: record raw values + flag "tokens unresolved — local MCP needed."
4. **Targeted deep extraction — `get_design_context` per chosen child node** (never the whole frame) → layout structure, auto-layout/constraints, typography, spacing, variant structure. Treat strictly as **reference, not final code**.
5. **Reuse pass — `get_code_connect_map` + repo scan** → reuse table mapping Figma node/`mainComponentId` → existing Compose composable or theme token. Reuse over regenerate (per-task table for v1; no knowledge-graph ledger yet).
6. **Visual reference — `get_screenshot`** → saved image path for the dev's 1:1 validation and embedded in the brief.
7. **Asset manifest** — each icon/image node → exported asset URL → intended Android drawable/resource; flag ~7-day URL expiry so dev **downloads-and-commits** (never hand-draws vectors / inline SVG).
8. **Write brief** to `.ai/context/design-specs/{TASK_ID}.md`; return one-line summary + `BRIEF_PATH`.

### B. Coordinator routing (deterministic, zero-token predicate)

1. Coordinator inspects handoff for the trigger predicate (below) before dev.
2. First-match wins; max one `mas-figma` spawn per `TASK_ID` unless `RE_EXTRACT: yes`.
3. Coordinator writes `mas-figma` handoff with `SOURCES_HINT` (Figma URL/node-id), `MODEL_CLASS`, `BRIEF_PATH` refs to upstream architect/plan briefs, `SPAWN_STATUS: spawned`.
4. `mas-figma` runs pipeline (A) → writes design-spec brief.
5. Coordinator chains to `android-dev`/`general-dev`, which read the design-spec brief at startup (subscription matrix).
6. Dev implements against the spec, validates 1:1 vs the screenshot reference; `reviewer` remains the sole `Approved:` gate.

**Trigger predicate table (handoff extension):**

| Flag (full `/mas`) | Lite | Fires when |
|--------------------|------|-----------|
| `FIGMA_SPEC: yes` | `FIG:y` | Explicit request, **or** Figma URL/`node-id` present in `SOURCES_HINT`/`FILES`, **or** `SCOPE: ui-from-figma` |

**Chain position:** after `architect`/`planner`, **before** `android-dev`/`general-dev` (design spec precedes implementation). When UI already exists and only behavioral friction or WCAG is in question, defer to `ux-intelligence`/`a11y` — do **not** trigger `mas-figma`.

### C. Chain shape — UI-from-Figma feature (full `/mas`)

```
Coordinator → osint → brainstorm → planner → architect
  → mas-figma (if FIGMA_SPEC: yes | Figma URL/node-id in SOURCES_HINT | SCOPE: ui-from-figma)
  → android-dev | general-dev   (reads design-specs/{TASK_ID}.md at startup)
  → [ux-intelligence → a11y → i18n per MAS-04 predicates]
  → documenter → reviewer → commit
```

### D. Degrade-gracefully paths (never fabricate)

| Failure | Handling |
|---------|----------|
| No `node-id` in handoff | Block: brief with Open-Questions + HITL; do not guess coordinates |
| MCP unreachable | Brief with Blocked note; route to user HITL; no invented layout |
| Remote-only server (no `get_variable_defs`) | Record raw values + flag "tokens unresolved (local MCP required)"; continue with node map + screenshot |
| No Code Connect configured | Fall back to repo scan for reuse hints; mark reuse table entries "scan-inferred (unverified)" |
| Asset URL expired | Flag in asset manifest; instruct dev to re-export before commit |

---

## Domain & Contracts

### 1. New brief type — `design-spec` (register in `brief-schemas.md`)

| Type | Path pattern | Required sections |
|------|--------------|-------------------|
| design-spec | `.ai/context/design-specs/{TASK_ID}.md` | Node Map, Design Tokens, Layout Spec, Component Reuse Table, Asset Manifest, Screenshot Reference, Open Questions |

**Section field contracts (data shapes — no Compose layout authored here):**

- **Node Map** — table: `node-id | name | type | x | y | width | height | parent-id`. The structural/positional backbone from `get_metadata`.
- **Design Tokens** — table: `figma token name | category (color/spacing/typography/sizing/radius) | raw value | → intended MaterialTheme/CompositionLocal ref`. Follows the Relay mapping *model* (figma style → intermediate token → `MaterialTheme.colorScheme/typography/shapes`; custom scales e.g. spacing via `CompositionLocal`). Adopt the mapping shape only — **not** Relay's plugin toolchain.
- **Layout Spec** — per chosen node: auto-layout direction, constraints, spacing, typography, variant structure (from `get_design_context`, marked "reference").
- **Component Reuse Table** — `figma node/mainComponentId | existing composable or theme token | source (code-connect | repo-scan) | reuse | regenerate`.
- **Asset Manifest** — `node-id | asset type (icon/image) | exported URL | intended drawable/resource | expiry flag`.
- **Screenshot Reference** — saved image path + node-id for dev 1:1 validation.
- **Open Questions** — ambiguities, blocked steps, transport/token-resolution flags.

### 2. Protocol touchpoints (MAS-04 file-touch pattern)

| File | Edit |
|------|------|
| `install/manifest.json` | Register `mas-figma` skill; version bump |
| `brief-schemas.md` | Add `design-spec` row |
| `read-order.md` subscription matrix | `mas-figma` reads: osint, architecture, plans, handoff `SOURCES_HINT`. android-dev/general-dev **add** `design-specs/{TASK_ID}.md` to their startup reads |
| `spawn-model-policy.md` | Add `mas-figma` → default `MODEL_CLASS: normal` (escalate `thinking` on complex frames) |
| `handoff-format.md` | Document `FIGMA_SPEC`/`FIG:y`, `SOURCES_HINT` (Figma URL/node-id), `RE_EXTRACT` |
| `mas-coordinator/SKILL.md` | Add predicate row + chain position (after architect, before dev) |
| `.ai/context/design-specs/.gitkeep` | New context dir |
| `skills/mas-figma/SKILL.md` | New skill: ordered MCP recipe + reference-not-final contract + degrade paths |

### 3. Specialist invariants (inherited, all must hold)

- Read-only extraction; **never** patches production source.
- One design-spec brief per `TASK_ID`; chat return = one-line summary + `BRIEF_PATH`.
- Never spawns Task subagents; never routes workflows.
- No `Approved:` authority — `reviewer` remains the sole gate; dev owns composables/state/1:1 validation.
- Honors Cursor `figma-design-to-code` skill as mandatory prereq before `get_design_context`.

### 4. Mutual exclusion (keep gates intact)

| vs | Boundary |
|----|----------|
| `ux-intelligence` | Behavioral friction — **not** design extraction |
| `a11y` | WCAG conformance — **not** layout/token extraction (mas-figma may surface contrast token *values* for a11y to consume) |
| `architect` | System/module design — mas-figma extracts the visual contract only, designs no architecture |
| `android-dev`/`general-dev` | Spec only; dev owns composables, state, and 1:1 validation |

### 5. MODEL_CLASS

Default **normal** (extraction is mechanical). Escalate to **thinking** for high-complexity frames (composer-style complexity score: node count / variant depth / unbound values) set via a handoff flag. `fast` is a candidate only for trivial single-node pulls — recommend leaving default at `normal` for v1.

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Figma URL has no `node-id` | Block + HITL; never guess a node |
| Multi-screen frame requested | Inspect-first `get_metadata` only; deep-extract per child node — never whole-frame `get_design_context` |
| Remote MCP server only | Skip/flag `get_variable_defs`; record raw values + "local MCP required" |
| Design has no Figma variables (raw hex/px) | Record raw values, flag "no design tokens defined"; recommend dev not hardcode — map to nearest project token |
| Component exists in repo already | Reuse table marks `reuse`; dev must not regenerate (matches user rule) |
| Icon/image node | Asset manifest entry with exported URL; never inline SVG / hand-draw |
| Asset URL expired (~7 days) | Flag for dev re-export before commit |
| UI already implemented, only friction/WCAG in question | Do not trigger mas-figma; route ux-intelligence/a11y |
| Re-run on same TASK_ID | Blocked unless `RE_EXTRACT: yes` (idempotency) |
| Lite mode | Short-form brief; `FIG:y` flag; still inspect-first |

---

## Quality Bar

- **Token-bounded:** inspect-first is non-negotiable; whole-frame `get_design_context` is forbidden (OSINT anti-pattern #1).
- **Design-system fidelity:** tokens recorded by *name* and mapped to `MaterialTheme`/`CompositionLocal`; no screenshot-eyedropper hex.
- **Reference-not-final:** extracted code is a spec; dev re-maps to Compose + project tokens and validates 1:1 vs screenshot.
- **Reuse-first / DRY:** reuse table precedes any regenerate recommendation (aligns with user rules + MAS DRY intent).
- **Asset-faithful:** every icon/image from an exported asset; no hand-drawn vectors.
- **Deterministic routing:** zero-token predicate; max one spawn per TASK_ID unless `RE_EXTRACT`.
- **Artifact-forward:** chat = one line + `BRIEF_PATH`; brief body never inlined.
- **Fail-safe:** MCP/transport/node-id failures produce a Blocked/Open-Questions brief + HITL, never fabricated coordinates or token names.
- **No external code copy:** describe OSS patterns (composer/SK-agent/Relay) only; do not vendor their source.
- **Schema validation:** reviewer flags missing required design-spec sections per `brief-schemas.md`.

---

## Risks & Open Questions

| Risk / Question | Impact | Planner/Architect decision |
|-----------------|--------|---------------------------|
| MCP transport: local desktop vs remote `mcp.figma.com` | `get_variable_defs` (tokens) only on local | Document requirement; degrade gracefully to raw values + flag when remote-only |
| Code Connect configured in the Android repo? | Reuse-table reliability | If not, repo-scan fallback marked "unverified"; architect to confirm |
| mas-figma before or after `architect` for greenfield UI? | Chain ordering | Recommend after architect, before dev (spec informs implementation, architecture informs spec scope) |
| Knowledge-graph reuse ledger vs per-task table | Cross-screen reuse fidelity vs infra cost | Recommend per-task table for v1; revisit if multi-screen volume grows |
| `MODEL_CLASS` default | Token cost vs mapping quality | Recommend `normal` default, `thinking` escalation on complex frames via flag |
| Complexity-score heuristic | Mis-tiering risk | Optional v1; simple node-count threshold; refine later |
| Chain-count toward `MAX_CHAIN_AGENTS` | Cap pressure on full UI chains | mas-figma is skippable in Lite; document priority order |
| `plugin-figma-figma` tool descriptors not cached locally | Skill must not hardcode tool schema that could drift | Skill references tool names + honors `figma-design-to-code` prereq; verify tool surface at install |

---

## Suggested Next

**planner** — Break Option 1 into install tasks: `mas-figma/SKILL.md` stub (ordered MCP recipe + reference-not-final contract + degrade paths), `design-spec` schema row, `read-order.md` subscription (mas-figma reads + android-dev/general-dev design-spec subscription), `spawn-model-policy.md` row, `handoff-format.md` `FIGMA_SPEC`/`SOURCES_HINT`/`RE_EXTRACT` fields, coordinator predicate + chain position, `install/manifest.json` entry + version bump, `.ai/context/design-specs/.gitkeep`, and a mutual-exclusion regression checklist (vs ux-intelligence/a11y/architect/dev). Architect to confirm MCP transport + Code Connect assumptions and the architect-vs-figma ordering.

## Brief File

.ai/context/brainstorms/MAS-05.md

## Usage Report

Model: default
Class: thinking
Tokens: unknown

DONE
