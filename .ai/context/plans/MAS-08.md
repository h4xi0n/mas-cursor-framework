# Plan Brief — MAS-08

## Plan

Goal:
Ship **Option 2 — Platform-native plugin with phased protocol upgrade** (per `.ai/context/brainstorms/MAS-08.md` Recommended and `.ai/context/osint/MAS-08.md` Recommended Approach): package MAS v1.6 as a **Cursor Plugin** with **project-level hooks**, refresh **spawn-model-policy** (`inherit` defaults + class-based fallback), add **hybrid `.cursor/agents/` stubs** and **built-in delegation** (`explore` / `bash` / `browser`), optional **PARALLEL_AUDIT** async lane, **MCP plugin template**, and **Plan Mode export** bridge — while preserving MAS invariants (reviewer `Approved:` gate, foreground dev chain, self-contained Task prompts, artifact-forward hooks). **Logic-only** — no IDE UI layouts or marketplace screenshots.

**Upstream context:** `.ai/handoffs/MAS-08-planner.md`; brainstorm Logic Flow A–G, Domain & Contracts, Quality Bar; OSINT Findings #1–#10 (HIGH confidence on P0 items).

**Version target:** `1.6.0` — additive plugin + protocol; air-gapped install script remains fallback.

**Resolved / escalated open questions (architect confirms in Phase 0):**

| ID | Decision | Rationale |
|----|----------|-----------|
| Q1 | **Plugin wins over global on name collision when plugin active; project paths win over both** — document in README + `platform-parity.md`; dogfood test required | Brainstorm open Q1; aligns with Cursor project-scoped precedence pattern |
| Q2 | **Static class→hint table in `spawn-model-policy.md` + optional `agent models` probe script (P1, non-blocking)** | Avoid Coordinator startup dependency on CLI; quarterly manual refresh + probe for dogfood |
| Q3 | **No programmatic Coordinator API work in v1.6** — extend `subagentStop` followup only | OSINT open Q3; out of scope until Cursor exposes APIs |
| Q4 | **Document enterprise merge order in `platform-parity.md`; project deny wins for MAS matchers** | Architect validates hook JSON merge semantics in dogfood |
| Q5 | **`PARALLEL_AUDIT` default `no`; use Task `run_in_background` param only (not agent frontmatter `is_background`)** | Forum 2.5 parent-verification gap; lite mode ignores flag |
| Q6 | **CI stub generation from `install/manifest.json` → top 8 `.cursor/agents/*.md` (architect picks template)** | Reduces dual-maintenance drift; hand-maintained acceptable for v1.6.0 if CI deferred |
| Q7 | **CLI parity matrix in `platform-parity.md`** — Task tool partial; adb/device prep IDE+CLI local only | Honest boundary per MAS-07 cloud constraint |

**Non-negotiable invariants (do not change):**

- Reviewer sole `Approved:` gate
- Foreground sequential dev → ux → a11y → i18n chain (same FILES)
- Self-contained Task prompts (subagents do not receive User Rules)
- Hybrid rule `multi-agent-hybrid.mdc` with `alwaysApply`
- Artifact-forward — hooks never inject full brief bodies into `additional_context`

**NEXT_AGENT:** architect

Tasks:

### Phase 0 — Architect gate (pre-implementation)

1. **Architect confirms v1.6 topology and file layout** — Validate plugin manifest structure, project hooks bootstrap flow, hook script layout (`.cursor/hooks/` vs user `~/.cursor`), native agent stub template, delegation map wiring, CI sync between `install/manifest.json` and `.cursor-plugin/plugin.json`, and Q1–Q7 resolutions above.
   - **Files:** `.ai/context/architecture/MAS-08.md` (new)
   - **Decisions required:**
     - `.cursor-plugin/plugin.json` schema vs `install/manifest.json` canonical skill list (duplicate vs import; CI subset check)
     - Bootstrap trigger: first `/mas` vs explicit `init-mas` script; emitted paths (`.ai/` scaffold, `.cursor/hooks.json`, hook scripts)
     - Hook event contracts: `subagentStart`, `subagentStop`, `postToolUse` (matcher Task), `stop`, `preCompact`; fail-open v1.6 defaults
     - `record-workflow-step.ps1` fields: `agent`, `model`, `model_class`, `subagent_type`, `delegate`, `duration_ms`
     - Native agent stub frontmatter: `name`, `description`, `model`, `readonly` (auditors)
     - Top 8 stub slugs: osint, brainstorm, planner, architect, general-dev, reviewer, test-executor, security-auditor
     - Delegation map: `DELEGATE: explore|bash|browser` handoff field → Task `subagent_type`
     - `PARALLEL_AUDIT: yes` coordinator wait/collect protocol before reviewer
     - `platform-parity.md` location: `skills/multi-agent-system/protocol/platform-parity.md`
     - Semver `1.6.0`; manifest bump strategy
   - **Acceptance:** Architecture brief documents end-to-end install → bootstrap → spawn → hooks → brief flow without re-litigating brainstorm options.

---

### Phase P0 — Distribution + hooks + model policy (v1.6.0 core)

2. **Create `.cursor-plugin/plugin.json`** — Cursor Plugin manifest bundling skills, rules, commands, hooks reference per brainstorm Domain & Contracts plugin sketch.
   - **Files:** `.cursor-plugin/plugin.json` (new)
   - **Content:** `name`, `version: 1.6.0`, `skills`, `rules`, `commands`, `hooks` path; skill list ⊆ `install/manifest.json`
   - **Acceptance:** Validates against Cursor plugin schema; no secrets; references repo-relative paths.

3. **Sync `install/manifest.json` to v1.6.0** — Bump version; add `plugin` metadata pointer if architect specifies; document plugin as primary distribution path.
   - **Files:** `skills/multi-agent-system/install/manifest.json`
   - **Acceptance:** Skill inventory unchanged unless architect adds paths metadata; version `1.6.0`.

4. **Extend bootstrap / init script for project hooks** — Emit `.cursor/hooks.json` (`version: 1`) and copy hook scripts to `.cursor/hooks/` on first MAS run or explicit init.
   - **Files:** `skills/multi-agent-system/install/init-mas-context.ps1` (extend) or new `init-mas-project.ps1`; `.cursor/hooks.json` template in install bundle
   - **Events:** `subagentStart` (validate TASK_ID + handoff `SPAWN_STATUS: spawned`), `subagentStop` (existing followup), `postToolUse` (matcher Task → telemetry), `stop` (finalize session JSON), `preCompact` (warn incomplete handoffs)
   - **Acceptance:** Fresh repo bootstrap creates committed-ready `.cursor/hooks.json`; Cloud Agent loads repo hooks; fail-open on non-MAS Tasks.

5. **Extend hook scripts for v1.6 events** — Refactor/extend `mas-session-context` pattern; add `subagentStart` validator and `record-workflow-step` invoker.
   - **Files:** `skills/multi-agent-system/hooks/mas-session-context.ps1`, `.sh` (or `.cursor/hooks/` copies); optional `validate-subagent-start.ps1`, `record-workflow-step.ps1` extensions
   - **Security:** Read-only validation; no unescaped handoff content to shell; no brief body in logs
   - **Acceptance:** Fixture JSON in/out for `subagentStart` validator; `subagentStop` followup_message shape unchanged for chain reminder.

6. **Refresh `spawn-model-policy.md`** — `inherit` default for dev-class agents; class→hint table; remove hard-coded `claude-opus-4-7-*` from coordinator-facing docs; add `MODEL_SLUG:` override (v1.6 handoff extension).
   - **Files:** `skills/multi-agent-system/protocol/spawn-model-policy.md`
   - **Policy:**
     - `fast` → latest `*-fast` family OR `default` fallback
     - `normal` → `inherit` (preferred) OR `default`
     - `thinking` → latest thinking-high family OR `default`
     - Dev-class (`general-dev`, `android-dev`, `bug-fix`) → `inherit` default
   - **Resolution order:** handoff `MODEL_CLASS` → `MODEL_SLUG:` override → policy table → Task spawn; on rejection → `default` + session step log
   - **Acceptance:** Table-driven fixtures resolve each slug; stale slug spawn falls back without aborting chain.

7. **Extend `handoff-format.md` + lite format** — Document v1.6 handoff fields.
   - **Files:** `skills/multi-agent-system/protocol/handoff-format.md`, `handoff-format-lite.md`
   - **Fields:** `MODEL_SLUG:` (optional explicit Task model); `DELEGATE:` (`explore`|`bash`|`browser`); `PARALLEL_AUDIT:` (`yes`|`no`, default no); `PLAN_MODE:` (`export`, P3)
   - **Acceptance:** Fields optional; existing handoffs remain valid.

8. **Update export/install scripts** — Plugin bundle path; air-gapped fallback documented; README model CLI note (`/models`, `agent models`).
   - **Files:** `skills/multi-agent-system/install/export-mas-framework.ps1` (if applicable), `README.md` (slice)
   - **Acceptance:** Air-gapped `init-mas` still works when marketplace unavailable; plugin happy path documented.

---

### Phase P1 — Native agents + delegation map

9. **Create `.cursor/agents/` stubs for top 8 specialists** — Thin wrappers mirroring skill slugs; model from spawn-model-policy; `readonly: true` for security-auditor.
   - **Files:** `.cursor/agents/osint.md`, `brainstorm.md`, `planner.md`, `architect.md`, `general-dev.md`, `reviewer.md`, `test-executor.md`, `security-auditor.md` (new)
   - **Content:** Self-contained spawn prompt template reference; skill path; brief schema pointer; no duplicate skill body
   - **Acceptance:** Coordinator may spawn via Task with matching slug OR continue `generalPurpose` + skill prompt; stubs align with policy table.

10. **Extend `subagent-spawn.md`** — Delegation table, built-in subagent routing, model resolution cross-ref, nested async depth limit (≤2).
    - **Files:** `skills/multi-agent-system/protocol/subagent-spawn.md`
    - **Delegation map:**

    | TARGET_AGENT | Default | Built-in when | Handoff flag |
    |--------------|---------|---------------|--------------|
    | osint | generalPurpose | `explore` if FILES empty + codebase discovery | `DELEGATE: explore` |
    | test-executor | generalPurpose | `bash` if shell-only prep + gradle + adb | `DELEGATE: bash` |
    | mas-visual-fidelity | generalPurpose | `browser` if MCP browser tab required | `DELEGATE: browser` |
    | all other MAS specialists | generalPurpose | never replace | — |

    - **Rule:** Built-in output supplements only; `BRIEF_PATH` / FILES remain authoritative
    - **Acceptance:** Handoff fixtures document `DELEGATE: bash` → `subagent_type: bash` in spawn examples.

11. **Update `mas-coordinator/SKILL.md`** — Model resolution flow; delegation decision table; Task rejection fallback; optional native stub spawn path.
    - **Files:** `skills/mas-coordinator/SKILL.md`
    - **Acceptance:** Coordinator references policy file only (no hard-coded opus strings); MCP lazy-load note ("do not preload MCP catalogs").

12. **Create `platform-parity.md`** — IDE vs CLI vs Cloud Agent capability matrix.
    - **Files:** `skills/multi-agent-system/protocol/platform-parity.md` (new)
    - **Required rows:** Task tool, project hooks, user hooks, `sessionStart`, adb/device prep (MAS-07), `/mas` Coordinator, MCP, Plan Mode
    - **Acceptance:** Documents adb incompatibility for default Cloud Agent VM; plugin vs global precedence (Q1); enterprise hook merge note (Q4).

13. **Add specialist skill `paths:` globs** — Reduce ambient skill injection (Cursor 2.4+); scope to `.ai/**`, relevant `skills/**`.
    - **Files:** Top specialist `SKILL.md` frontmatter updates (batch per architect list)
    - **Acceptance:** `disable-model-invocation: true` unchanged on coordinator skills; commands retained for `$ARGUMENTS`.

14. **Optional: `agent-models-probe` script** — Non-blocking CLI helper for dogfood model enum refresh (P1 optional).
    - **Files:** `skills/multi-agent-system/scripts/agent-models-probe.ps1` (optional)
    - **Acceptance:** Documents output format; does not block Coordinator startup.

---

### Phase P2 — Async audit lane + MCP template

15. **Implement `PARALLEL_AUDIT` coordinator rules** — After dev complete, spawn dependency-risk, api-contract, security-auditor with `run_in_background: true` when handoff `PARALLEL_AUDIT: yes`; parent verifies brief paths exist before reviewer.
    - **Files:** `skills/mas-coordinator/SKILL.md`, `skills/mas-lite/SKILL.md` (lite ignores flag)
    - **Preconditions:** `readonly: true` on auditors; distinct output paths; no shared FILES mutation; distinct TASK_ID suffixes if needed
    - **Acceptance:** Three audit briefs exist before reviewer spawn; `PARALLEL_AUDIT: no` preserves MAS-04-FIX-P0-ALL sequential regression.

16. **Ship MCP plugin template stubs** — Optional `mcp.json` with env placeholders (Figma, browser); no bundled server code.
    - **Files:** `.cursor/mcp.json` template or plugin-bundled stub; `permissions.json` / Auto-review docs slice in README
    - **Acceptance:** Users without MCP still work; secrets via env vars only.

17. **Optional `beforeMCPExecution` hook** — Audit log MCP server + tool name (fail-open).
    - **Files:** `.cursor/hooks.json` template, hook script extension
    - **Acceptance:** Log only; optional enterprise deny list documented in platform-parity.

18. **Update `mas-figma` / `mas-visual-fidelity` skills** — On-demand MCP load contract per Cursor 2.4.
    - **Files:** `skills/mas-figma/SKILL.md`, `skills/mas-visual-fidelity/SKILL.md`
    - **Acceptance:** Document lazy MCP load; auth failure → brief notes BLOCKED; workflow continues.

---

### Phase P3 — Plan Mode bridge (optional v1.6.x)

19. **Extend `mas-planner/SKILL.md`** — Optional `PLAN_MODE: export` writes plan to `.cursor/plans/` or workspace plan path; dedupe when Plan Mode plan already exists.
    - **Files:** `skills/mas-planner/SKILL.md`
    - **Acceptance:** Planner brief sections mirror Plan Mode todos; Coordinator may suggest Shift+Tab Plan Mode for greenfield before `/mas`.

---

### Phase Dogfood + documentation

20. **Create dogfood fixtures** — Handoff + hook JSON fixtures for P0/P1 validation.
    - **Files:** `.ai/fixtures/MAS-08-PLUGIN/` (plugin.json sample, hooks.json sample, handoff-delegate-explore.md, handoff-parallel-audit.md)
    - **Acceptance:** Covers plugin validate, subagentStart pass/fail, model fallback, delegation map examples.

21. **Framework dogfood workflow `MAS-08`** — Self-install plugin + run osint→brainstorm with project hooks; verify session JSON telemetry fields.
    - **Files:** `.ai/context/workflow-sessions/MAS-08.json` (append during dogfood), `.ai/context/test-strategies/MAS-08.md` (logic-layer test matrix per brainstorm Quality Bar)
    - **Acceptance:** Project hooks fire on Cloud-compatible path; `inherit` dev spawn records `model_class` in session JSON.

22. **Documenter pass** — README: plugin install, air-gapped fallback, hook bootstrap, precedence table, command visibility toggle troubleshooting, when to use MAS vs Cloud Agents.
    - **Files:** `README.md`, `skills/multi-agent-system/SKILL.md` (v1.6 roster note)

23. **Reviewer — dogfood validation** — Schema compliance, invariants unchanged, platform-parity completeness, regression MAS-04 sequential audit with `PARALLEL_AUDIT: no`.
    - **Acceptance:** Quality Bar checklist from brainstorm §Quality Bar satisfied; grep confirms no hard-coded opus strings in coordinator skill; reviewer gate unchanged.

## Dependencies

| Task | Depends on | Reason |
|------|------------|--------|
| 2–8 (P0 plugin + hooks + policy) | 1 (architect) | Layout, hook contracts, manifest sync strategy |
| 5 (hook scripts) | 4 (bootstrap template) | Event names and script paths |
| 6 (model policy) | 1 | Class→hint table and inherit defaults |
| 9–14 (P1 stubs + delegation) | 1, 6 | Stub model frontmatter; spawn doc alignment |
| 12 (platform-parity) | 1, 4 | Cloud/hook/adb matrix needs bootstrap truth |
| 15–18 (P2 async + MCP) | 1, 10, 11 | Coordinator rules depend on spawn + delegation contracts |
| 19 (Plan Mode) | 1 | Export path convention |
| 20–23 (dogfood + docs + review) | 2–19 (P0 minimum for review) | End-to-end validation |

**External dependencies:** Cursor 2.5+ for plugin + async subagents; Cursor docs for plugin schema validation; optional MCP servers (Figma, browser) for P2 dogfood only.

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Model enum volatility | H | `inherit` + `default` fallback; optional probe script (Task 14); no hard-coded slugs in coordinator |
| Plugin marketplace review delay | M | Keep air-gapped install script primary for contributors (Task 8) |
| Hook over-automation blocks manual Tasks | M | fail-open v1.6; matchers scoped to MAS Task descriptions |
| Dual maintenance skill + agent stub | M | CI generation from manifest (Q6); thin wrappers only |
| Async audit race on FILES | M | `readonly: true`; distinct brief paths; parent verification (Task 15) |
| Plugin + global skill name collision | M | Document precedence (Q1); project paths win |
| User confusion MAS vs Cloud Agents | M | `platform-parity.md` + coordinator when-to-use table (Task 12) |
| Enterprise team hooks merge | M | Document ordering (Q4); architect dogfood |
| Command visibility toggle (forum 3.9.8) | L | README troubleshooting (Task 22) |

## Build & Test Plan

**Gradle / compile:** N/A — `UI_SCOPE: logic-only`; no Android modules in MAS framework repo.

**Verification surfaces:**

| Layer | Command / action | Owner |
|-------|------------------|-------|
| Plugin manifest | Validate `.cursor-plugin/plugin.json` against Cursor plugin schema; skill list ⊆ `install/manifest.json` | general-dev |
| Install smoke | Plugin path happy path + air-gapped init script dry-run | general-dev |
| Hooks fixtures | `subagentStart` validator JSON in/out; `subagentStop` followup shape | general-dev |
| Model policy | Table-driven: each slug → class → hint; unknown slug → `default`; stale slug rejection → fallback | reviewer |
| Bootstrap | Fresh repo emits `.cursor/hooks.json` with `version: 1` | test-executor (fixture) |
| Delegation | Handoff fixtures: `DELEGATE: explore|bash|browser` maps in spawn doc examples | reviewer |
| Session telemetry | `record-workflow-step` fields present in workflow session JSON after dogfood | reviewer |
| Regression | MAS-04-FIX-P0-ALL sequential chain with `PARALLEL_AUDIT: no` | reviewer |
| Protocol grep | No `claude-opus-4-7` in coordinator skill; `inherit` in dev-class rows | reviewer |
| Dogfood chain | MAS-08 self-install plugin + osint→brainstorm with project hooks | coordinator (manual) |

**Framework dogfood (no marketplace required):**

```powershell
# Air-gapped init + bootstrap hooks
powershell -File skills/multi-agent-system/install/init-mas-context.ps1 -BootstrapProject

# Hook validator fixture (architect defines harness)
powershell -File .cursor/hooks/validate-subagent-start.ps1 -HandoffPath .ai/fixtures/MAS-08-PLUGIN/handoff-spawned.md
```

**test-strategy agent:** Task 21 — logic-layer test matrix (install, hooks, model policy, delegation, regression) per brainstorm Quality Bar §Test strategy.

**Optional live smoke:** Install plugin from local bundle in Cursor IDE; run `/mas` on synthetic TASK_ID; confirm project hooks fire and session JSON appends step with `plugin_version`.

## Visual QA Scenarios

N/A — `UI_SCOPE: logic-only` for framework changes.

**Reviewer dogfood (protocol + hook behavior):**

| Config | State | Expected |
|--------|-------|----------|
| Plugin install happy path | marketplace or local | Skills/rules/commands load; version from manifest |
| Air-gapped init | no marketplace | Global install script succeeds |
| Fresh repo bootstrap | first `/mas` | `.cursor/hooks.json` + scripts in `.cursor/hooks/` |
| Cloud Agent run | repo hooks committed | `subagentStop` followup from project hooks |
| Stale model slug spawn | Task rejection | Fallback `default`; chain continues; logged in session |
| `inherit` dev spawn | general-dev | Session JSON records correct `model_class` |
| `DELEGATE: explore` osint | FILES empty | Brief at `.ai/context/osint/{TASK_ID}.md`; explore supplements only |
| `PARALLEL_AUDIT: yes` | post-dev | Three audit briefs before reviewer |
| `PARALLEL_AUDIT: no` | MAS-04 regression | Sequential audit chain unchanged |
| Reviewer gate | any hook event | No auto-approve from hooks |
| Cloud + MAS-07 device | adb workflow | platform-parity documents SKIP / BLOCKED path |

## Required Agents

| Agent | When | Scope |
|-------|------|-------|
| **architect** | Task 1 — before edits | Plugin topology, hook contracts, stub template, CI sync, Q1–Q7 confirmation |
| **general-dev** | Tasks 2–19, 20 | Plugin manifest, bootstrap, hooks, policy, stubs, protocol, coordinator/specialist skill updates, MCP template |
| **test-strategy** | Task 21 — after P0 | Logic-layer test matrix; install/hooks/model/delegation/regression cases |
| **test-executor** | Optional — hook fixture runs | Bootstrap smoke; prep-style fixture harness if architect assigns |
| **documenter** | Task 22 | README plugin install, precedence, Cloud vs local, troubleshooting |
| **reviewer** | Task 23 | Invariants, Quality Bar checklist, regression, schema compliance |

**Not required:** android-dev (no app code); ux-intelligence (no UI screens); new specialist slug; osint/brainstorm/planner (briefs exist for MAS-08 planning chain).

## Acceptance criteria

1. **Plugin packaging:** `.cursor-plugin/plugin.json` ships; plugin installs without manual file copy (happy path); skill list matches `install/manifest.json` subset.
2. **Air-gapped fallback:** Init/export script still works when marketplace unavailable.
3. **Project hooks:** Fresh repo bootstrap creates `.cursor/hooks.json` with `version: 1` schema; scripts copied to `.cursor/hooks/`.
4. **Cloud parity:** Cloud Agent run triggers `subagentStop` followup from **project** hooks (not user-only hooks).
5. **Model policy:** `spawn-model-policy.md` uses `inherit` for dev-class agents; class→hint table with `default` fallback; `MODEL_SLUG:` override documented; stale slug spawn does not abort chain.
6. **Handoff extensions:** `DELEGATE`, `PARALLEL_AUDIT`, `PLAN_MODE` fields documented in handoff-format.
7. **Native stubs:** Top 8 `.cursor/agents/*.md` stubs exist; align with spawn-model-policy models.
8. **Delegation map:** `subagent-spawn.md` documents explore/bash/browser routing; built-in output does not replace brief files.
9. **Parallel audit (opt-in):** `PARALLEL_AUDIT: yes` produces three audit briefs before reviewer; default `no` preserves sequential MAS-04 regression.
10. **Platform parity:** `platform-parity.md` documents IDE/CLI/Cloud matrix including adb Cloud incompatibility.
11. **Invariants:** Reviewer sole `Approved:` gate unchanged; foreground dev chain unchanged; self-contained Task prompts unchanged.
12. **MCP template (P2):** Optional `mcp.json` stubs with env placeholders only; lazy-load documented in figma/visual-fidelity skills.
13. **Telemetry:** Session JSON includes `plugin_version`, `hooks_schema_version`, `model_class`, optional `delegate`.
14. **Security:** Hook scripts read-only validation; no brief body in logs; no secrets in plugin bundle.
15. **Semver:** `install/manifest.json` bumped to `1.6.0`; framework dogfood TASK_ID validates P0 path.

## Usage Report

Model: default
Class: normal
Tokens: unknown

DONE
