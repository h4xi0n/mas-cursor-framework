# Token Optimization Rules

## Protocol constants (MAS-01)

| Constant | Full `/mas` | Lite |
|----------|-------------|------|
| `MAX_CHAIN_AGENTS` | 12 | S=2, M=2, L=3, L+=4 |
| `MAX_REVIEWER_LOOPS` | 2 | 2 |
| `MAX_DEBATE_ROUNDS` | 2 | 1 |
| `MAX_DEBATE_SESSIONS_PER_TASK` | 1 | 1 |

**Cap breach:** Coordinator escalates to user with paths to reviewer brief and `debates/{TASK_ID}.md` when applicable — no further auto-spawn.

### MAX_CHAIN_AGENTS overflow — optional specialist skip order (MAS-04)

When projected chain exceeds cap, drop **optional** specialists in this order (first dropped = lowest retention):

```
1. test-executor
2. api-contract
3. dependency-risk
4. security-auditor
5. a11y
6. i18n
7. compliance
```

Record `skipped_specialists: []` in session JSON; log in user summary. Lite L/L+ uses same order within tier cap (3–4). Phase C specialists (observability, migration, chaos-resilience) follow compliance in mas-coordinator overflow policy.

**Protected agents (never auto-skipped):** osint, brainstorm, planner, architect, test-strategy, dev, android-dev, general-dev, bug-fix, documenter, reviewer, imaginer (active bug chain), debate-synthesizer (when triggered).

**MAS-05 (v1.3.0):** `mas-figma` is **protected-when-triggered** in full `/mas` — not added to the auto-skip list above (dev depends on design-spec artifact). If mandatory chain + mas-figma exceeds `MAX_CHAIN_AGENTS` (12) → **user escalation**, not silent drop. In Lite, `mas-figma` is **skippable within tier cap** (S/M: no spawn; L/L+: `FIG:y` per predicate — skip + warn if cap breached; recommend full `/mas`).

**MAS-06 (v1.4.0):** `mas-visual-fidelity` is **protected-when-triggered** in full `/mas` — not added to the auto-skip list above (same policy as `mas-figma`). Cap breach with triggered fidelity → **user escalation** with unresolved P0 table attached — never silent skip in full `/mas`. In Lite: no auto predicate — skip spawn unless explicit `VFID:y`; always warn "Figma fidelity unverified" when design-spec exists.

## Artifact-forward rule

After each specialist step, Coordinator user summary:

```
{Agent} complete — {one-line outcome}. Brief: {path}
```

Never paraphrase or paste full brief body in Coordinator chat. Handoffs use `BRIEF_PATH` + optional `SECTIONS:` (lite: `BP:` / `SEC:`).

## MAS Lite (`MODE: LITE`)

- Handoffs max **12 lines** — [handoff-format-lite.md](handoff-format-lite.md)
- Coordinator reads **memory.md** only at startup
- Subagents: handoff + specialist skill only; **no** `protocol/` folder
- Dev/Bug Fix output: **file paths + one line per file** — never paste full sources
- Reviewer: [reviewer-lite.md](../references/reviewer-lite.md) when `REVIEWER_MODE: lite`
- Max subagents per tier: S=2, M=2, L=3, L+=4 (see constants above)
- Token auditor: **skip by default** unless user requests
- Specialist skills have `disable-model-invocation: true` — loaded only via Coordinator Task spawn

## Always

- Use structured handoffs in `.ai/handoffs/`.
- Reference memory instead of repeating context.
- Pass only relevant file paths in handoffs.
- Keep handoffs under 20 lines whenever possible.
- Resolve `MODEL_CLASS` per [spawn-model-policy.md](spawn-model-policy.md).

## Never

- Paste entire conversations.
- Paste entire codebases.
- Repeat architecture decisions already stored in memory.md.
- Paste full brief bodies in Coordinator chat.

## Good Handoff

```
TASK_ID: AUTH-12
TARGET_AGENT: android-dev
MODEL_CLASS: normal
BRIEF_PATH: .ai/context/plans/AUTH-12.md
SECTIONS: Tasks, Dependencies
GOAL: Implement login repository.
FILES:
* LoginRepository.kt
DELIVERABLE: Repository + unit test
NEXT_AGENT: reviewer
DONE
```

## Bad Handoff

```
Here is everything discussed so far...
[pastes 500 lines of architecture and chat history]
```
