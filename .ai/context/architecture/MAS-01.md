# Architecture Brief — MAS-01

## Architecture

**Option 2 — Incremental upgrade** extends the existing MAS framework as a **deterministic state machine** (Coordinator routing tables) plus an **artifact bus** (brief files on disk). No shared chat transcript, no LLM-based routing, no parallel specialist spawn by default.

### Core topology (unchanged)

```
User → Coordinator (inline, normal)
         │
         ├─ init-workflow-session.ps1 → workflow-sessions/{TASK_ID}.json
         ├─ handoff write → .ai/handoffs/{TASK_ID}[-{agent}].md
         ├─ Task spawn (foreground, model from policy) → Specialist
         ├─ record-workflow-step.ps1
         └─ route via NEXT_AGENT (zero-token table lookup)
```

### New subsystems (MAS-01)

| Subsystem | Role | Trigger |
|-----------|------|---------|
| **Spawn model policy** | Maps agent slug → `MODEL_CLASS` → Task `model` | Every specialist spawn |
| **Artifact forwarding** | Handoffs pass `BRIEF_PATH` + optional `SECTIONS:`; Coordinator chat = one line + path | Every specialist completion |
| **Brief schema registry** | Required headings per brief type; Reviewer enforces | Brief write + review |
| **Loop caps** | `MAX_CHAIN_AGENTS`, `MAX_REVIEWER_LOOPS`, debate caps | Session + Coordinator |
| **Debate micro-chain** | Single `debate-synthesizer` Task; internal persona rounds | 2nd Reviewer `NO`, `debate_used == false` |
| **Token auditor** | Post-finalize advisory brief | Optional after `Approved: YES` + FILES |
| **Install dedup** | Single canonical install tree; root `install/` export-generated or pointer-only | Export / CI guard |

### Architect gate decisions

#### 1. Install dedup — **export-generated root stub**

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Canonical edit surface | `skills/multi-agent-system/install/` | Co-located with protocol, skills, scripts; `$PSScriptRoot` already resolves here |
| Root `install/` in repo | **Pointer-only** — keep `install/README.md` redirect; **remove** duplicate `.ps1`, `.sh`, `.bat`, `manifest.json` from git | Today root and nested trees are byte-identical (verified); maintaining two copies guarantees drift |
| Release / workspace export | `export-mas-framework.ps1` copies canonical install → bundle `install/` (existing behavior) | Portable zip and folder export unchanged |
| Repo guard | Add `Test-InstallParity` in export script: if repo contains both trees and hashes differ → **fail** | Prevents reintroduction of hand-edited root copies |
| Contributor quick-start | Root `install/README.md` points to `skills/multi-agent-system/install/`; root README updated in Phase 5 | No broken paths — nested path is always valid in clone |

**Do not** delete install scripts from canonical path. **Do** treat any root `install/*` script (except README) as export artifact only.

#### 2. Debate v1 — **single synthesizer, sequential internal personas**

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Spawn model | **One** Task to `debate-synthesizer` (`mas-debate`) per session | Caps spawn count; avoids AutoGen-style multi-agent chat |
| Persona execution | Security-critic and simplicity-critic run **sequentially inside one subagent** (prompt sections in skill, not separate Tasks) | OSINT Finding #8: 2 critics + judge pattern; MAS forbids parallel spawn |
| Internal rounds | Max `MAX_DEBATE_ROUNDS` (full=2, lite=1); early exit on consensus | Bounded cost |
| `MODEL_CLASS` | `thinking` for `debate-synthesizer` | Synthesis requires judgment; persona passes are prompt-only (no extra spawn) |
| Output | `.ai/context/debates/{TASK_ID}.md` | Artifact bus; bug-fix subscribes |
| Not for | Feature brainstorming | `mas-brainstorm` owns design options |

#### 3. Lite handoff abbreviations — **approved**

| Full field | Lite abbreviation | Example line |
|------------|-------------------|--------------|
| `MODEL_CLASS:` | `MC:` | `MC: fast` |
| `BRIEF_PATH:` | `BP:` | `BP: .ai/context/osint/MAS-01.md` |
| `SECTIONS:` | `SEC:` | `SEC: Recommended, Logic Flow` (optional) |
| `DEBATE_TRIGGER:` | `DT:` | `DT: reviewer-rejection-2` (Coordinator-only) |

Fits 12-line cap: add at most 2 abbreviated lines per handoff; drop `CONTEXT` bullets in favor of `BP:` when brief exists.

---

## Modules:

Logical module map (framework repo — not Android Gradle modules).

```
mas-cursor-framework/
├── skills/
│   ├── multi-agent-system/          # Core bundle
│   │   ├── SKILL.md
│   │   ├── protocol/                # Orchestration contracts (extend)
│   │   │   ├── spawn-model-policy.md      [NEW]
│   │   │   ├── brief-schemas.md           [NEW]
│   │   │   ├── handoff-format.md          [UPDATE]
│   │   │   ├── handoff-format-lite.md     [UPDATE]
│   │   │   ├── subagent-spawn.md          [UPDATE]
│   │   │   ├── read-order.md              [UPDATE]
│   │   │   ├── token-rules.md             [UPDATE]
│   │   │   └── workflow-usage-policy.md   [UPDATE]
│   │   ├── scripts/                 # Session telemetry
│   │   │   ├── init-workflow-session.ps1  [UPDATE]
│   │   │   └── record-workflow-step.ps1   [existing -ModelClass]
│   │   └── install/                 # CANONICAL install (edit here only)
│   │       ├── manifest.json              [UPDATE: +mas-debate, +mas-token-auditor]
│   │       └── export-mas-framework.ps1   [UPDATE: hash guard]
│   ├── mas-coordinator/             # State machine router [UPDATE]
│   ├── mas-debate/                  # debate-synthesizer [NEW]
│   ├── mas-token-auditor/           # Post-workflow advisory [NEW]
│   └── mas-{role}/                  # Existing specialists [UPDATE startup refs]
├── install/                         # POINTER STUB ONLY (README.md)
├── commands/                        # mas.md, mas-lite.md
├── rules/                           # multi-agent-hybrid.mdc
└── hooks/                           # session context
```

### Per-project context dirs (`.ai/context/`)

| Dir | Brief type | Producer | Consumer(s) |
|-----|------------|----------|-------------|
| `osint/` | osint | osint | brainstorm, planner, architect |
| `brainstorms/` | brainstorm | brainstorm | planner, architect |
| `plans/` | plan | planner | architect, dev, bug-fix |
| `architecture/` | plan-adjacent | architect | dev, reviewer |
| `debates/` | debate | debate-synthesizer | bug-fix, reviewer |
| `audits/` | audit | token-auditor | user (advisory) |
| `workflow-sessions/` | session JSON | scripts | coordinator, token-auditor |

### Agent slug registry (post-MAS-01)

| Slug | Skill dir | Phase |
|------|-----------|-------|
| `debate-synthesizer` | `mas-debate` | 3 |
| `token-auditor` | `mas-token-auditor` | 4 |

All 17 existing slugs unchanged. Coordinator remains inline (not Task-spawned).

---

## Layers:

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation / Entry                                         │
│  commands/mas.md, mas-lite.md · rules/multi-agent-hybrid.mdc │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│  Orchestration (Coordinator)                                  │
│  mas-coordinator · routing tables · cap enforcement           │
│  handoff I/O · Task spawn · user summaries (artifact-forward)│
└────────────────────────────┬────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼───────┐  ┌─────────▼─────────┐  ┌──────▼──────┐
│  Protocol      │  │  Telemetry         │  │  Install    │
│  spawn-model   │  │  workflow-sessions │  │  manifest   │
│  brief-schemas │  │  record-step       │  │  export     │
│  token-rules   │  │  finalize/cancel   │  │  install-*  │
│  read-order    │  │  memory MAS-02     │  │  hash guard │
└───────┬───────┘  └───────────────────┘  └─────────────┘
        │
┌───────▼───────────────────────────────────────────────────┐
│  Specialist execution (Task-spawned, isolated context)     │
│  mas-{role}/SKILL.md · read-order subscription · brief write │
└───────┬───────────────────────────────────────────────────┘
        │
┌───────▼───────────────────────────────────────────────────┐
│  Artifact store (.ai/context/*, .ai/handoffs/*)              │
│  Durable briefs · ephemeral session JSON                     │
└─────────────────────────────────────────────────────────────┘
```

### Coordinator state extensions

Session JSON top-level fields (additive, defaults preserve regression):

```json
{
  "reviewer_loop_count": 0,
  "debate_used": false,
  "debate_round": 0
}
```

**Reviewer rejection state machine:**

```
Reviewer NO → reviewer_loop_count++
  ├─ count == 1 → bug-fix (findings-only handoff, agents-as-tools)
  ├─ count == 2 ∧ ¬debate_used → debate-synthesizer → bug-fix
  └─ count >= MAX_REVIEWER_LOOPS (2) post-debate → user escalation (no auto-spawn)
```

**Post-finalize (optional):**

```
finalize-workflow-usage.ps1 ∧ Approved: YES ∧ FILES non-empty
  → optional token-auditor (fast) → audits/{TASK_ID}.md (non-blocking)
```

---

## Contracts:

### Handoff extensions (full `/mas`)

```
MODEL_CLASS: fast | normal | thinking    # optional; default from spawn-model-policy.md
BRIEF_PATH: .ai/context/plans/{TASK_ID}.md
SECTIONS: Tasks, Dependencies            # optional slice; omit = full brief
DEBATE_TRIGGER: reviewer-rejection-2     # Coordinator-only; debate + bug-fix read debates/
```

Lite abbreviations: `MC:`, `BP:`, `SEC:`, `DT:` — see Architect gate §3.

### Spawn model policy (default map)

Resolution order: **handoff `MODEL_CLASS`** → **policy table** → **`default`**.

| Agent slug | `MODEL_CLASS` | Task `model` hint |
|------------|---------------|-------------------|
| osint, imaginer, documenter, spec-reader, token-auditor | `fast` | `composer-2.5-fast` |
| planner, brainstorm, test-strategy, ux-intelligence, android-dev, general-dev, bug-fix, coordinator | `normal` | default / `composer-2.5` |
| architect, reviewer, debate-synthesizer | `thinking` | `claude-opus-*-thinking-high` |

Fallback: if Task `model` unsupported → spawn with default; record `model: default`, `model_class` per policy in session step.

### Protocol constants (`token-rules.md`)

| Constant | Full `/mas` | Lite |
|----------|-------------|------|
| `MAX_CHAIN_AGENTS` | 12 | S=2, M=2, L=3, L+=4 |
| `MAX_REVIEWER_LOOPS` | 2 | 2 |
| `MAX_DEBATE_ROUNDS` | 2 | 1 |
| `MAX_DEBATE_SESSIONS_PER_TASK` | 1 | 1 |

Cap breach → Coordinator user escalation with paths to reviewer + debate briefs.

### Brief schema registry (`brief-schemas.md`)

| Type | Path pattern | Required sections |
|------|--------------|-------------------|
| osint | `.ai/context/osint/{TASK_ID}.md` | Research Summary, Findings table, Recommended Approach, Confidence |
| brainstorm | `.ai/context/brainstorms/{TASK_ID}.md` | Options table, Recommended, Logic Flow, Risks |
| plan | `.ai/context/plans/{TASK_ID}.md` | Tasks, Dependencies, Acceptance criteria |
| architecture | `.ai/context/architecture/{TASK_ID}.md` | Architecture, Modules, Layers, Contracts, Files |
| debate | `.ai/context/debates/{TASK_ID}.md` | Critics, Consensus, Action items, Dissent |
| audit | `.ai/context/audits/{TASK_ID}.md` | Step breakdown, Outliers, Recommendations |

Specialists complete even if sections missing; Reviewer flags gaps as `Approved: NO`.

### Subscription matrix (`read-order.md`)

| Agent | Reads at startup (beyond base context) |
|-------|----------------------------------------|
| brainstorm | `osint/{TASK_ID}.md`, `specs/{TASK_ID}.md` if exists |
| planner | osint, brainstorms, specs |
| architect | osint, brainstorms, plans |
| general-dev / android-dev | plans, imaginations, optimizations, ux-reviews, test-strategies |
| bug-fix | above + `debates/{TASK_ID}.md` when `DEBATE_TRIGGER` or debate brief exists |
| reviewer | all `{TASK_ID}` briefs + handoff FILES |
| debate-synthesizer | reviewer output, prior debate round, FILES |
| token-auditor | `workflow-sessions/{TASK_ID}.json` only |

`BRIEF_PATH` + `SECTIONS:` semantics: read only listed markdown headings; invalid `SECTIONS` → read full brief, Coordinator logs warning.

### Artifact-forward rule (Coordinator)

After each specialist step, user-visible summary:

```
{Agent} complete — {one-line outcome}. Brief: {path}
```

Never paraphrase or paste full brief body in Coordinator chat.

### Debate synthesizer contract

| Field | Value |
|-------|-------|
| Trigger | `reviewer_loop_count >= 2` AND `debate_used == false` |
| Input | Reviewer findings, FILES list, optional prior `debates/{TASK_ID}.md` |
| Personas | `security-critic`, `simplicity-critic` (sequential prompts in skill) |
| Max rounds | `MAX_DEBATE_ROUNDS`; set `debate_round` in session |
| Output | `debates/{TASK_ID}.md` with Critics, Consensus, Action items, Dissent |
| Post-action | `debate_used: true`; `NEXT_AGENT: bug-fix` |
| Security | Critics scope FILES only; no secret paste |

### Token auditor contract

| Field | Value |
|-------|-------|
| Trigger | Post-`finalize-workflow-usage.ps1`, `Approved: YES`, non-empty FILES |
| Skip | Planning-only chains; lite default skip unless user requests |
| Input | Session JSON + memory workflow bullet |
| Output | `audits/{TASK_ID}.md` |
| Blocks workflow | **Never** |

### Install manifest contract

`manifest.json` `skills` array must include `mas-debate` and `mas-token-auditor` before Phase 5 export. Export copies all manifest skills + canonical install files into bundle.

---

## Responsive Strategy:

**N/A — `UI_SCOPE: logic-only`.** No Compose screens, WindowSizeClass, or adaptive layouts. MAS-01 affects protocol, skills, scripts, and handoff fields only.

Tiered behavior applies to **workflow mode**, not viewport:

| Mode | Chain depth | Debate rounds | Auditor |
|------|-------------|---------------|---------|
| Full `/mas` | up to 12 agents | 2 | opt-in post-finalize |
| Lite S/M/L/L+ | 2–4 agents | 1 | skip unless user asks |

---

## Files:

### Create

| Path | Owner phase |
|------|-------------|
| `skills/multi-agent-system/protocol/spawn-model-policy.md` | 1 |
| `skills/multi-agent-system/protocol/brief-schemas.md` | 2 |
| `skills/mas-debate/SKILL.md` | 3 |
| `skills/mas-token-auditor/SKILL.md` | 4 |
| `.ai/context/debates/.gitkeep` | 3 |
| `.ai/context/audits/.gitkeep` | 4 |

### Update

| Path | Change summary |
|------|----------------|
| `skills/multi-agent-system/protocol/handoff-format.md` | `MODEL_CLASS`, `BRIEF_PATH`, `SECTIONS:`, debate subsection |
| `skills/multi-agent-system/protocol/handoff-format-lite.md` | `MC:`, `BP:`, `SEC:`, `DT:` |
| `skills/multi-agent-system/protocol/subagent-spawn.md` | model resolution, new slug rows, prompt refs |
| `skills/multi-agent-system/protocol/token-rules.md` | cap constants, artifact-forward |
| `skills/multi-agent-system/protocol/read-order.md` | subscription matrix, slice semantics |
| `skills/multi-agent-system/protocol/workflow-usage-policy.md` | session field docs |
| `skills/multi-agent-system/scripts/init-workflow-session.ps1` | seed new session fields |
| `skills/multi-agent-system/install/export-mas-framework.ps1` | `Test-InstallParity` hash guard |
| `skills/multi-agent-system/install/manifest.json` | +2 skills |
| `skills/mas-coordinator/SKILL.md` | spawn model, caps, debate loop, auditor, summaries |
| `skills/mas-bug-fix/SKILL.md` | debate brief in startup |
| `skills/mas-osint/SKILL.md`, `mas-brainstorm`, `mas-planner`, `mas-reviewer` | cite `brief-schemas.md` |
| `skills/mas-lite/SKILL.md` | auditor skip default |
| `README.md`, nested READMEs | install path, new protocol overview |

### Remove / stub

| Path | Action |
|------|--------|
| `install/install-mas-framework.ps1` | Remove from repo (export regenerates) |
| `install/install-mas-framework.sh` | Remove from repo |
| `install/install.bat` | Remove from repo |
| `install/manifest.json` | Remove from repo |
| `install/export-mas-framework.ps1` | Remove from repo |
| `install/README.md` | Replace with pointer to canonical path |

### Dependency order (implementation)

```
Phase 1: install dedup → spawn-model-policy → handoff formats → subagent-spawn → coordinator → manifest
Phase 2: brief-schemas → token-rules → read-order → session schema → specialist startup refs
Phase 3: mas-debate → coordinator rejection loop → bug-fix → manifest
Phase 4: mas-token-auditor → coordinator finalize → manifest
Phase 5: READMEs + documenter script headers
```

---

## Usage Report

Model: default
Class: thinking
Tokens: unknown
