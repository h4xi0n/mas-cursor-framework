# OSINT Brief — MAS-08

## Research Mode

FEATURE

## Topic

What can improve the MAS multi-agent framework to work better with the latest Cursor IDE build (2025–2026)?

## Scope

`mas-cursor-framework` — `skills/`, `protocol/`, Coordinator + Task (`generalPurpose`, foreground), MCP integration, hooks, rules, slash commands, model policy, token efficiency. Compared against Cursor platform capabilities as of changelog 2.5 (Feb 2026) and current docs.

## Research Summary

Cursor has converged on the same primitives MAS already uses — **Skills** (`SKILL.md`), **Task subagents**, **hooks**, **MCP**, and **rules** — but shipped them as first-class platform features with **Plugins** (2.5), **native subagent files** (`.cursor/agents/`), **async/nested subagents**, **Cloud Agents / Projects**, and a greatly expanded **hooks surface** (`subagentStart`, `preToolUse`, `stop`, `preCompact`, MCP gates). MAS v1.5.0 is directionally aligned (Coordinator + skills + handoffs + `subagentStop` chain reminder) but **distribution, hook depth, model policy freshness, and parallelism** lag the platform. Highest-impact upgrades: (1) package MAS as a Cursor Plugin with project-level `.cursor/hooks.json`, (2) refresh spawn-model-policy for 2026 model slugs with `inherit` defaults, (3) hybrid native subagents for built-in `explore`/`bash`/`browser` plus MAS specialists, (4) selective async spawn for independent audit lanes, (5) document Cloud Agent / CLI parity boundaries so users know when `/mas` applies.

## Sources Consulted

| # | Source | Tier | Date | Version | Notes |
|---|--------|------|------|---------|-------|
| 1 | [Cursor Changelog 2.5 — Plugins, async subagents](https://cursor.com/changelog/2-5) | official | 2026-02-17 | 2.5 | Plugin bundles; async + nested subagents |
| 2 | [Cursor Changelog 2.4 — Subagents, Skills](https://cursor.com/changelog/2-4) | official | 2026-01-22 | 2.4 | Agent Skills; MCP lazy load in `.cursor` |
| 3 | [Cursor Changelog 1.7 — Hooks beta](https://cursor.com/changelog/1-7) | official | 2025 | 1.7 | Hooks introduction; MCP autorun |
| 4 | [Cursor Changelog CLI Jan 2026](https://cursor.com/changelog/cli-jan-08-2026) | official | 2026-01-08 | CLI | `/models`, `/mcp`, `/rules`; hooks 10× faster |
| 5 | [Cursor Docs — Hooks](https://cursor.com/docs/hooks) | official | 2026-03 | — | Full hook catalog; cloud agent support matrix |
| 6 | [Cursor Docs — Subagents](https://cursor.com/docs/context/subagents) | official | 2026-03 | — | Built-in explore/bash/browser; `.cursor/agents/` format |
| 7 | [Cursor Docs — Agent Skills](https://cursor.com/docs/skills) | official | 2026-03 | — | `disable-model-invocation`, `paths`, `/migrate-to-skills` |
| 8 | [Cursor Docs — MCP](https://cursor.com/docs/mcp) | official | 2026-03 | — | `.cursor/mcp.json`; marketplace; permissions |
| 9 | [Cursor Docs — Cloud Agents](https://cursor.com/docs/cloud-agents) | official | 2026-03 | — | VM agents; MCP; project hooks only |
| 10 | [Cursor Docs — Plan Mode](https://cursor.com/docs/agent/plan-mode) | official | 2026-03 | — | Pre-build plans; workspace-save |
| 11 | [Cursor Docs — Plugins reference](https://cursor.com/docs/reference/plugins) | official | 2026-03 | — | `.cursor-plugin/plugin.json` manifest |
| 12 | [Forum — Async subagents 2.5](https://forum.cursor.com/t/cursor-2-5-async-subagents/152125) | community | 2026-02 | 2.5 | `is_background` quirks; parent verification gap |
| 13 | [Forum — Subagent model/control](https://forum.cursor.com/t/subagent-control-via-rules-and-settings/159562) | community | 2026 | 3.2.x | Task params; model enum drift |
| 14 | MAS local: `skills/multi-agent-system/protocol/subagent-spawn.md`, `spawn-model-policy.md`, `install/manifest.json`, `hooks/mas-session-context.ps1`, `commands/mas.md`, `rules/multi-agent-hybrid.mdc` | local seed | 2026-03 | MAS v1.5.0 | Current framework contracts |

## Findings

| # | Source | Context | Pattern/Fix | Tradeoffs | Applicability | Recommendation | Confidence |
|---|--------|---------|-------------|-----------|---------------|----------------|------------|
| 1 | 11, 1 | MAS installs via copy-to-`~/.cursor` script; no marketplace discoverability | **Ship as Cursor Plugin:** add `.cursor-plugin/plugin.json` bundling `skills/`, `rules/`, `hooks/`, optional `mcp.json`, `commands/` per [plugins reference](https://cursor.com/docs/reference/plugins). One-click install from Customize/Marketplace; versioned releases replace manual zip export. | Marketplace review process; must keep canonical install script for air-gapped users | Primary distribution upgrade for v1.6+; aligns manifest.json with plugin schema | **adopt** | HIGH |
| 2 | 5, 4 | MAS hooks only `sessionStart` + `subagentStop` at **user** `~/.cursor/hooks.json`; cloud agents ignore user hooks | **Project-level hooks + expanded events:** commit `.cursor/hooks.json` in framework template / bootstrap script; add `subagentStart` (validate Task prompt contains TASK_ID), `postToolUse` on Task (telemetry), `stop` (finalize workflow session), `preCompact` (warn when briefs not flushed). Cloud Agents load **repo** hooks only — critical for team CI-style MAS runs. | More hook scripts to maintain; hook failures must fail-open per platform defaults | Extends existing `mas-session-context` pattern; required for Cloud Agent parity | **adopt** | HIGH |
| 3 | 6, 13 | MAS spawns all specialists as `Task(generalPurpose)` with skill path in prompt; platform now has typed subagents + built-ins | **Hybrid subagent strategy:** keep MAS skills/handoffs as SOT; add thin `.cursor/agents/` wrappers per specialist slug (name, description, model from spawn-model-policy, `readonly: true` for auditors). Coordinator may use built-in `explore` for OSINT codebase sweep, `bash` for test-executor, `browser` for visual QA instead of bloating generalPurpose context. Custom subagents **do not receive User Rules** — keep self-contained Task prompt template. | Dual maintenance (skill + agent file); model frontmatter may be overridden by plan/admin | Reduces token load; improves Task routing hints; maps 1:1 to spawn-model-policy slugs | **adapt** | HIGH |
| 4 | 1, 12, 2 | MAS forbids `run_in_background: true` and parallel Tasks; Cursor 2.5 supports async + nested subagents | **Selective parallel audit lane:** after dev, spawn independent P0/P1 auditors (`dependency-risk`, `api-contract`, `security-auditor`) with `run_in_background: true` when handoff flags are mutually exclusive and `readonly: true`. Coordinator collects results before reviewer. Keep sequential chain for dev → ux → a11y → i18n. Document parent verification step (forum reports async subagents skip verification). | Race on shared FILES; harder debugging; nested spawn depth limit (2 levels) | Opt-in via handoff `PARALLEL_AUDIT: yes`; lite mode stays sequential | **adapt** | MEDIUM |
| 5 | 13, 6, 14 | `spawn-model-policy.md` references `composer-2.5-fast`, `claude-opus-4-7-thinking-high`; platform model enum drifts (e.g. `composer-2-fast`, `gpt-5.3-codex-high-fast`, bracket params `claude-opus-5[effort=high]`) | **Dynamic model resolution layer:** document `inherit` as default for dev subagents; thinking class = latest thinking-high family; fast = latest composer-fast; add handoff `MODEL_SLUG:` override; on Task rejection fall back to `default` (already specified). Add `agent models` / `/models` CLI parity note in install README. | Breaking changes each Cursor release; tests need smoke spawn | Prevents silent model mismatch; reduces coordinator prompt brittleness | **adopt** | HIGH |
| 6 | 7, 14 | MAS uses `commands/mas.md` + `disable-model-invocation: true` on coordinator skill; Cursor pushes Skills as primary | **Skills-first entry with command args:** run `/migrate-to-skills` pattern manually — keep `mas`/`mas-lite` commands for `$ARGUMENTS` passthrough (skills lack positional args per forum). Ensure `multi-agent-system` and `mas-coordinator` skills use `paths` globs for `.ai/**` to reduce auto-invocation noise. Custom Mode (Alt+Enter) for session-pinned Coordinator. | Commands hidden when "third-party plugins" toggle off (forum 3.9.8) | Preserve slash UX; document toggle + reload for command visibility | **adapt** | MEDIUM |
| 7 | 8, 2 | MAS references MCP (Figma, browser) in specialists but install manifest has no bundled `mcp.json` | **Plugin MCP template + lazy-load contract:** ship optional `mcp.json` stubs in plugin (Figma official, browser MCP) with env placeholders; document "agents load MCP on demand" (2.4) in mas-figma / mas-visual-fidelity skills. Add `beforeMCPExecution` hook option for audit trail. Use `permissions.json` / Auto-review allowlist for dogfooded servers. | Secrets management burden; users without MCP still work | Completes MAS-05/06/07 device+capture story when MCP present | **adapt** | MEDIUM |
| 8 | 9, 5 | Cloud Agents = native coordinator + VMs; `sessionStart` hook N/A in cloud; user hooks unavailable | **Document MAS vs Cloud Agents boundary:** MAS `/mas` = **local IDE orchestration** with filesystem handoffs; Cloud Agents/Projects = **hosted coordinator** with shared project context. Recommend: use MAS for repo-scoped quality gates on laptop; use Cloud Agents for long-running feature branches. Bootstrap must emit `.cursor/environment.json` + project hooks for cloud parity. | Feature overlap may confuse users; not all MAS scripts run in cloud VM (adb, local device) | README + coordinator skill "when to use" table; avoid claiming MAS replaces Projects | **adapt** | HIGH |
| 9 | 10 | Cursor Plan Mode produces editable markdown plans pre-build | **Align mas-planner output with Plan Mode artifacts:** optional handoff `PLAN_MODE: export` writes plan to `.cursor/plans/` or workspace plan path Cursor recognizes; planner brief sections mirror Plan Mode todos. Coordinator can suggest Shift+Tab Plan Mode for greenfield before `/mas` chain. | Duplication if both run; Plan Mode is user-driven not Task-spawned | Reduces friction for users already in Plan Mode; planner remains MAS gate | **adapt** | MEDIUM |
| 10 | 3, 4 | Hooks beta → production; parallel hook execution; `subagentStop` returns `followup_message` | **MAS already uses `subagentStop` followup** — extend with `loop_limit`, `matcher` on `generalPurpose`, and `subagentStart` deny if handoff missing `SPAWN_STATUS: spawned`. Jan 2026 CLI: hooks 10× faster — safe to add lightweight telemetry hooks without UX penalty. | `followup_message` only when status=completed; over-aggressive deny breaks manual Task use | Validate existing `mas-session-context.ps1` against new hook JSON schema (`version: 1`) | **adapt** | HIGH |

## Recommended Approach

Treat MAS as a **Cursor-native orchestration plugin** that composes platform primitives rather than fighting them. Preserve the durable artifacts model (`.ai/handoffs/`, `.ai/context/{brief-type}/`) as MAS's differentiator — Cursor Projects/Cloud Agents optimize for long-horizon cloud work; MAS optimizes for **repo-local, reviewer-gated, specialist brief chains** with supply-chain and device-prep rigor.

### Target architecture (v1.6+ direction)

```
User: /mas or /mas-lite
        ↓
Coordinator skill (disable-model-invocation)
        ↓
Handoff → Task subagent
        ├─ MAS specialist: generalPurpose + skill prompt (current)
        ├─ OR native .cursor/agents/{slug}.md (thin wrapper, same prompt)
        ├─ OR built-in explore | bash | browser (platform delegation)
        ↓
Hooks (.cursor/hooks.json in repo)
        ├─ subagentStart: validate handoff / set env (TASK_ID)
        ├─ subagentStop: followup_message chain (existing)
        ├─ stop / postToolUse: record-workflow-step, session finalize
        └─ preCompact: artifact-forward warning
        ↓
Briefs on disk → next agent reads slice per read-order.md
```

### Phase plan

| Phase | Deliverable | Rationale |
|-------|-------------|-----------|
| **P0** | Plugin manifest + project `.cursor/hooks.json` in bootstrap | Distribution + Cloud Agent hook parity |
| **P0** | spawn-model-policy refresh (`inherit`, fallback table, README model CLI) | Stops model hint rot |
| **P1** | `.cursor/agents/` stubs for top 8 specialists | Better Task routing; model per agent |
| **P1** | Built-in subagent delegation map (osint→explore, test-executor→bash) | Token savings per platform guidance |
| **P2** | Optional `PARALLEL_AUDIT` async lane | Speed for P0 quartet when flags independent |
| **P2** | Plugin MCP template + permissions.json docs | Figma/browser/device workflows |
| **P3** | Plan Mode export compatibility for planner briefs | UX bridge for greenfield users |

### What not to change

- **Reviewer sole `Approved:` gate** — platform subagents lack this; keep MAS reviewer as hard stop.
- **Foreground sequential dev chain** — async dev→reviewer races on same FILES; parallelize audits only.
- **Self-contained Task prompts** — subagents don't get User Rules; handoff + skill paths stay mandatory.
- **Hybrid rule** (`multi-agent-hybrid.mdc`) — still correct; `alwaysApply` prevents ambient `/mas` activation.

## Priority Order

1. **Finding #1 — Plugin packaging** — Official distribution path; bundles all MAS assets; marketplace discoverability.
2. **Finding #2 — Project-level hooks expansion** — Unblocks Cloud Agents; strengthens chain automation beyond user-level install.
3. **Finding #5 — Model policy refresh** — Low effort, high reliability; prevents spawn failures on new Cursor builds.
4. **Finding #3 — Hybrid native subagents** — Platform-aligned delegation without rewriting specialist logic.
5. **Finding #8 — Cloud vs local boundary docs** — Sets user expectations; avoids wrong-tooling for adb/device MAS-07 flows.

## Anti-Patterns Avoided

- **Replacing MAS Coordinator with Cloud Projects** — Different trust model, no guaranteed brief schema gates, weak supply-chain/device prep story for Android dogfood.
- **Full async coordinator chain** — Forum reports parent skips verification; MAS reviewer gate would be undermined.
- **Copying Cursor's built-in explore/bash/browser prompts** — Use platform built-ins via Task `subagent_type`, not duplicate SKILL content.
- **Migrating `/mas` to skills-only without commands** — Skills lack `$ARGUMENTS`; user task text would be lost.
- **User-only hooks for team repos** — Cloud Agents cannot see `~/.cursor/hooks.json`.

## Implementation Guidance

**For architect/planner (downstream):**

1. Add `.cursor-plugin/plugin.json` referencing existing `skills/multi-agent-system/install/manifest.json` skill list; keep install scripts as fallback.
2. Extend `init-mas-context.ps1` to write `.cursor/hooks.json` merging MAS events; copy hook scripts to `.cursor/hooks/` (project-relative paths per docs).
3. Update `subagent-spawn.md` with optional `subagent_type: explore|bash|browser` table and when Coordinator may use native types vs `generalPurpose`.
4. Add `protocol/platform-parity.md` covering IDE vs CLI vs Cloud Agent capability matrix (Task tool, hooks, adb, MCP).
5. Refresh `spawn-model-policy.md` model hints to `inherit` + class-based escalation; remove hard-coded opus-4-7 strings where possible.
6. Consider `record-workflow-step.ps1` invocation from `postToolUse` hook matcher `Task` instead of Coordinator-only manual logging.

**Token efficiency wins aligned with platform:**

- MCP lazy load (2.4) — document "do not preload MCP tools in coordinator prompt."
- Built-in explore for OSINT seed file discovery — handoff FILES stay authoritative; explore supplements only.
- `paths` on specialist skills scoped to `.ai/`, `skills/`, relevant code globs — reduces auto-skill injection surface.
- Artifact-forward rule unchanged — hooks should never inject full brief bodies into `additional_context`.

## License / Copy Guardrails

- Cursor docs and changelog: reference URLs only; do not paste proprietary hook JSON schemas beyond minimal examples.
- Forum posts: pattern descriptions only; no user content reproduction.
- MAS framework remains MIT/portable — plugin manifest should not bundle third-party MCP server code; stubs + env docs only.

## Regression Notes

N/A (FEATURE mode). Related: MAS-07 device prep requires **local** adb — document as incompatible with default Cloud Agent VM unless USB passthrough or cloud device farm integrated.

## Local Files Referenced

- `skills/multi-agent-system/SKILL.md`
- `skills/mas-coordinator/SKILL.md`
- `skills/multi-agent-system/protocol/subagent-spawn.md`
- `skills/multi-agent-system/protocol/spawn-model-policy.md`
- `skills/multi-agent-system/install/manifest.json`
- `hooks/mas-session-context.ps1`
- `commands/mas.md`, `commands/mas-lite.md`
- `rules/multi-agent-hybrid.mdc`
- `README.md`

## Open Questions

- Will Cursor expose **programmatic Coordinator** APIs (beyond `subagentStop` followup) for fully automated multi-step chains without user-in-the-loop?
- Stable **model enum** contract for Task `model` param — should MAS ship a runtime probe script (`agent models`) vs static table?
- **Plugin vs global install** precedence when both exist — which skills win on name collision?
- Enterprise **team hooks** merging with project MAS hooks — ordering and deny precedence?
- When will `is_background: true` in subagent frontmatter work reliably without prompt hacks (forum: fixed in 2.6)?

## Overall Confidence

**HIGH** — Multiple official Cursor docs and changelogs (1.7–2.5, Jan 2026 CLI) agree on skills, hooks, subagents, plugins, and cloud boundaries. Local MAS v1.5.0 gap analysis cross-checked against seed files. **MEDIUM** on async parallel audit recommendation pending dogfood — community reports parent verification gaps. Model enum specifics remain volatile (LOW per-slug certainty, HIGH on "use inherit + fallback" strategy).
