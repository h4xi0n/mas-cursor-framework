# Handoff Format (MAS Lite)

Max **12 lines**. Write to `.ai/handoffs/{TASK_ID}.md` only — never paste in chat.

```
TASK_ID: <id>
MODE: LITE
TIER: S|M|L|L+
TARGET_AGENT: <osint|imaginer|perf-optimizer|release-readiness|test-strategy|security-auditor|dependency-risk|api-contract|test-executor|mas-figma|bug-fix|android-dev|general-dev|ux-intelligence|brainstorm|planner|reviewer|debate-synthesizer|token-auditor>
SPAWN_STATUS: spawned
MC: fast|normal|thinking          # optional; lite MODEL_CLASS — see spawn-model-policy.md
BP: .ai/context/osint/{TASK_ID}.md # optional BRIEF_PATH
SEC: Recommended, Logic Flow      # optional SECTIONS slice
DT: reviewer-rejection-2          # Coordinator-only debate trigger
UI_SCOPE: logic-only
GOAL: <one sentence>
CONTEXT:
* memory.md — <section>
FILES:
* path
UI_CHANGES: YES | NO
REVIEWER_MODE: lite
NEXT_AGENT: <none|reviewer>
DONE
```

## Lite abbreviations

| Full field | Lite | Example |
|------------|------|---------|
| `MODEL_CLASS:` | `MC:` | `MC: fast` |
| `BRIEF_PATH:` | `BP:` | `BP: .ai/context/osint/MAS-01.md` |
| `SECTIONS:` | `SEC:` | `SEC: Recommended, Logic Flow` |
| `DEBATE_TRIGGER:` | `DT:` | `DT: reviewer-rejection-2` |
| `SECURITY_AUDIT:` | `SEC:` | `SEC:y` (routing flag — see disambiguation below) |
| `API_CONTRACT:` | `API:` | `API:y` |
| `SUPPLY_CHAIN:` | `DEPS:` | `DEPS:y` |
| `RUN_TESTS:` | `TEST:` | `TEST:y` |
| `A11Y_AUDIT:` | `A11Y:` | `A11Y:y` |
| `I18N_AUDIT:` | `I18N:` | `I18N:y` |
| `FIGMA_SPEC:` | `FIG:` | `FIG:y` |
| `VISUAL_FIDELITY:` | `VFID:` | `VFID:y` |
| `DEVICE_SERIAL:` | `DEV_SER:` | `DEV_SER:R58M90ABCDE` |
| `DEVICE_POLICY:` | `DEV_POL:` | `DEV_POL:physical` |
| `LOG_CAPTURE:` | `LOG:` | `LOG:y` |

**`SEC:` disambiguation (12-line cap):** `SEC:y` or `SEC:n` → `SECURITY_AUDIT` routing flag. `SEC: Heading1, Heading2` (comma-separated headings) → `SECTIONS:` slice per [brief-schemas.md](brief-schemas.md). Do not combine both on one line.

**Compliance:** `COMPLIANCE_FRAMEWORK` — **full `/mas` only** (no lite abbreviation). Enterprise opt-in; never spawn in lite.

**MAS-06 (v1.4.0):** `VFID:y` — explicit mas-visual-fidelity trigger only (no auto predicate in lite). When design-spec exists without `VFID:y`, skip spawn + warn "Figma fidelity unverified". L/L+ within tier cap only.

Drop `CONTEXT` bullets in favor of `BP:` when brief exists. Max **12 lines** total.

## Output (Lite)

**OSINT:** `## Summary` (bullets) + `## Brief Path` + `DONE` — no full source tables in lite.

**Imaginer:** `## Summary` (bullets) + `## Brief Path` + `DONE` — no full table paste.

**Perf Optimizer:** `## Summary` (bullets) + `## Brief Path` + `DONE` — no full finding tables in lite.

**Release Readiness:** `## Summary` (bullets) + `## Brief Path` + `DONE` — no full 17-row category table in lite.

**Test Strategy:** `## Summary` (bullets) + `## Brief Path` + `DONE` — no full table paste.

**UX Intelligence:** `## Summary` (bullets) + `## Brief Path` + `DONE` — no full table paste.

### Coordinator → UX Intelligence (Lite)

When `TARGET_AGENT: ux-intelligence` (M/L/L+ UI chains or S-tier `UX_ONLY` audit):

```
FEATURE: <screen or flow>
USER_GOAL: <user intent>
SCOPE:
* primary path + edge states
UX_ONLY: true | false
DELIVERABLE: Brief at .ai/context/ux-reviews/{TASK_ID}.md
NEXT_AGENT: none
```

Standards: [ux-intelligence-standards.md](../references/ux-intelligence-standards.md). Full handoff fields: [handoff-format.md](handoff-format.md) § Coordinator → UX Intelligence.

**Dev / Bug Fix:** `## Summary` (bullets) + `## Files` (paths only) + `DONE` — no full code in output.

**Reviewer lite:** See [reviewer-lite.md](../references/reviewer-lite.md).

**Planner:** `## Plan` (tasks max 5 lines) + `Required Agents: dev, reviewer` + `DONE`.

## S-Tier Bug Chain (Lite)

Default non-trivial bug: `imaginer` (`NEXT_AGENT: bug-fix`) → `bug-fix` (`NEXT_AGENT: reviewer`). Max 2 subagents.

**Difficult bug with prior art:** `osint` (`NEXT_AGENT: imaginer` | `bug-fix`) → second agent. Max 2 subagents.

- Trace only: `imaginer` + `TRACE_ONLY: true`, `NEXT_AGENT: none`
- Research only: `osint` + `RESEARCH_ONLY: true`, `NEXT_AGENT: none`
- Trivial: `bug-fix` only, skip imaginer and osint

## S-Tier Perf Chain (Lite)

Default non-trivial perf: `perf-optimizer` (`NEXT_AGENT: android-dev` | `general-dev`) → dev (`NEXT_AGENT: reviewer`). Max 2 subagents.

- Analyze only: `perf-optimizer` + `ANALYZE_ONLY: true`, `NEXT_AGENT: none`
- Trivial: dev only when fix obvious

## S-Tier Release Chain (Lite)

Default non-trivial release: `release-readiness` (`NEXT_AGENT: android-dev` | `general-dev` | `bug-fix`) → fix agent (`NEXT_AGENT: reviewer`). Max 2 subagents.

- Audit only: `release-readiness` + `RELEASE_ONLY: true`, `NEXT_AGENT: none`
- All pass: `release-readiness` only, `NEXT_AGENT: none`

## L+ Feature Chain with OSINT (Lite)

When user requests research or Coordinator detects complex greenfield (max 4 subagents):

1. `osint` (`RESEARCH_MODE: FEATURE`, `NEXT_AGENT: brainstorm`) → writes `.ai/context/osint/{TASK_ID}.md`
2. `brainstorm` (`NEXT_AGENT: planner`) — reads osint brief
3. `planner` (`NEXT_AGENT: dev`)
4. `dev` (`NEXT_AGENT: reviewer` or `ux-intelligence` when `UI_CHANGES: YES`)

Upgrade to full `/mas` when PRD/API docs need Spec Reader, new module needs Architect, or Reviewer lite fails twice.

## M/L/L+ UI Chain (Lite)

When `UI_CHANGES: YES` — see [mas-lite/SKILL.md](../../mas-lite/SKILL.md) tier table. Lite does **not** auto-chain dev fix loop after ux-intelligence; full `/mas` does.

- **M:** `dev` → `ux-intelligence` (`NEXT_AGENT: none` default)
- **L:** `planner` → `dev` → `ux-intelligence`
- **L+:** optional `osint` → `brainstorm` → `planner` → `dev` → `ux-intelligence` (max 4 with osint prepend)
- **S audit only:** `ux-intelligence` + `UX_ONLY: true`, `NEXT_AGENT: none`
