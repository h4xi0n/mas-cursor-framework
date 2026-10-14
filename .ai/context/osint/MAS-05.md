# OSINT Brief — MAS-05

## Research Mode

FEATURE

## Topic

How do Figma MCP tools and OSS agents extract screen layout (dimensions, positions, tokens, hierarchy) and hand design specs off to UI implementation agents — for a new `mas-figma` specialist feeding android-dev/general-dev?

## Scope

Figma MCP extraction tools (official + Cursor `plugin-figma-figma`), Cursor `figma-design-to-code` skill, OSS design-to-code multi-agent pipelines, Figma→Jetpack Compose toolchains, and MAS-style handoff of design specs to a downstream dev agent. Stack: MAS framework (Coordinator + on-disk brief artifact bus) driving an Android/Kotlin/Compose project.

## Research Summary

The industry has converged on a **two-phase "inspect-first, extract-second" MCP pattern**: a lightweight structural sweep (`get_metadata` → XML of node `id`/`name`/`type`/`x`/`y`/`width`/`height`/hierarchy) to build a node map without blowing the context window, then targeted deep extraction on chosen node IDs (`get_design_context` for layout+styles, `get_variable_defs` for tokens, `get_screenshot` for visual fidelity, `get_code_connect_map` for existing-component reuse). Every credible source treats the extracted code as a **reference, not final output** — it must be re-mapped to the project's real tokens/components/framework. Mature OSS pipelines (figma-code-composer, Builder.io, Semantic Kernel agent) split the work into **fetch → canonical spec manifest → coordinator (reuse/complexity routing) → builders**, with a knowledge graph to avoid rebuilding shared components. For Android specifically, Google **Relay** and community **figma-to-compose** MCPs map Figma styles → tokens → `MaterialTheme`/`CompositionLocal`, and import *metadata that describes how to generate* Compose (not ready-made composables). This maps almost 1:1 onto a MAS `mas-figma` **extraction/spec specialist** (read-only, no patches) that writes a design-spec brief consumed by android-dev/general-dev — analogous to how `ux-intelligence` feeds dev but with an artifact contract like `api-contract`/`architect`.

## Sources Consulted

| # | Source | Tier | Date | Version | Notes |
|---|--------|------|------|---------|-------|
| 1 | [Figma MCP — Tools and prompts](https://developers.figma.com/docs/figma-mcp-server/tools-and-prompts/) | official | 2026-08 | Dev Mode MCP | Authoritative tool list: get_design_context, get_metadata, get_variable_defs, get_screenshot, get_code_connect_map |
| 2 | [Figma MCP — Skill: Implement Design](https://developers.figma.com/docs/figma-mcp-server/skill-figma-implement-design/) | official | 2026-08 | — | Required flow + large-file chunking recipe; layout/typography/token/component data returned |
| 3 | [figma/mcp-server-guide (README + DeepWiki get_metadata/get_variable_defs)](https://github.com/figma/mcp-server-guide) | official | 2026-08 | — | Node property schema (id/name/type/x/y/w/h); local (127.0.0.1:3845) vs remote (mcp.figma.com) server split |
| 4 | Cursor `figma-design-to-code` SKILL (plugin-figma-figma, local) | official | 2026-08 | plugin cache | Hint priority order; asset-fidelity rules; "reference not final code" |
| 5 | [Builder.io — Multi-Agent Systems for Frontend](https://www.builder.io/m/explainers/multi-agent-system-for-frontend-development) | maintained OSS/vendor | 2026 | — | Perception/mapping/codegen/testing/a11y agent split + orchestration routing |
| 6 | [raveracker/figma-code-composer](https://github.com/raveracker/figma-code-composer) (+ [npm](https://www.npmjs.com/package/figma-code-composer)) | maintained OSS | 2026-06 | v1.2.0, MIT | fetcher→manifest→coordinator→builders; KG ledger reuse; complexity→model routing; handover files |
| 7 | [Google Relay — codelab](https://codelabs.developers.google.com/relay-complete-app) + [GDE writeups](https://medium.com/google-developer-experts/a-foray-into-relay-a95a899fb85f) | official | 2022→ | Relay | Figma→Compose; style→token→MaterialTheme JSON mapping; imports UI-Component metadata not composables |
| 8 | [Through-Reflection/figma-compose-mcp](https://github.com/Through-Reflection/figma-compose-mcp), [figma-to-compose-mcp (PyPI)](https://pypi.org/project/figma-to-compose-mcp/) | community | 2025–26 | — | Compose-targeted MCPs; get_node_info dims, get_local_variables/styles token extraction |
| 9 | [ayushya-patel/figma-to-code-agent](https://github.com/ayushya-patel/figma-to-code-agent), [AnithaKarre/semantic-kernel-agent](https://github.com/AnithaKarre/semantic-kernel-agent) | community | 2026 | — | 10-step Claude agent (detect stack→fetch→reconcile tokens→gen→validate); SK multi-provider + session isolation |

## Findings

| # | Source | Context | Pattern/Fix | Tradeoffs | Applicability | Recommendation | Confidence |
|---|--------|---------|-------------|-----------|---------------|----------------|------------|
| 1 | 1,2,3 | Large screens overflow the ~25k-token MCP context if you extract the whole frame | **Inspect-first two-phase extraction:** `get_metadata` (sparse XML: id/name/type/x/y/w/h + hierarchy) to map the tree, then `get_design_context` per chosen child node ID | Extra round-trips; agent must pick node IDs | Directly enforces MAS token-rules; keeps `mas-figma` bounded. `get_metadata` XML *is* the "dimensions/positions/hierarchy" the goal asks for | **adopt** | HIGH |
| 2 | 1,3,4,8 | Screenshot eyedropper → literal hex loses the design system | **Token-first extraction:** run `get_variable_defs` (colors/spacing/typography/sizing/radii) and record token *names*; map to project tokens, never raw hex/px | `get_variable_defs` is **local desktop-server only** — remote server can't return it | Core of the brief; Android maps to `MaterialTheme` colorScheme/typography/shapes + `CompositionLocal` for spacing | **adopt** | HIGH |
| 3 | 1,4,6 | Regenerating components that already exist in the repo | **Reuse-first via Code Connect:** `get_code_connect_map` (nodeId→code path) + scan repo before emitting new UI; KG ledger keyed on Figma `mainComponentId` (composer) | Requires Code Connect setup or a repo scan step; KG adds infra | Matches user rules ("reuse existing components before creating new") and MAS DRY intent; `mas-figma` should emit a reuse table, dev decides | **adapt** | HIGH |
| 4 | 2,3,4,5 | Raw MCP code is React+Tailwind; target is Kotlin/Compose | **Reference-not-final translation gate:** extracted code is a spec/reference; a downstream agent re-maps to real framework, tokens, components; validate 1:1 vs screenshot | Requires explicit "do not paste verbatim" contract or drift/hallucinated UI results | Perfect fit for MAS role split: `mas-figma` = spec (never patches); android-dev/general-dev = implementation | **adopt** | HIGH |
| 5 | 6,5,3 | Ad-hoc chat handoff loses structure between fetch and codegen | **Canonical spec manifest as the contract:** figma-fetcher writes one `manifest.json` (composer v1.2) all builders read; Builder.io shares a repo/DS/standards context bus | Schema design + versioning upkeep | 1:1 with MAS "artifact bus" — `mas-figma` writes `.ai/context/design-specs/{TASK_ID}.md` brief that android-dev reads at startup | **adopt** | HIGH |
| 6 | 7 | Figma→Compose needs stable theme, not one-off pixel values | **Relay style-mapping:** JSON with `figma` object (style→intermediate token) + `compose` object (token→theme ref); import *UI-Component metadata* that regenerates on redesign, keeping a link to the source node | Relay is a full plugin toolchain (Figma+Studio+Gradle plugins), heavier than an MCP read; but the *mapping model* is reusable | Adopt the **mapping model** (figma style → token → Compose theme) as the brief's token section; skip adopting Relay tooling itself | **adapt** | MEDIUM |
| 7 | 6,5 | One model/skill set for every screen wastes tokens or underperforms | **Complexity routing:** score node count/variants/depth/unbound values → tier → minimum viable model+skills (trivial→sm … extreme→2nd review pass) | Needs a scoring heuristic; risk of mis-tiering | Aligns with MAS `spawn-model-policy` MODEL_CLASS; Coordinator can set `mas-figma` class from a complexity flag in handoff | **adapt** | MEDIUM |
| 8 | 4,2 | Icons/images faked as inline SVG or placeholders | **Asset-faithful export:** every icon/image rendered from exported asset URL; download-and-commit (URLs expire ~7 days); explicit fixed-size square container | Asset URLs expire; commit step required | Brief must carry an asset manifest (node→asset URL→intended drawable/resource) for android-dev; never hand-draw vectors | **adopt** | HIGH |

## Recommended Approach

Add **`mas-figma`** as a **read-only design-spec extraction specialist** (never patches production code), positioned **pre-dev** in the chain and feeding **android-dev / general-dev** — the same feeder relationship `ux-intelligence` and `api-contract` have to dev, but producing a *design contract* rather than a review.

**Role boundary (extraction/spec, not implementation):**
- Reads Figma via the `plugin-figma-figma` MCP; writes a structured brief; routes findings to dev. No code patches, no routing, no `Approved:` authority (mirrors osint/api-contract invariants).

**Extraction protocol the skill should mandate (token-bounded, inspect-first):**
1. `get_metadata` on the target node → node map (id/name/type/x/y/w/h + hierarchy). This is the layout/dimensions/position/hierarchy backbone. If no `node-id` in URL, block and ask user (never guess).
2. `get_variable_defs` → design tokens (color/spacing/typography/sizing/radii) recorded by **name**. Note local-server requirement; degrade gracefully to raw values + flag if only remote server is available.
3. `get_design_context` **per chosen child node** (not the whole frame) → layout structure, auto-layout/constraints, typography, spacing, component/variant structure. Treat as *reference only*.
4. `get_code_connect_map` + repo scan → reuse table (Figma node → existing composable/theme token). Reuse over regenerate.
5. `get_screenshot` → visual reference for the dev's 1:1 validation and for the brief.
6. Asset manifest: node → exported asset URL → intended Android drawable/resource; flag ~7-day URL expiry so dev downloads-and-commits.

**Handoff contract (the artifact bus):**
- New brief type `design-spec` at `.ai/context/design-specs/{TASK_ID}.md`, registered in `brief-schemas.md`, `read-order.md` (android-dev/general-dev subscription), `spawn-model-policy.md`, and the coordinator predicate table. Suggested required sections: **Node Map**, **Design Tokens (→ MaterialTheme/CompositionLocal mapping)**, **Layout Spec**, **Component Reuse Table**, **Asset Manifest**, **Screenshot Reference**, **Open Questions / Ambiguities**.
- Android token mapping should follow the Relay model conceptually: Figma style/variable → intermediate token → `MaterialTheme.colorScheme/typography/shapes` (custom scales like spacing via `CompositionLocal`). Do **not** adopt Relay's plugin toolchain; adopt only the mapping shape.

**Routing / triggers (predicate, matching MAS-04 style):**
- Trigger flag e.g. `FIGMA_SPEC: yes` (full) / `FIG:y` (lite), or a Figma URL / `node-id` present in handoff `SOURCES_HINT`/`FILES`, or `SCOPE: ui-from-figma`.
- Default chain position: after architect/planner, before android-dev (design spec precedes implementation). When UI already exists and only friction/WCAG is in question, defer to ux-intelligence/a11y instead.
- `MODEL_CLASS`: default **normal**; escalate to **thinking** for high-complexity screens (composer-style complexity score in handoff). Extraction itself is mechanical; mapping/ambiguity resolution benefits from stronger reasoning on complex frames.

**Mutual exclusion (keep gates intact):**
- vs `ux-intelligence`: behavioral friction — not design extraction.
- vs `a11y`: WCAG conformance — not layout/token extraction (though `mas-figma` can surface contrast token values for a11y to consume).
- vs `architect`: system/module design — `mas-figma` only lints/extracts the visual contract, does not design architecture.
- vs android-dev/general-dev: spec only; dev owns the actual composables, state, and 1:1 validation.

## Recommended Fix Strategy

N/A — FEATURE mode.

## Priority Order

1. Finding #1 (inspect-first `get_metadata`→`get_design_context`) — bounds token cost; non-negotiable for MAS.
2. Finding #5 (canonical `design-spec` brief as artifact-bus contract) — the actual MAS integration surface.
3. Finding #4 (reference-not-final translation gate) — preserves the extraction-vs-implementation role split.
4. Finding #2 (token-first via `get_variable_defs`, note local-only) — design-system fidelity.
5. Finding #3 (reuse-first via Code Connect + repo scan) — DRY, matches project rules.
6. Findings #6/#8/#7 (Relay token-mapping model; asset-faithful manifest; complexity→model routing) — Android specialization + efficiency polish.

## Anti-Patterns Avoided

- **Whole-frame `get_design_context`** on multi-screen frames — burns the ~25k MCP context; use metadata-first chunking.
- **Screenshot eyedropper → literal hex/px** — bypasses the design system; extract token names.
- **Pasting MCP React+Tailwind verbatim** into a Compose project — hallucinated/wrong UI; re-map to real stack.
- **Hand-drawing icons / inline `<svg>` / placeholders** — always render exported assets.
- **Adopting a heavy plugin toolchain (Relay)** wholesale for what is a read-only MCP extraction need — adopt the mapping model only.
- **Unmaintained/low-signal community MCPs** treated as primary — figma-to-compose community servers are watch-list references, not the extraction backbone (the official Figma MCP + Cursor `plugin-figma-figma` is the source of truth).

## Implementation Guidance

- `mas-figma` is an **extraction/spec** agent: read-only, one brief per `TASK_ID`, chat return = one-line summary + `BRIEF_PATH` (specialist invariants from MAS-04).
- Skill must encode the ordered MCP recipe (metadata → variable_defs → per-node design_context → code_connect_map → screenshot → assets) and the "reference not final; adapt to Compose + project tokens" contract.
- Because Cursor's `figma-design-to-code` is a **mandatory prerequisite skill before `get_design_context`**, `mas-figma`'s workflow should load/honor it (or replicate its hint-priority order: Code Connect > component docs > annotations > tokens > raw hex).
- Add the `design-specs/` context dir (+ `.gitkeep`), brief schema, read-order subscription (android-dev/general-dev), spawn-model row, coordinator predicate + routing flag, and manifest version bump — same file-touch pattern MAS-04 used to add specialists.
- Degrade gracefully: MCP unreachable / no `node-id` / remote-only server (no `get_variable_defs`) → write brief with a Blocked/Open-Questions note and route to user HITL, do not fabricate coordinates or token names.
- Do **not** paste external OSS code (composer/SK-agent/Relay) into the skill or brief — describe patterns only.

## License / Copy Guardrails

- figma-code-composer: **MIT** — patterns (fetcher→manifest→coordinator→KG→handover, complexity routing) are safe to *adapt* conceptually; do not copy source files.
- Relay: Google toolkit — adopt the **style→token→theme mapping concept** only; do not vendor Relay code/plugins.
- Community Compose MCPs (figma-to-compose, figma-compose-mcp): reference for tool surface ideas only; not maintained enough to depend on — no code copy.
- Official Figma MCP tool names/behaviors are API surface, not copyrightable implementation — safe to reference by name.

## Regression Notes

N/A — FEATURE mode.

## Local Files Referenced

- `.ai/handoffs/MAS-05.md`
- `.ai/context/memory.md`
- `.ai/context/architecture/MAS-04.md` (specialist-addition file-touch pattern, artifact bus, predicate routing, spawn-model policy)
- `skills/mas-ux-intelligence/SKILL.md` (feeder-to-dev role model, brief/mutual-exclusion structure)
- `skills/mas-a11y/SKILL.md` (advisory read-only specialist template)
- Cursor `figma-design-to-code` SKILL (plugin-figma-figma cache) — mandatory prereq + hint priority

## Open Questions

- Which MCP transport will the project use — **local desktop** (needed for `get_variable_defs`) or **remote** (`mcp.figma.com`, no variable_defs)? Determines the token-extraction step's reliability.
- Is **Code Connect** configured in the Android repo (for `get_code_connect_map`), or must `mas-figma` rely on a repo scan for reuse hints?
- Should `mas-figma` run **before or after** architect for greenfield UI (spec-then-architect vs architect-then-spec)? Recommend before android-dev, after architect — brainstorm/architect to confirm.
- Does the project want a **knowledge-graph/reuse ledger** (composer-style) for cross-screen component reuse, or is per-task reuse table sufficient for v1? Recommend per-task table for v1.
- `MODEL_CLASS` default: confirm **normal** with **thinking** escalation on complex frames via a complexity flag.

## Overall Confidence

**HIGH** — The extraction mechanics are confirmed by official Figma docs and Cursor's first-party skill; the multi-agent handoff patterns are corroborated across multiple maintained OSS pipelines and a vendor (Builder.io); the Android/Compose token-mapping model is confirmed by Google Relay. Web/search tools were available and returned consistent, cross-verified results. Medium-confidence items (Relay mapping adoption depth, complexity routing) are flagged for brainstorm/architect validation.

## Usage Report

Model: default
Class: thinking
Tokens: unknown
