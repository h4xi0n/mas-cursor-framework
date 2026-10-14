---
name: mas-lite
description: Token-efficient MAS entry point. Use when the user types /mas-lite or wants orchestration below normal Opus token cost. Tiered pipelines S/M/L with minimal subagents and slim handoffs.
---

# MAS Lite

Low-token alternative to full `/mas`. Load [mas-coordinator](../mas-coordinator/SKILL.md) but **MAS Lite Mode overrides full `/mas` chains**.

## Activation

- User message starts with `/mas-lite` or `/mas lite`
- User asks for "mas lite", "low token", or "quick mas"

## Coordinator Rules (Lite)

1. Strip `/mas-lite` prefix; set `MODE: LITE` on every handoff.
2. Read **only** `.ai/context/memory.md` at startup (skip `project.md` / `coding_standards.md` unless implementation needs them — then read on demand).
3. **Daily changelog:** inherit [mas-coordinator](../mas-coordinator/SKILL.md) Startup ensure + After Reviewer append — `MODE: LITE` does **not** skip changelog.
4. **Workflow usage:** same init/record/finalize/cancel scripts as full `/mas` — `MODE: LITE` does **not** skip usage tracking; subagents omit `## Usage Report`.
5. **Token auditor:** skip by default after finalize — spawn only when user requests (full `/mas` may opt-in).
6. Use [handoff-format-lite.md](../multi-agent-system/protocol/handoff-format-lite.md) — not full handoff-format.md.
7. Use **lite subagent prompt** (below) — never `Read protocol/`.
8. Pick tier **S**, **M**, or **L** (auto-detect or user override).

## Tier Selection

| Tier | When | Chain | Subagents max |
|------|------|-------|---------------|
| **S** | Bug fix, crash, regression | `imaginer` → `bug-fix` (default), `osint` → `imaginer` \| `bug-fix` (difficult bug with prior art), `imaginer` only (`TRACE_ONLY`), `osint` only (`RESEARCH_ONLY`), or `bug-fix` only (trivial skip) | **2** |
| **S** | Perf symptom (jank, slow start, memory, battery) | `perf-optimizer` → `android-dev` \| `general-dev` (default), or `perf-optimizer` only (`ANALYZE_ONLY`) | **2** |
| **S** | Release / ship / production readiness | `release-readiness` → `android-dev` \| `general-dev` \| `bug-fix` (default), or `release-readiness` only (`RELEASE_ONLY`) | **2** |
| **S** | Typo, config tweak, obvious one-liner | `bug-fix` or `android-dev` / `general-dev` only | **1** |
| **S** | Explicit UX audit request | `ux-intelligence` only (`UX_ONLY: true`) — e.g. `/mas-lite S ux pass on onboarding` | **1** |
| **S** | Explicit test plan request | `test-strategy` only (`STRATEGY_ONLY: true`) — e.g. `/mas-lite S test strategy for export module` | **1** |
| **M** | Small feature, 3–8 files, clear scope | `dev` → `ux-intelligence` when `UI_CHANGES: YES`; else `dev` → `reviewer` (lite) | **2** |
| **L** | Medium feature, needs plan, no external docs | `planner` → `dev` → `ux-intelligence` when `UI_CHANGES: YES`; else `planner` → `dev` → `reviewer` (lite) | **3** |
| **L** | Medium feature + MAS-04 P0 flags (`SEC:y`, `API:y`, `DEPS:y`, `TEST:y`) or P1 flags (`A11Y:y`, `I18N:y`) | Same as L with optional P0/P1 specialists per predicates — within tier cap; overflow skip per [token-rules.md](../multi-agent-system/protocol/token-rules.md) | **3** (specialists count toward cap) |
| **L** | Medium feature + UI-from-Figma (`FIG:y`) | `planner` → `mas-figma` → `dev` → [`mas-visual-fidelity` when `VFID:y`] when cap allows; else skip + warn (recommend full `/mas`) | **3** (mas-figma / mas-visual-fidelity count toward cap) |
| **L+** | Medium feature + UI-from-Figma (`FIG:y` + `VFID:y`) | optional `osint` → `brainstorm` → `planner` → `mas-figma` → `dev` → [`mas-visual-fidelity` when `VFID:y`] within cap | **4** (specialists count toward cap) |
| **L+** | Medium feature, needs ideation first | optional `osint` → `brainstorm` → `planner` → `dev` → `ux-intelligence` when `UI_CHANGES: YES` (max 4); else optional `osint` → `brainstorm` → `planner` → `dev` → `reviewer` (lite) | **4** |

**Never in Lite:** Spec Reader, Architect, Documenter, full Reviewer — unless user explicitly requests full `/mas`.

**MAS-04 Phase A (L tier only):** S/M tiers unchanged — no P0 specialist spawns unless user upgrades to full `/mas`. L tier may spawn `security-auditor`, `dependency-risk`, `api-contract`, `test-executor` when predicates match and abbreviated flags fit 12-line cap (`SEC:y`, `API:y`, `DEPS:y`, `TEST:y` per [handoff-format-lite.md](../multi-agent-system/protocol/handoff-format-lite.md)). When projected chain exceeds tier cap, skip optional specialists in order: test-executor → api-contract → dependency-risk → security-auditor.

**MAS-04 Phase B (L tier only):** Lite may spawn `a11y` and `i18n` when predicates match (`A11Y:y`, `I18N:y` per handoff-format-lite). **Compliance is full `/mas` only** — never spawn `compliance` in lite (enterprise opt-in). Sequential: ux-intelligence → a11y → i18n when all triggered within tier cap. P1 overflow skip after P0: a11y → i18n (compliance N/A in lite).

**MAS-05 (L/L+ only):** `FIG:y` triggers mas-figma when Figma URL/node-id present — inspect-first recipe preserved. S/M tiers: no mas-figma spawn unless user upgrades to full `/mas`. If `FIG:y` would breach tier cap, document skip in user summary and recommend full `/mas`.

**MAS-06 (L/L+ only):** `VFID:y` triggers mas-visual-fidelity explicitly — **no auto predicate** in lite. S/M tiers: no mas-visual-fidelity spawn unless user upgrades to full `/mas`. When design-spec exists without `VFID:y`, skip spawn + warn **"Figma fidelity unverified"**. If `VFID:y` would breach tier cap, document skip and recommend full `/mas`.

Use **L+** when user says brainstorm, options, tradeoffs, or scope is ambiguous on logic/API/state.

**Brainstorm in Lite:** `UI_SCOPE: logic-only` unless user explicitly asks for UI.

Upgrade to full `/mas` when: PRD/API docs attached, new module, user says "full mas", or Reviewer lite fails twice.

## Lite Handoff Template

```
TASK_ID: <id>
MODE: LITE
TIER: S|M|L|L+
TARGET_AGENT: <osint|imaginer|perf-optimizer|release-readiness|test-strategy|bug-fix|android-dev|general-dev|ux-intelligence|brainstorm|planner|reviewer>
GOAL: <one sentence>
CONTEXT:
* See memory.md — <section>
FILES:
* path
UI_CHANGES: YES | NO
REVIEWER_MODE: lite
NEXT_AGENT: <agent|none>
DONE
```

Max **12 lines**. No CHANGE_SUMMARY essays.

## Subagent execution (mandatory)

Each specialist step = **`Task`** tool (`generalPurpose`, `run_in_background: false`). See [subagent-spawn.md](../multi-agent-system/protocol/subagent-spawn.md). Coordinator never implements inline.

## Lite Task prompt

Use the self-contained template in subagent-spawn.md with `LITE_MODE: true` and `MODE: LITE` on handoff. Specialists read [subagent-role.md](../multi-agent-system/protocol/subagent-role.md).

## Token Targets

| vs Opus | Lite tier |
|---------|-----------|
| **< 1×** | S (one subagent) |
| **≈ 1×** | M |
| **~1.2–1.5×** | L |

Full `/mas` remains available for maximum quality gates.

## S-Tier Bug Chain (Lite)

Default for non-trivial bugs:

1. `imaginer` (`NEXT_AGENT: bug-fix`) → trace data flow, write `.ai/context/imaginations/{TASK_ID}.md`
2. `bug-fix` (`NEXT_AGENT: reviewer`) — reads imagination brief if present

**Difficult bug with prior art (max 2):**

1. `osint` (`RESEARCH_MODE: BUG`, `NEXT_AGENT: imaginer` | `bug-fix`) → writes `.ai/context/osint/{TASK_ID}.md`
2. `imaginer` | `bug-fix` — reads osint brief; imaginer traces local path first

Variants:

- **Trace only:** `imaginer` with `TRACE_ONLY: true`, `NEXT_AGENT: none`
- **Research only:** `osint` with `RESEARCH_ONLY: true`, `NEXT_AGENT: none`
- **Trivial skip:** `bug-fix` only when stack trace or fix is obvious (≤1 hop)

Max **2** subagents for S-tier bug chain.

## L+ Feature Chain with OSINT (Lite)

When user requests research or Coordinator detects complex greenfield (max 4 subagents):

1. `osint` (`RESEARCH_MODE: FEATURE`, `NEXT_AGENT: brainstorm`) → writes brief
2. `brainstorm` (`NEXT_AGENT: planner`) — reads osint brief
3. `planner` (`NEXT_AGENT: dev`)
4. `dev` (`NEXT_AGENT: reviewer` or `ux-intelligence` when `UI_CHANGES: YES`)

Upgrade to full `/mas` when: PRD/API docs need Spec Reader, new module needs Architect, L+ would exceed 4 subagents with osint prepend, or Reviewer lite fails twice.

## S-Tier Perf Chain (Lite)

Default for non-trivial performance symptoms:

1. `perf-optimizer` (`NEXT_AGENT: android-dev` | `general-dev`) → writes `.ai/context/optimizations/{TASK_ID}.md`
2. `android-dev` | `general-dev` (`NEXT_AGENT: reviewer`) — reads optimization brief if present

Variants:

- **Analyze only:** `perf-optimizer` with `ANALYZE_ONLY: true`, `NEXT_AGENT: none`
- **Trivial skip:** dev only when fix is obvious (e.g. single `Dispatchers.IO`)

Max **2** subagents for S-tier perf chain. Skip documenter in lite (inherits mas-lite rules).

**Not default for perf:** M/L tiers — user may force `/mas-lite M` with perf-optimizer entry if scope small.

## S-Tier Release Chain (Lite)

Default for release / ship / production readiness intent:

1. `release-readiness` (`NEXT_AGENT: android-dev` | `general-dev` | `bug-fix`) → writes `.ai/context/release-readiness/{TASK_ID}.md`
2. Fix agent (`NEXT_AGENT: reviewer`) — reads release brief if present

Variants:

- **Audit only:** `release-readiness` with `RELEASE_ONLY: true`, `NEXT_AGENT: none`
- **All pass:** `release-readiness` only when no P0/P1 FAIL, `NEXT_AGENT: none`

Max **2** subagents for S-tier release chain. Skip documenter in lite fix loop (inherits mas-lite rules).

**Not default for M/L feature tiers** — release is user-triggered.

## M/L/L+ UI Chain (Lite)

When `UI_CHANGES: YES`:

- **M-tier:** `dev` → `ux-intelligence` (2 subagents). `ux-intelligence` `NEXT_AGENT: none` default (brief deliverable); user may run follow-up `/mas-lite S` dev pass or upgrade to full `/mas` for fix loop.
- **L-tier:** `planner` → `dev` → `ux-intelligence` (3 subagents). `NEXT_AGENT: none` or `reviewer` if user wants validation in same session (tradeoff: 3 agents, no dev fix loop in lite).
- **L+-tier:** `brainstorm` → `planner` → `dev` → `ux-intelligence` (4 subagents — at max; skip documenter/full reviewer per lite rules).

Lite **does not** auto-chain dev fix loop after ux-intelligence (token budget); full `/mas` does.

**Not default in M/L tiers** — `planner → test-strategy → dev → reviewer` = 4 subagents (exceeds lite budget). Use full `/mas` for integrated test-strategy + dev chain.

## S-Tier Test Strategy Chain (Lite)

Explicit test plan only:

1. `test-strategy` with `STRATEGY_ONLY: true`, `NEXT_AGENT: none` → writes `.ai/context/test-strategies/{TASK_ID}.md`

**Pre-dev lite variant (user forces):** `/mas-lite L test strategy then implement` — Coordinator runs test-strategy first (`NEXT_AGENT: none`); user starts second workflow for dev (two-phase pattern; same as perf analyze-only).

Max **1** subagent for S-tier strategy-only. Full `/mas` is default when user wants test-strategy in same feature chain as dev.

## L-Tier P0 Audit Chain (Lite — MAS-04 Phase A)

When L-tier feature work triggers MAS-04 predicates (`SEC:y`, `API:y`, `DEPS:y`, `TEST:y` or FILES/SCOPE match):

1. Optional early: `dependency-risk` (P0-1) after osint/planner seed — counts toward tier cap
2. Optional: `api-contract` (P0-2) after planner/architect context — counts toward cap
3. `planner` → `dev` (mandatory L chain)
4. Optional post-dev: `security-auditor` (P0-3) → `test-executor` (P0-4) before `reviewer` lite
5. `test-strategy` is **not** default in lite L — user may run S-tier `STRATEGY_ONLY` first or upgrade to full `/mas` for integrated `planner → test-strategy → dev → test-executor` chain

**Boundary:** test-strategy **plans** (pre-dev in full `/mas`); test-executor **runs** (post-dev). Lite L may spawn test-executor only when strategy brief exists or `TEST:y`.

Overflow: when cap threatened, skip per [token-rules.md](../multi-agent-system/protocol/token-rules.md) P0 then P1 skip order (a11y → i18n; compliance N/A in lite).

## L-Tier P1 UI Chain (Lite — MAS-04 Phase B)

When L-tier UI work triggers `UI_CHANGES: YES` and `A11Y:y` / `I18N:y`:

1. `planner` → `dev` (mandatory)
2. `ux-intelligence` when UI chain active
3. Optional: `a11y` (`A11Y:y` or FILES trigger) → `i18n` (`I18N:y` or SCOPE trigger) — **sequential only**
4. `reviewer` lite (no documenter in lite)

**Compliance:** not available in lite — use full `/mas` with `COMPLIANCE_FRAMEWORK` for enterprise audits.

## User Override Examples

- `/mas-lite L+ osint video export pipeline`
- `/mas-lite S osint only — Room migration crash` (`RESEARCH_ONLY: true`)
- `/mas-lite S osint → imaginer — obscure MediaCodec failure`
- `/mas-lite S trace export crash then fix`
- `/mas-lite S imaginer only — trace login flow regression`
- `/mas-lite S fix null crash in EditorViewModel` (trivial → bug-fix only)
- `/mas-lite S optimize export list jank` (perf → dev)
- `/mas-lite S perf analysis only — startup` (`ANALYZE_ONLY: true`)
- `/mas-lite S release readiness` (release → fix)
- `/mas-lite S release check` (release audit)
- `/mas-lite S release audit only` (`RELEASE_ONLY: true`)
- `/mas-lite S release only — no fixes` (`RELEASE_ONLY: true`)
- `/mas-lite M add export button` (if UI → dev → ux-intelligence)
- `/mas-lite S ux pass on onboarding — review only` (`UX_ONLY: true`)
- `/mas-lite S test strategy for export module` (`STRATEGY_ONLY: true`)
- `/mas-lite L test strategy then implement` (two-phase: strategy then dev in second workflow)
