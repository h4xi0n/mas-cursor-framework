# Token Optimization Rules

## MAS Lite (`MODE: LITE`)

- Handoffs max **12 lines** — [handoff-format-lite.md](handoff-format-lite.md)
- Coordinator reads **memory.md** only at startup
- Subagents: handoff + specialist skill only; **no** `protocol/` folder
- Dev/Bug Fix output: **file paths + one line per file** — never paste full sources
- Reviewer: [reviewer-lite.md](../references/reviewer-lite.md) when `REVIEWER_MODE: lite`
- Max subagents: S=1, M=2, L=3
- Specialist skills have `disable-model-invocation: true` — loaded only via Coordinator Task spawn

## Always

- Use structured handoffs in `.ai/handoffs/`.
- Reference memory instead of repeating context.
- Pass only relevant file paths in handoffs.
- Keep handoffs under 20 lines whenever possible.

## Never

- Paste entire conversations.
- Paste entire codebases.
- Repeat architecture decisions already stored in memory.md.

## Good Handoff

```
TASK_ID: AUTH-12
TARGET_AGENT: android-dev
GOAL: Implement login repository.
FILES:
* LoginRepository.kt
CONSTRAINTS:
* StateFlow
* Hilt
DELIVERABLE: Repository + unit test
NEXT_AGENT: reviewer
DONE
```

## Bad Handoff

```
Here is everything discussed so far...
[pastes 500 lines of architecture and chat history]
```
