# Brainstorm Brief — MAS-08

## Problem & User Outcome

**Problem:** MAS v1.5.0 is directionally aligned with Cursor (Skills, Task subagents, hooks, MCP, rules) but **distribution, hook depth, model policy freshness, and delegation strategy** lag Cursor 2.5+ platform primitives (Plugins, project hooks, native `.cursor/agents/`, async subagents, expanded hook catalog, model enum drift). Users install via manual copy-to-`~/.cursor`; Cloud Agents cannot see user-level hooks; `spawn-model-policy.md` hard-codes slugs like `composer-2.5-fast` and `claude-opus-4-7-thinking-high` that drift per release; all specialists spawn as `generalPurpose` with full skill context even when platform built-ins (`explore`, `bash`, `browser`) would be cheaper and better routed.

**User outcome:** After v1.6+, a developer installs MAS as a **Cursor Plugin** (or air-gapped fallback script), runs `/mas` or `/mas-lite` on any repo, and gets **reliable specialist chains** with repo-local hooks (Cloud Agent parity), **current model resolution** (`inherit` + class-based fallback), and **selective platform delegation** — while preserving MAS's differentiator: durable `.ai/handoffs/` + `.ai/context/{brief-type}/` artifacts and reviewer-gated `Approved:` workflow.

**UI scope:** `logic-only` (per handoff). Covers orchestration contracts, hook events, spawn parameters, plugin manifest, model resolution, delegation maps, and platform parity documentation. No IDE UI layouts, marketplace screenshots, or styling.

**OSINT delta:** OSINT (`.ai/context/osint/MAS-08.md`) identifies P0: plugin packaging, project hooks, model policy refresh; P1: hybrid native subagents + built-in delegation; P2: async audit lane, MCP template, Plan Mode bridge. This brief evaluates **implementation options and tradeoffs** for those findings. Does **not** re-research externally.

**Prior-art delta:** MAS-04/05/06/07 extended specialist roster, Figma/visual-fidelity, and device prep — all assume `subagent_type: generalPurpose`, `run_in_background: false`, user-level `hooks.json`. Framework seed: `install/manifest.json` v1.5.0, `subagent-spawn.md`, `spawn-model-policy.md`, `hooks/mas-session-context.ps1`, `rules/multi-agent-hybrid.mdc`.

---

## Options

| # | Option | Pros | Cons | Risk | Effort | Fits memory? |
|---|--------|------|------|------|--------|--------------|
| 1 | **Docs-only refresh** — Update README + `spawn-model-policy.md` with `inherit` guidance and Cloud vs local table; no plugin manifest, no project hooks, keep user-level install | Smallest diff; no marketplace review; zero hook script maintenance | No discoverability; Cloud Agents still miss user hooks; model drift recurs each Cursor release; no token savings from built-in subagents | M | S | Partial |
| 2 | **Platform-native plugin + phased protocol upgrade** (recommended) — `.cursor-plugin/plugin.json` bundling skills/rules/commands/hooks; bootstrap writes **project** `.cursor/hooks.json`; refresh model policy (`inherit` default, class→hint table, `MODEL_SLUG:` override); hybrid `.cursor/agents/` stubs for top specialists; delegation map (`osint→explore`, `test-executor→bash`, `visual-qa→browser`); optional `PARALLEL_AUDIT` async lane; MCP stubs + `platform-parity.md` | Aligns with Cursor 2.5 distribution; Cloud Agent hook parity; reduces token load; preserves MAS artifact model; air-gapped install script remains fallback | Dual maintenance (skill + agent file); hook failure surface grows; async audit needs parent verification discipline; plugin vs global precedence unclear | L | M | Y |
| 3 | **Full platform replacement** — Replace Coordinator Task chain with Cloud Agents/Projects as primary orchestrator; native subagents only; default `run_in_background: true` for all post-dev specialists; deprecate handoff files in favor of project context | Maximum parallelism; lowest coordinator token cost in cloud | Breaks reviewer `Approved:` gate semantics; races on shared FILES; adb/device prep (MAS-07) incompatible with default cloud VM; loses supply-chain brief schema gates; forum reports async parent verification gaps | H | L | N |
| 4 | **Minimal plugin, maximal hooks** — Ship plugin for distribution only; invest heavily in `subagentStart`/`postToolUse`/`stop`/`preCompact` hooks; defer agent stubs and built-in delegation | Strong automation and telemetry; Cloud parity for chain reminders | Does not fix model enum rot or Task routing hints; coordinators still pay full generalPurpose context tax | M | M | Partial |

**Fits existing patterns?** Option 2: Y — extends `install/manifest.json`, `subagent-spawn.md`, `mas-session-context` hook pattern, MAS-04 sequential specialist chains. Option 3: N — contradicts memory.md reviewer gate and MAS-07 local adb constraint.

---

## Recommended

**Option 2 — Platform-native plugin with phased protocol upgrade (P0 → P1 → P2).**

**Rationale vs alternatives:**

- **vs Option 1 (docs-only):** OSINT Finding #2 (project hooks) is blocking for team repos and Cloud Agents — documentation cannot fix hook visibility. Model policy without structural `inherit` defaults will rot again within one Cursor release cycle.
- **vs Option 3 (full replacement):** MAS differentiator is **repo-local, reviewer-gated, brief-on-disk** workflows with Android device prep and P0 audit quartet — Cloud Agents optimize long-horizon cloud work, not the same trust model. Sequential dev chain must stay foreground; parallelize **independent audit briefs only** when `PARALLEL_AUDIT: yes`.
- **vs Option 4 (hooks-only):** Hooks automate chain discipline but do not reduce spawn cost or improve Task routing. Built-in `explore` for OSINT codebase sweep and `bash` for test-executor are platform-recommended token wins.

**Non-negotiable invariants (do not change):**

- Reviewer sole `Approved:` gate
- Foreground sequential dev → ux → a11y → i18n chain (same FILES)
- Self-contained Task prompts (subagents do not receive User Rules)
- Hybrid rule `multi-agent-hybrid.mdc` with `alwaysApply` — ambient `/mas` activation prevented
- Artifact-forward — hooks never inject full brief bodies into `additional_context`

---

## Logic Flow

### A. Target architecture (v1.6+)

```
User: /mas | /mas-lite | Custom Mode (Coordinator pinned)
        ↓
Coordinator skill (disable-model-invocation: true)
        ↓
Write handoff (.ai/handoffs/{TASK_ID}.md, SPAWN_STATUS: spawned)
        ↓
Resolve model (MODEL_CLASS → class table → inherit/default fallback)
        ↓
Task spawn
        ├─ MAS specialist: generalPurpose + self-contained prompt (current default)
        ├─ OR thin .cursor/agents/{slug}.md wrapper (same prompt, model frontmatter)
        ├─ OR built-in: explore | bash | browser (platform delegation per map)
        ↓
Project hooks (.cursor/hooks.json in repo)
        ├─ subagentStart: validate TASK_ID + handoff exists; set env
        ├─ subagentStop: followup_message chain reminder (existing mas-session-context)
        ├─ postToolUse (matcher Task): record-workflow-step telemetry
        ├─ stop: finalize workflow session JSON
        └─ preCompact: warn if briefs/handoffs not flushed to disk
        ↓
Specialist writes brief → SPAWN_STATUS: complete → next handoff
        ↓
Reviewer Approved: YES | NO → loop or user escalation
```

### B. Install / distribution state machine

| State | Trigger | Action |
|-------|---------|--------|
| `UNINSTALLED` | User new to MAS | Install via Plugin marketplace **or** `init-mas.ps1` air-gapped |
| `PLUGIN_ACTIVE` | `.cursor-plugin/plugin.json` present | Skills/rules/commands load from plugin bundle; version from manifest |
| `GLOBAL_FALLBACK` | Plugin unavailable | Copy to `~/.cursor/skills/` per existing install script |
| `PROJECT_BOOTSTRAPPED` | First `/mas` on repo | Emit `.ai/` scaffold + `.cursor/hooks.json` + hook scripts to `.cursor/hooks/` |
| `COLLISION` | Plugin + global same skill name | Document precedence in README; prefer project-scoped paths |

### C. Model resolution flow

```
1. Handoff MODEL_CLASS (full) or MC (lite) if set
2. Else spawn-model-policy default for TARGET_AGENT slug
3. Map class → Task model hint:
     fast    → latest composer-*-fast family OR inherit for dev-class agents
     normal  → inherit (preferred) OR default
     thinking → latest thinking-high family OR inherit
4. Handoff MODEL_SLUG: explicit override (optional v1.6)
5. Task spawn; on rejection → model: default, record in session step
6. Telemetry: record-workflow-step.ps1 -ModelClass + resolved slug
```

**Policy change:** Default **dev-class** agents (`general-dev`, `android-dev`, `bug-fix`) to `inherit` so parent Coordinator model flows down — matches MAS-07 dogfood pattern in memory.md.

### D. Hybrid subagent delegation map (Coordinator decision)

| Handoff `TARGET_AGENT` | Default `subagent_type` | When to use built-in | Handoff flag |
|------------------------|---------------------------|----------------------|--------------|
| osint | `generalPurpose` | `explore` when FILES empty and codebase discovery needed | `DELEGATE: explore` |
| test-executor | `generalPurpose` | `bash` when commands are shell-only (prep + gradle + adb) | `DELEGATE: bash` |
| mas-visual-fidelity (browser capture) | `generalPurpose` | `browser` when MCP browser tab required | `DELEGATE: browser` |
| All other MAS specialists | `generalPurpose` | Never replace — skill + brief schema required | — |

**Rule:** Built-in delegates are **supplements** — handoff `FILES` and `BRIEF_PATH` remain authoritative; explore output does not replace OSINT brief file.

### E. Parallel audit lane (opt-in P2)

```
dev complete → handoff PARALLEL_AUDIT: yes
        ↓
Coordinator spawns (mutually exclusive brief paths):
  dependency-risk | api-contract | security-auditor  [run_in_background: true]
        ↓
Coordinator waits / collects (parent MUST verify DONE + brief paths exist)
        ↓
Sequential: test-executor → documenter → reviewer
```

** Preconditions:** `readonly: true` on auditors; distinct output paths (`.ai/context/supply-chain/`, `api-contracts/`, `security-audits/`); no shared FILES mutation.

### F. Hook event contracts

| Event | Matcher | Purpose | Fail mode |
|-------|---------|---------|-----------|
| `subagentStart` | Task / generalPurpose | Deny if handoff missing `SPAWN_STATUS: spawned` or TASK_ID | fail-open (warn only v1.6; strict deny v1.7 opt-in) |
| `subagentStop` | * | `followup_message` → Coordinator chain reminder | existing behavior |
| `postToolUse` | Task | Invoke `record-workflow-step.ps1` | fail-open |
| `stop` | session | Finalize `.ai/context/workflow-sessions/{TASK_ID}.json` | fail-open |
| `preCompact` | * | Warn if `.ai/handoffs/` has incomplete spawns | fail-open |
| `beforeMCPExecution` | optional P2 | Audit log MCP server + tool name | fail-open |

**Cloud Agent rule:** Only **repo-committed** `.cursor/hooks.json` runs — bootstrap must not rely on `~/.cursor/hooks.json` alone.

### G. Phase delivery sequence

| Phase | Deliverables | Rationale |
|-------|--------------|-----------|
| **P0** | `.cursor-plugin/plugin.json`; project hooks bootstrap; `spawn-model-policy` refresh (`inherit`, fallback table); README model CLI note | Distribution + reliability |
| **P1** | `.cursor/agents/` stubs (top 8: coordinator-adjacent: osint, brainstorm, planner, architect, general-dev, reviewer, test-executor, security-auditor); `subagent-spawn.md` delegation table; `platform-parity.md` | Routing + token efficiency |
| **P2** | `PARALLEL_AUDIT` handoff flag + coordinator rules; MCP `mcp.json` stubs; `beforeMCPExecution` optional hook; skills `paths` globs for `.ai/**` | Speed + MCP completeness |
| **P3** | Planner `PLAN_MODE: export` → `.cursor/plans/` compatibility | UX bridge for greenfield |

---

## Domain & Contracts

### Entities

| Entity | Location | Owner | Lifecycle |
|--------|----------|-------|-----------|
| `PluginManifest` | `.cursor-plugin/plugin.json` | framework release | versioned semver |
| `InstallManifest` | `skills/multi-agent-system/install/manifest.json` | framework | source of truth for skill list; plugin references |
| `Handoff` | `.ai/handoffs/{TASK_ID}[-{agent}].md` | Coordinator | per spawn; `SPAWN_STATUS` |
| `WorkflowSession` | `.ai/context/workflow-sessions/{TASK_ID}.json` | hooks + Coordinator | append-only steps |
| `NativeAgentStub` | `.cursor/agents/{slug}.md` | framework | thin wrapper; mirrors skill slug |
| `ProjectHooks` | `.cursor/hooks.json` | bootstrap script | committed per repo |
| `PlatformParityMatrix` | `protocol/platform-parity.md` | documenter | IDE / CLI / Cloud |

### Handoff extensions (v1.6)

| Field | Values | When |
|-------|--------|------|
| `MODEL_SLUG:` | explicit Task model enum | override policy hint |
| `DELEGATE:` | `explore` \| `bash` \| `browser` | built-in subagent routing |
| `PARALLEL_AUDIT:` | `yes` \| `no` (default no) | P2 async audit quartet |
| `PLAN_MODE:` | `export` | P3 planner artifact path |

### Plugin manifest sketch (logic contract)

```json
{
  "name": "mas-cursor-framework",
  "version": "1.6.0",
  "skills": ["./skills/..."],
  "rules": ["./rules/multi-agent-hybrid.mdc"],
  "commands": ["./commands/mas.md", "./commands/mas-lite.md"],
  "hooks": "./.cursor/hooks.json"
}
```

Canonical skill list remains `install/manifest.json` — plugin `plugin.json` imports or duplicates with CI sync check.

### Model class → hint table (refreshed policy intent)

| `MODEL_CLASS` | Primary hint | Fallback |
|---------------|--------------|----------|
| `fast` | `composer-2.5-fast` or latest `*-fast` | `default` |
| `normal` | `inherit` | `default` |
| `thinking` | latest thinking-high family | `default` |

Remove hard-coded `claude-opus-4-7-*` strings from coordinator prompts; reference policy file only.

### Skills metadata contracts

- `disable-model-invocation: true` on `multi-agent-system`, `mas-coordinator`, `mas-lite` (unchanged)
- Add `paths:` globs on specialists: `.ai/**`, relevant `skills/**` — reduce ambient skill injection (Cursor 2.4+)
- Keep `mas` / `mas-lite` **commands** for `$ARGUMENTS` passthrough — skills lack positional args

### MCP lazy-load contract (P2)

- Coordinator prompt: **do not preload** MCP tool catalogs
- Plugin ships optional `mcp.json` stubs (Figma, browser) with env placeholders — no bundled server code
- `mas-figma` / `mas-visual-fidelity` skills document on-demand MCP load per Cursor 2.4 behavior

### Platform parity matrix (required rows)

| Capability | Local IDE | CLI | Cloud Agent |
|------------|-----------|-----|-------------|
| Task tool | yes | partial | yes |
| Project hooks | yes | yes | yes (repo only) |
| User hooks (`~/.cursor`) | yes | yes | **no** |
| `sessionStart` hook | yes | varies | **no** |
| adb / device prep (MAS-07) | yes | yes if host | **no** (default) |
| `/mas` Coordinator | yes | user-driven | not equivalent |

---

## Edge Cases

| Case | Behavior | Owner |
|------|----------|-------|
| Task `model` hint rejected | Spawn with `default`; log in session step | Coordinator |
| Plugin + global skill name collision | Document precedence; project paths win | README / install |
| `subagentStart` deny on manual Task | fail-open v1.6 — do not block non-MAS Tasks | hook script |
| Async auditor writes same brief path | FORBIDDEN — coordinator must assign distinct TASK_ID suffixes | Coordinator |
| Async parent skips verification | Coordinator polls brief file existence before reviewer | Coordinator |
| `preCompact` during active spawn | Warn; list incomplete handoffs | hook |
| Cloud Agent on MAS-07 device workflow | SKIP device prep with `BLOCKED: no adb`; route user to local IDE | test-executor |
| Enterprise team hooks + project hooks | Document merge order; project deny wins for MAS events | platform-parity.md |
| Commands hidden (third-party plugins toggle) | README troubleshooting: enable toggle + reload | documenter |
| `inherit` on thinking-class reviewer | Allow — parent may already be thinking model | spawn-model-policy |
| Lite mode `PARALLEL_AUDIT` | Ignored — lite stays sequential (max 1–3 foreground) | mas-lite skill |
| Hook script missing on Windows | Bootstrap copies `.ps1` + `.sh` to `.cursor/hooks/` | init script |
| Plan Mode + `/mas` both run | Planner checks `.cursor/plans/` for existing plan; dedupe or `PLAN_MODE: export` only | planner |
| MCP server auth failure | Specialist brief notes BLOCKED; workflow continues without MCP | specialist |
| Nested spawn depth > 2 | Coordinator must not chain async inside async | subagent-spawn.md |
| Forum `is_background` frontmatter unreliable | Use Task `run_in_background` param only; not agent file frontmatter until 2.6+ stable | protocol note |

---

## Quality Bar

### Acceptance criteria (testable without UI)

- [ ] Plugin installs from manifest without manual file copy (happy path)
- [ ] Air-gapped `init-mas.ps1` still works when marketplace unavailable
- [ ] Fresh repo bootstrap creates `.cursor/hooks.json` with `version: 1` schema
- [ ] Cloud Agent run triggers `subagentStop` followup from **project** hooks
- [ ] Spawn with stale model slug falls back to `default` without aborting chain
- [ ] `inherit` dev spawn records correct `model_class` in session JSON
- [ ] `DELEGATE: explore` osint completes with brief at `.ai/context/osint/{TASK_ID}.md`
- [ ] `PARALLEL_AUDIT: yes` produces three audit briefs before reviewer spawn
- [ ] Reviewer `Approved:` gate unchanged — no auto-approve from hooks
- [ ] `platform-parity.md` documents adb incompatibility for Cloud Agents

### Test strategy (logic layer)

| Layer | Tests |
|-------|-------|
| **Install** | Smoke: plugin.json validates against Cursor plugin schema; manifest skill list ⊆ plugin bundle |
| **Hooks** | Fixture JSON in/out for `subagentStart` validator; `subagentStop` followup_message shape |
| **Model policy** | Table-driven: each slug resolves class; unknown slug → default |
| **Delegation** | Handoff fixtures: `DELEGATE: bash` maps to `subagent_type: bash` in spawn doc examples |
| **Regression** | MAS-04-FIX-P0-ALL sequential audit chain still passes with `PARALLEL_AUDIT: no` |
| **Dogfood** | MAS-08 workflow self-install plugin + run osint→brainstorm with project hooks |

### Observability

- `record-workflow-step.ps1` fields: `agent`, `model`, `model_class`, `subagent_type`, `delegate`, `duration_ms`
- Hook `postToolUse`: log Task description + TASK_ID — no brief body, no PII
- Session JSON: `platform: ide|cli|cloud`, `plugin_version`, `hooks_schema_version`

### Security

- Hook scripts: read-only validation; no arbitrary code exec from handoff content
- `beforeMCPExecution`: log only; deny list optional for enterprise
- Plugin bundle: no secrets in `mcp.json` — env var placeholders only
- `subagentStart` deny: never pass user handoff content to shell unescaped

### Rollback / feature flags

| Flag | Default | Rollback |
|------|---------|----------|
| `PARALLEL_AUDIT` | `no` | Set `no` on handoff |
| `DELEGATE:*` | unset (generalPurpose) | Omit field |
| Strict `subagentStart` deny | off v1.6 | Toggle in hooks.json |
| Plugin install | opt-in marketplace | Revert to global install script |

---

## Risks & Open Questions

### Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Model enum volatility | H | `inherit` default + `default` fallback; optional runtime `agent models` probe script |
| Async audit race on FILES | M | `readonly: true`; distinct brief paths; parent verification step |
| Dual maintenance skill + agent stub | M | Generate stubs from manifest in CI; single prompt template |
| Plugin marketplace review delay | M | Keep install script as primary for contributors; plugin for consumers |
| Hook over-automation blocks manual Tasks | M | fail-open defaults; matcher scoped to MAS Task descriptions |
| User confusion MAS vs Cloud Agents | M | `platform-parity.md` + coordinator "when to use" table |
| Command visibility toggle (forum 3.9.8) | L | Document in README troubleshooting |

### Open questions (for Planner / Architect)

1. **Plugin vs global precedence** — When both install, which `mas-coordinator` skill wins? Need Cursor docs clarification or dogfood test.
2. **Runtime model probe** — Ship static table + quarterly refresh, or `agent models` script invoked at Coordinator startup?
3. **Programmatic Coordinator** — Will Cursor expose APIs beyond `subagentStop` followup for fully automated chains without user-in-the-loop?
4. **Enterprise team hooks merge** — Ordering when org hooks and project MAS hooks both define `subagentStart`?
5. **`is_background` reliability** — Defer `PARALLEL_AUDIT` default until forum confirms 2.6+ parent verification fix?
6. **Stub generation** — CI job from `install/manifest.json` → `.cursor/agents/*.md` or hand-maintained top 8?
7. **CLI `/mas` parity** — Which Coordinator steps work headless vs IDE-only Task tool?

---

## Suggested Next

**planner** — Break P0/P1/P2 into ordered tasks with dependencies (plugin manifest → hooks bootstrap → model policy → agent stubs → delegation map → parallel audit → MCP template → Plan Mode bridge); acceptance criteria per phase above.

**architect** (after planner) — Module structure for `.cursor-plugin/`, `.cursor/agents/`, hook scripts layout, `platform-parity.md` location, CI sync between `install/manifest.json` and plugin bundle.

---

## References

- `.ai/context/osint/MAS-08.md` — upstream research
- `skills/multi-agent-system/install/manifest.json` — v1.5.0 skill inventory
- `skills/multi-agent-system/protocol/subagent-spawn.md` — current spawn contract
- `skills/multi-agent-system/protocol/spawn-model-policy.md` — model class map (needs refresh)
- `skills/multi-agent-system/protocol/brief-schemas.md` — brainstorm required sections
- `.ai/context/memory.md` — MAS-04/05/06/07 architecture decisions; reviewer gate; device prep
- `.ai/context/brainstorms/MAS-07.md` — prior brainstorm pattern (composite script + schema)
