# MAS-03 Implementation Brief — Cross-Project Integration Audit

**TASK_ID:** MAS-03  
**Source:** Install docs (`skills/multi-agent-system/install/README.md`, `manifest.json`)  
**Goal:** Define MAS integration acceptance criteria for auditing global (`~/.cursor`) and per-project setup across `C:\Users\arunk\AndroidStudioProjects`.

---

## Requirements Summary

### Goals

1. Produce auditable checklists distinguishing **global Cursor install** from **per-project bootstrap**.
2. Define three integration states: **fully integrated**, **partial**, **not integrated**.
3. Enumerate all projects under `C:\Users\arunk\AndroidStudioProjects` to audit.
4. Enable downstream agent (general-dev) to run a systematic cross-project audit.

### In Scope

- Global `~/.cursor` artifacts installed by `install-mas-framework.ps1` / manual copy per manifest.
- Per-project artifacts created by `init-mas-context.ps1` or equivalent manual bootstrap.
- Verification steps from install README ("Verify" section).
- Optional workspace-level commands (`.cursor/commands/` in repo root).

### Out of Scope

- Implementing fixes for failed audits (separate task).
- Auditing projects outside `C:\Users\arunk\AndroidStudioProjects`.
- Validating MAS workflow correctness (token usage, agent chains) — only file/install presence.
- Mac/Linux-specific hook command strings (audit target is Windows per handoff).

---

## Global Integration Checklist (`~/.cursor`)

Base path: `%USERPROFILE%\.cursor` (Windows) / `~/.cursor` (Mac).

### Skills (`~/.cursor/skills/`)

All skills listed in `manifest.json` must exist as directories:

| Skill | Required |
|-------|----------|
| `multi-agent-system` | Yes (includes `install/`, `scripts/`, `protocol/`, `templates/`) |
| `mas` | Yes |
| `mas-coordinator` | Yes |
| `mas-brainstorm` | Yes |
| `mas-planner` | Yes |
| `mas-architect` | Yes |
| `mas-android-dev` | Yes |
| `mas-general-dev` | Yes |
| `mas-osint` | Yes |
| `mas-imaginer` | Yes |
| `mas-ux-intelligence` | Yes |
| `mas-perf-optimizer` | Yes |
| `mas-release-readiness` | Yes |
| `mas-test-strategy` | Yes |
| `mas-bug-fix` | Yes |
| `mas-reviewer` | Yes |
| `mas-documenter` | Yes |
| `mas-spec-reader` | Yes |
| `mas-commit` | Yes |
| `mas-lite` | Yes |
| `mas-debate` | Yes |
| `mas-token-auditor` | Yes |

**Critical subpaths under `multi-agent-system/`:**

- `install/manifest.json`, `install/install-mas-framework.ps1`, `install/export-mas-framework.ps1`
- `scripts/init-mas-context.ps1` (per-project bootstrap)
- `protocol/` (handoff, spawn, read-order policies)
- `templates/` (project.md, coding_standards, memory, daily-changelog)

### Commands (`~/.cursor/commands/`)

| File | Required |
|------|----------|
| `mas.md` | Yes |
| `mas-lite.md` | Yes |

**Verify:** Typing `/` in Agent chat shows **mas** and **mas-lite** slash commands.

### Rules (`~/.cursor/rules/`)

| File | Required |
|------|----------|
| `multi-agent-hybrid.mdc` | Yes |

**Verify:** Rule activates hybrid MAS behavior (`/mas`, `/mas-lite` routing per rule content).

### Hooks (`~/.cursor/hooks/`)

| File | Required (Windows) |
|------|-------------------|
| `mas-session-context.ps1` | Yes |
| `mas-session-context.sh` | Yes (present; used on Mac) |

### Hooks config (`~/.cursor/hooks.json`)

Must contain MAS entries (merged, not overwritten):

| Event | Command pattern |
|-------|-----------------|
| `sessionStart` | `powershell ... mas-session-context.ps1 -Event sessionStart` |
| `subagentStop` | `powershell ... mas-session-context.ps1 -Event subagentStop` |

**Verify:** Opening a project with `.ai/context/` triggers session hint mentioning `/mas` and `/mas-lite` (hook reads workspace `.ai/`).

### Optional docs (`~/.cursor/`)

| File | Required |
|------|----------|
| `USER-RULE-MAS.md` | Optional (reference for User Rules paste) |

---

## Per-Project Integration Checklist

Created by `init-mas-context.ps1 -ProjectPath <path> -Stack auto` or manual equivalent.

### Context directory (`.ai/context/`)

| Path | Required | Notes |
|------|----------|-------|
| `.ai/context/project.md` | Yes | Stack, modules, entry points |
| `.ai/context/coding_standards.md` | Yes | Android or general template |
| `.ai/context/memory.md` | Yes | Durable decisions |
| `.ai/context/daily-changelog.md` | Yes | Created by init script |
| `.ai/context/specs/` | Yes | Directory + `.gitkeep` |
| `.ai/context/brainstorms/` | Yes | Directory + `.gitkeep` |
| `.ai/context/imaginations/` | Yes | Directory + `.gitkeep` |
| `.ai/context/workflow-sessions/` | Yes | Directory (no `.gitkeep` required) |

**Optional subdirs** (not created by init, may exist from prior MAS work):

- `.ai/context/architecture/`, `plans/`, `osint/`, `audits/`, `debates/`

### Handoffs (`.ai/handoffs/`)

| Path | Required |
|------|----------|
| `.ai/handoffs/` | Yes (directory) |
| `.ai/handoffs/.gitkeep` | Yes (if no handoff files yet) |

### Root files

| Path | Required | Notes |
|------|----------|-------|
| `AGENTS.md` | Yes | Pointer: read `.ai/context/` order; `/mas` / `/mas-lite` |
| `.gitignore` | Yes | Must include `.ai/` block |

**Expected `.gitignore` block:**

```
# Multi-agent local context (not in VCS)
.ai/
```

Init script also removes legacy partial rules (`.ai/handoffs/*.md` only) if present.

### Optional per-project

| Path | Required |
|------|----------|
| `.cursor/commands/mas.md` | Optional (team-shared slash commands) |
| `.cursor/commands/mas-lite.md` | Optional |

---

## Acceptance Criteria — Integration States

### Fully Integrated

**Global AND per-project criteria met.**

#### Global (all must pass)

1. All 22 manifest skills present under `~/.cursor/skills/`.
2. `mas.md` and `mas-lite.md` in `~/.cursor/commands/`.
3. `multi-agent-hybrid.mdc` in `~/.cursor/rules/`.
4. `mas-session-context.ps1` (and `.sh`) in `~/.cursor/hooks/`.
5. `hooks.json` contains both `sessionStart` and `subagentStop` MAS hook commands.
6. `/mas` and `/mas-lite` appear in Agent chat slash command list.
7. `multi-agent-system/scripts/init-mas-context.ps1` exists and is runnable.

#### Per-project (all must pass)

1. `.ai/context/project.md`, `coding_standards.md`, `memory.md`, `daily-changelog.md` exist.
2. `.ai/context/specs/`, `brainstorms/`, `imaginations/`, `workflow-sessions/` directories exist.
3. `.ai/handoffs/` directory exists.
4. `AGENTS.md` at project root with MAS pointer content.
5. `.gitignore` excludes `.ai/` (full directory, not partial handoff-only rule).
6. Functional verify: `/mas-lite S` or `/mas` runs without missing-skill errors (smoke test).

---

### Partial Integration

**Some but not all criteria met.** Common partial patterns:

| Pattern | Classification |
|---------|----------------|
| Global install complete; project has no `.ai/` | **Partial** (global only) |
| Project has `.ai/context/` but missing `AGENTS.md` or `.gitignore` entry | **Partial** (project incomplete) |
| Project has legacy `.ai/handoffs/*.md` gitignore but not full `.ai/` exclusion | **Partial** (outdated bootstrap) |
| Skills installed but `hooks.json` missing MAS entries | **Partial** (hooks not wired) |
| Commands/rules present but one or more manifest skills missing | **Partial** (incomplete global) |
| `mas-cursor-framework` source repo with full `.ai/` but global `~/.cursor` not installed from it | **Partial** (source ≠ install target) |
| Only `mas-lite` artifacts, no full `multi-agent-system` tree | **Partial** |
| Optional `USER-RULE-MAS.md` or workspace `.cursor/commands/` missing | Still **fully integrated** if all required items pass |

**Partial scoring guidance for audit report:**

- Record **global score**: `N/M` required global checks.
- Record **project score**: `N/M` required per-project checks.
- State: `PARTIAL — global X/Y, project A/B`.

---

### Not Integrated

**No meaningful MAS setup.**

| Condition | Classification |
|-----------|----------------|
| No MAS skills under `~/.cursor/skills/` | **Not integrated** (global) |
| Project has no `.ai/` directory and no `AGENTS.md` | **Not integrated** (project) |
| Only unrelated `.cursor` config; no `multi-agent-hybrid.mdc` | **Not integrated** |
| Empty or placeholder `.ai/` with no context files | **Not integrated** (project) |

**Special cases under audit root:**

| Path | Expected classification |
|------|------------------------|
| `.ai` (sibling folder under AndroidStudioProjects) | Likely **not a project** — audit as config stash, not app repo |
| `.cursor` (sibling folder under AndroidStudioProjects) | Likely **not a project** — may be stray Cursor config copy |
| `mas-cursor-framework` | Framework **source** — expect full `.ai/`; global install may mirror or lag source |
| `mas-cursor-framework-export-test` | **Export/install test** artifact — compare against post-install manifest |

---

## Projects to Audit

Root: `C:\Users\arunk\AndroidStudioProjects`

| # | Project / Path | Type | Audit focus |
|---|----------------|------|-------------|
| 1 | `BMAD-setup` | App project | Per-project bootstrap + global dependency |
| 2 | `EditPrime` | App project | Per-project bootstrap + global dependency |
| 3 | `EditPrime-Phase2` | App project | Per-project bootstrap + global dependency |
| 4 | `mas-cursor-framework` | Framework source | Full `.ai/` expected; compare to manifest |
| 5 | `mas-cursor-framework-export-test` | Install test bundle | Post-export/install fidelity |
| 6 | `.ai` | Config directory (non-repo) | Not a standard project — note contents only |
| 7 | `.cursor` | Config directory (non-repo) | May duplicate global install — compare to `~/.cursor` |

**Global install** is audited once at `%USERPROFILE%\.cursor` (not per project).

**Audit order recommended:**

1. Global `~/.cursor` (single pass).
2. `mas-cursor-framework` (reference implementation).
3. `mas-cursor-framework-export-test` (install fidelity).
4. `BMAD-setup`, `EditPrime`, `EditPrime-Phase2` (consumer projects).
5. `.ai`, `.cursor` (document anomalies).

---

## API Contract Summary

N/A — no external API. Internal contracts:

- **Install contract:** `manifest.json` drives `install-mas-framework.ps1` copy targets.
- **Bootstrap contract:** `init-mas-context.ps1` creates per-project tree from `templates/`.
- **Hook contract:** `hooks.json` events `sessionStart`, `subagentStop` → `mas-session-context.ps1`.

---

## Design & UX Notes

N/A — logic-only audit spec. No UI changes.

---

## Constraints

- Windows primary environment (`powershell` hook commands).
- Install uses merge semantics for `hooks.json` (must not destroy unrelated hooks).
- Per-project `.ai/` is gitignored — audit is filesystem-based, not git-tracked.
- Framework version in manifest: **1.0.0** (`mas-cursor-framework`).
- Reload Cursor required after global install for commands/rules/hooks to activate.

---

## Assumptions

- **ASSUMPTION:** Audit runs on the same machine where `~/.cursor` is the live Cursor config (not remote).
- **ASSUMPTION:** `mas-cursor-framework` repo is the authoritative source; `~/.cursor` should match manifest unless intentionally outdated.
- **ASSUMPTION:** `.ai` and `.cursor` folders at AndroidStudioProjects root are not application repos.

---

## Open Questions

1. **README vs manifest skill list:** Install README table (lines 99–106) omits `mas-osint`, `mas-imaginer`, `mas-ux-intelligence`, `mas-perf-optimizer`, `mas-release-readiness`, `mas-test-strategy`, `mas-brainstorm`. **manifest.json is authoritative** for audit — confirm whether README should be updated separately.
2. **Export-test project:** Is `mas-cursor-framework-export-test` a fresh export or an installed copy? Affects whether it should have `.ai/` or only global artifacts.
3. **`.ai` / `.cursor` siblings:** Are these intentional workspace-level folders or accidental copies? Coordinator/user should clarify expected state.
4. **Version drift:** Should audit fail on skill content diff vs source, or only on presence? Default: **presence only** unless `-Force` reinstall requested.

---

## Conflicts with Memory

None. `memory.md` documents MAS-01/MAS-02 workflow policies; no conflict with install acceptance criteria.

---

## Downstream Audit Deliverable (for general-dev)

Produce a matrix:

```
| Project | Global | Project | State | Gaps |
```

With remediation commands where applicable:

```powershell
# Global install (from bundle)
cd path\to\mas-cursor-framework\install
.\install-mas-framework.ps1 -Force

# Per-project bootstrap
~\.cursor\skills\multi-agent-system\scripts\init-mas-context.ps1 -ProjectPath "C:\Users\arunk\AndroidStudioProjects\<project>" -Stack auto
```

---

## Recommended Next Agent

**general-dev** (per handoff `NEXT_AGENT`)

---

## Source Inventory

| Document | Status | Notes |
|----------|--------|-------|
| `.ai/handoffs/MAS-03.md` | READ | Handoff with goal, docs, project list |
| `skills/multi-agent-system/install/README.md` | READ | Install/export/bootstrap/verify |
| `skills/multi-agent-system/install/manifest.json` | READ | Authoritative skill/command/rule/hook list |
| `skills/multi-agent-system/scripts/init-mas-context.ps1` | READ | Per-project bootstrap behavior |
| `skills/multi-agent-system/install/install-mas-framework.ps1` | READ | Global install + hooks.json merge |
| `hooks.mas.template.json` | READ | Hook event template |
| `.ai/context/memory.md` | READ | No conflicts |
