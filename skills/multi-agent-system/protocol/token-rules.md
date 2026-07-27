# Token Optimization Rules

## Protocol constants (MAS-01)

| Constant | Full `/mas` | Lite |
|----------|-------------|------|
| `MAX_CHAIN_AGENTS` | 12 | S=2, M=2, L=3, L+=4 |
| `MAX_REVIEWER_LOOPS` | 2 | 2 |
| `MAX_DEBATE_ROUNDS` | 2 | 1 |
| `MAX_DEBATE_SESSIONS_PER_TASK` | 1 | 1 |

**Cap breach:** Coordinator escalates to user with paths to reviewer brief and `debates/{TASK_ID}.md` when applicable — no further auto-spawn.

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
