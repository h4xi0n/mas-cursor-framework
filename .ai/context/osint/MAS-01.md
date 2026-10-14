# OSINT Brief — MAS-01

## Research Mode

FEATURE

## Topic

How do leading multi-agent frameworks (AutoGen, CrewAI, LangGraph, MetaGPT, OpenAI Agents SDK, Anthropic patterns) handle orchestration, token optimization, agent roles, and group discussion — and what concrete upgrades apply to the Cursor MAS framework?

## Scope

Cursor MAS framework (`skills/`, `protocol/`, `install/`): sequential Coordinator → specialist chains, structured handoffs, tiered `/mas-lite`, 15+ role skills. Compared against OSS orchestrators and academic consensus patterns (supervisor, hierarchical, debate, reflection).

## Research Summary

Industry frameworks converge on three orchestration topologies: **supervisor routing** (LangGraph, CrewAI hierarchical, Anthropic orchestrator-worker), **structured artifact pipelines** (MetaGPT SOP/pub-sub), and **ownership-transfer handoffs** (OpenAI Agents SDK). Token cost is the dominant scaling constraint — AutoGen's unbounded per-agent context causes O(T²) blowup; Anthropic reports 4–15× token multipliers for multi-agent vs single-agent. The Cursor MAS framework already implements several best practices (isolated subagent context, slim handoffs, durable brief files, workflow telemetry) but lacks tiered model routing, bounded debate/reflection loops, message-forwarding semantics, and explicit step/round caps. Highest-value upgrades: artifact-scoped context injection, tiered model spawn policy, capped multi-perspective review for rejection loops, and coordinator routing tables as deterministic state machines for common chains.

## Sources Consulted

| # | Source | Tier | Date | Version | Notes |
|---|--------|------|------|---------|-------|
| 1 | https://reference.langchain.com/python/langgraph-supervisor/supervisor/create_supervisor | official | 2026-07-27 | langgraph-supervisor | `pre_model_hook`, `output_mode: last_message`, `create_forward_message_tool` |
| 2 | https://dev.to/wartzarbee/autogens-hidden-token-tax-why-a-3-agent-chat-costs-15x-what-you-expect-21o5 | community | 2026-07-27 | AutoGen 0.4+ | BufferedChatCompletionContext, TokenLimitedChatCompletionContext |
| 3 | https://docs.crewai.com/en/concepts/processes | official | 2026-07-27 | CrewAI current | Sequential vs hierarchical process, manager_llm delegation |
| 4 | https://arxiv.org/abs/2308.00352 | official | 2026-07-27 | MetaGPT | SOP assembly-line, pub-sub message pool, structured artifacts |
| 5 | https://developers.openai.com/api/docs/guides/agents/orchestration | official | 2026-07-27 | OpenAI Agents SDK | Handoffs vs agents-as-tools, input_filter, nest_handoff_history |
| 6 | https://www.anthropic.com/engineering/multi-agent-research-system | official | 2026-07-27 | Anthropic Research | Orchestrator-worker, parallel subagents, token explains 80% variance |
| 7 | https://github.com/anthropics/anthropic-cookbook/blob/main/patterns/agents/orchestrator_workers.ipynb | official | 2026-07-27 | Claude Cookbooks | Opus orchestrator + Haiku workers cost pattern |
| 8 | https://aclanthology.org/2024.emnlp-main.992 | official | 2024 | EMNLP MAD paper | Multi-Agent Debate, judge, max rounds, degeneration-of-thought |
| 9 | https://arxiv.org/abs/2512.20845 | official | 2025-12 | MAR | Multi-Agent Reflexion, persona critics, consensus judge, 2-round cap |

## Findings

| # | Source | Context | Pattern/Fix | Tradeoffs | Applicability | Recommendation | Confidence |
|---|--------|---------|-------------|-----------|---------------|----------------|------------|
| 1 | LangGraph supervisor docs | Multi-agent token bloat from supervisor re-summarizing worker output | `output_mode: last_message` + `create_forward_message_tool` — pass worker result through without paraphrase; `pre_model_hook` trims/summarizes history before LLM call | Requires explicit forward vs synthesize decision per hop | MAS specialists already write briefs to disk; Coordinator still summarizes in chat — adopt **forward brief path + one-line summary** as default | **adapt** | HIGH |
| 2 | AutoGen context limiting | Group chat passes full history to every agent each turn → quadratic cost | `BufferedChatCompletionContext(buffer_size=8–12)` or `TokenLimitedChatCompletionContext`; `max_round` hard cap; cheap model for manager/selector | Loses full history awareness; acceptable for task-focused agents | MAS isolates subagent context (no shared chat) — already avoids worst case. Add explicit **max chain depth** and **max reviewer rejection loops** in protocol | **adapt** | HIGH |
| 3 | CrewAI hierarchical process | Dynamic task delegation when workflow not fully predetermined | `Process.hierarchical` with `manager_llm` delegates to specialists; workers `allow_delegation=False` to prevent loops | Extra LLM call per delegation; manager prompt is critical | MAS uses **deterministic Coordinator routing** (mas-coordinator rules) — superior for predictable dev workflows, inferior for open-ended research. Keep deterministic routing; add **optional L+ dynamic planner** only when scope ambiguous | **adapt** | MEDIUM |
| 4 | MetaGPT (arXiv 2308.00352) | Cascading hallucinations from unconstrained agent chat | SOP-encoded roles; publish-subscribe message pool; agents subscribe only to relevant artifact types; structured handoff artifacts (PRD, design, code) | Rigid; high setup cost; less flexible for bugs | MAS already mirrors this: `.ai/context/{specs,brainstorms,osint,imaginations}/` briefs + handoff `FILES` paths. Upgrade: define **artifact schema registry** (required fields per brief type) and **subscription matrix** (which agent reads which briefs) | **adapt** | HIGH |
| 5 | OpenAI Agents SDK orchestration | When to transfer ownership vs call specialist as tool | **Handoffs** = specialist owns conversation; **agents-as-tools** = manager synthesizes. `input_filter` / `nest_handoff_history` collapses prior transcript to summary block | Nested handoffs beta; guardrail scope changes per pattern | MAS is handoff-style (specialist owns step). For Reviewer rejection loops, use **agents-as-tools pattern**: dev re-invoked with filtered Reviewer findings only, not full chain history | **adapt** | HIGH |
| 6 | Anthropic orchestrator-worker | Complex research needing parallel independent exploration | Lead agent plans + spawns 3–5 parallel workers; workers have separate context windows; effort-scaling rules in orchestrator prompt; frontier model plans, cheaper models execute | 4–15× token cost; only justified for high-value tasks | MAS forbids parallel specialist spawn (subagent-spawn.md). For OSINT + Spec Reader on greenfield, consider **opt-in parallel read-only** phase (both write briefs, Coordinator merges) — user override only | **adapt** | MEDIUM |
| 7 | Anthropic model tiering + Cookbooks | Cost control in orchestrator-worker | Coordinator/orchestrator on capable model; workers on fast/cheap model; prompt caching on repeated system prompts | Quality drop if worker model too weak for task | MAS Lite already targets token budget via tier S/M/L. Add **spawn model policy** in handoff: `MODEL_CLASS: fast\|normal\|thinking` per agent (workflow-usage-policy already has `model_class` field) | **adopt** | HIGH |
| 8 | MAD (EMNLP 2024) + MAR (2025) | Single-agent self-reflection repeats same errors (degeneration-of-thought) | Multi-agent debate with 2–3 persona critics + judge synthesizes consensus; **max 2 debate rounds**; adaptive break when consensus reached | 3–5× tokens per rejection; needs judge objectivity | MAS Reviewer rejection → single bug-fix retry. Upgrade: on 2nd `Approved: NO`, spawn **capped debate brief** (brainstorm-lite: 2 critics + judge, max 2 rounds) before re-dev | **adapt** | MEDIUM |
| 9 | LangGraph / FRENXT production notes | Not every routing decision needs an LLM | State-machine supervisor (conditional edges, zero-token routing) for known workflow phases | Less flexible for novel tasks | MAS Coordinator routing tables in mas-coordinator are already a **deterministic state machine** — strength. Document explicitly; avoid future "LLM router" unless L+ ambiguous scope | **adopt** (preserve) | HIGH |

## Recommended Approach

**Preserve MAS core strengths** — deterministic Coordinator routing, isolated subagent context, structured brief files, mandatory quality gates (Documenter → Reviewer), and `/mas-lite` tiering — while adopting industry token and communication patterns:

1. **Artifact-forwarding protocol** — Treat specialist briefs as the message bus (MetaGPT pub-sub + LangGraph forward). Handoffs pass `BRIEF_PATH` + `SECTIONS:` (optional slice headers), never inline brief bodies. Coordinator user summary = one line + path.

2. **Tiered model spawn policy** — Map agents to `MODEL_CLASS` in handoff/spawn prompt: `fast` for OSINT sweep, imaginer trace, documenter; `normal` for dev/bug-fix/planner; `thinking` for architect, complex brainstorm. Leverage existing `record-workflow-step.ps1` telemetry.

3. **Explicit bounds** — Add protocol constants: `MAX_CHAIN_AGENTS` (full=12, lite per tier), `MAX_REVIEWER_LOOPS=2`, `MAX_DEBATE_ROUNDS=2`. After cap, Coordinator escalates to user.

4. **Capped multi-perspective review** — On repeated Reviewer rejection, optional `debate` micro-chain (2 persona critics + synthesizer) writes `.ai/context/debates/{TASK_ID}.md` before bug-fix retry. Avoids AutoGen-style unbounded group chat.

5. **Artifact schema registry** — Document required brief sections per type in `protocol/brief-schemas.md`; agents validate at write time. Reduces downstream re-read and token waste from incomplete handoffs.

**Avoid:** AutoGen-style shared conversation history; LangGraph network topology (every agent calls every agent); hierarchical supervisor-of-supervisors unless agent count exceeds ~8; unconstrained parallel spawn without user opt-in.

## Priority Order

1. **Finding #7 — Tiered model spawn policy** — Lowest implementation cost; immediate token savings; `model_class` field already exists in workflow-usage-policy.
2. **Finding #1 — Artifact-forwarding protocol** — Reinforces existing brief-on-disk pattern; reduces Coordinator chat bloat.
3. **Finding #4 — Artifact schema registry + subscription matrix** — Improves handoff quality across all chains; prevents incomplete briefs.
4. **Finding #2 — Explicit chain/rejection caps** — Prevents runaway loops (AutoGen `max_round` equivalent).
5. **Finding #8 — Capped debate on 2nd Reviewer rejection** — Quality upgrade for hard bugs; bounded cost (max 2 rounds).

## Anti-Patterns Avoided

- **Unbounded group chat** (AutoGen default) — MAS correctly forbids shared transcript; do not add.
- **LLM-based routing for all hops** — MAS deterministic Coordinator is cheaper and more debuggable than CrewAI manager_llm for software delivery.
- **Hierarchical supervisor-of-supervisors** — Overkill for ≤15 specialists; LangGraph data shows 1.6× cost vs flat supervisor with marginal gain below 8 agents.
- **Copying OSS implementations** — Patterns only; no code from LangGraph/CrewAI/AutoGen.
- **Parallel specialist spawn by default** — Anthropic parallelizes only for independent research subtasks; MAS sequential default is correct for code workflows.

## Implementation Guidance

### For Brainstorm agent (NEXT_AGENT per handoff)

- Read this brief before internal option exploration.
- When comparing orchestration approaches, prefer **SOP + artifact bus** (MetaGPT) over **debate** (MAD) for feature design; reserve debate for Reviewer rejection / ambiguous tradeoffs.
- Propose concrete diffs to: `protocol/token-rules.md`, `protocol/subagent-spawn.md`, `mas-coordinator/SKILL.md`, new `protocol/brief-schemas.md`, new `protocol/spawn-model-policy.md`.

### Tiered model policy (sketch)

| Agent | Default MODEL_CLASS | Rationale |
|-------|---------------------|-----------|
| osint, imaginer, documenter, spec-reader | fast | Read/search/trace; bounded output |
| planner, brainstorm, test-strategy, ux-intelligence | normal | Structured reasoning |
| architect, reviewer (full) | thinking | Design judgment, gate quality |
| android-dev, general-dev, bug-fix | normal | Implementation |
| coordinator | normal | Routing only; no LLM work inline |

Override via handoff `MODEL_CLASS:` field; Coordinator passes to Task `model` param when supported.

### Artifact subscription matrix (sketch)

| Agent | Reads at startup |
|-------|------------------|
| brainstorm | osint, specs |
| planner | osint, brainstorms, specs |
| architect | osint, brainstorms, plans |
| dev / bug-fix | osint, imaginations, optimizations, ux-reviews, test-strategies, plans |
| reviewer | all changed-files briefs + handoff |

### Debate micro-chain (sketch, optional)

Trigger: `Reviewer Approved: NO` count ≥ 2 for same TASK_ID.

```
Coordinator → debate-synthesizer (fast, max 2 rounds)
  critics: security-persona + simplicity-persona
  output: .ai/context/debates/{TASK_ID}.md
→ bug-fix (reads debate brief + reviewer findings)
```

Cap: 1 debate session per TASK_ID; user escalation after.

## License / Copy Guardrails

- All cited frameworks are OSS or published research — describe patterns in prose only.
- Do not paste LangGraph, CrewAI, AutoGen, or OpenAI SDK code into MAS skills.
- MetaGPT (MIT), LangGraph (MIT), CrewAI (MIT) — pattern adaptation only.

## Regression Notes

N/A (feature research mode)

## Local Files Referenced

- `skills/multi-agent-system/SKILL.md`
- `skills/mas-coordinator/SKILL.md`
- `skills/mas-lite/SKILL.md`
- `skills/multi-agent-system/protocol/token-rules.md`
- `skills/multi-agent-system/protocol/subagent-spawn.md`
- `skills/multi-agent-system/protocol/workflow-usage-policy.md`

## Open Questions

- Should MAS expose `MODEL_CLASS` in lite handoffs (12-line cap may require abbreviation)?
- Is parallel read-only OSINT + Spec Reader worth a user-opt-in flag, given Cursor Task tool constraints?
- Does Cursor Task metadata reliably expose token usage for `record-workflow-step.ps1` aggregation?

## Overall Confidence

**HIGH** — Multiple official sources (LangGraph, CrewAI, OpenAI, Anthropic, MetaGPT paper) agree on supervisor routing, bounded context, artifact handoffs, and tiered models. MAS local implementation was read directly; gaps are well-defined and actionable. Debate-on-rejection is MEDIUM confidence for software bug workflows (stronger evidence in reasoning benchmarks than code review).
