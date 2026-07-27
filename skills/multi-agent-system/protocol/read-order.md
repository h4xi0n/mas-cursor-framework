# Context Read Order

## MAS Lite (`MODE: LITE`)

1. `.ai/context/memory.md` only — unless handoff lists `project.md` or `coding_standards.md`
2. Specialist skill + handoff only — no full `protocol/` folder
3. **Bug-fix only (optional):** `.ai/context/daily-changelog.md` — same-day regression context when present
4. When handoff `BP:` / `BRIEF_PATH:` set — read that brief (optional `SEC:` / `SECTIONS:` slice per [brief-schemas.md](brief-schemas.md))

## Full `/mas`

Every agent reads shared context in this order before additional files:

1. `.ai/context/project.md` — stack, modules, entry points
2. `.ai/context/coding_standards.md` — conventions for this project
3. `.ai/context/memory.md` — durable architecture decisions and constraints
4. **Bug-fix only (optional):** `.ai/context/daily-changelog.md` — same-day regression context when present

## Subscription matrix (`{TASK_ID}` briefs)

Beyond base context and handoff `BRIEF_PATH` / `SECTIONS:` slice:

| Agent | Reads at startup |
|-------|------------------|
| brainstorm | `osint/{TASK_ID}.md`, `specs/{TASK_ID}.md` if exists |
| planner | osint, brainstorms, specs for `{TASK_ID}` |
| architect | osint, brainstorms, plans for `{TASK_ID}` |
| general-dev / android-dev | plans, imaginations, optimizations, ux-reviews, test-strategies for `{TASK_ID}` |
| bug-fix | above + `debates/{TASK_ID}.md` when `DEBATE_TRIGGER` or debate brief exists |
| reviewer | all `{TASK_ID}` briefs in context dirs + handoff `FILES` |
| debate-synthesizer | reviewer output, prior `debates/{TASK_ID}.md`, handoff `FILES` |
| token-auditor | `workflow-sessions/{TASK_ID}.json` only |

## `BRIEF_PATH` + `SECTIONS:` semantics

- Handoff `BRIEF_PATH:` (lite `BP:`) points to artifact on disk — read instead of inline `CONTEXT` bullets when present
- Optional `SECTIONS:` (lite `SEC:`) — read only listed markdown headings
- Invalid `SECTIONS` headers → read full brief; Coordinator logs warning in user summary
- Omit `SECTIONS` → read full brief

Schema registry: [brief-schemas.md](brief-schemas.md).

## Rules

- Load additional files only when required for the task.
- Never repeat content already in `memory.md` in handoffs or responses.
- Reference memory by section name (e.g. "See memory.md — Architecture Decisions").

## Protocol Location

Agent-specific rules: `~/.cursor/skills/mas-{role}/SKILL.md`

Android projects: also read `~/.cursor/skills/multi-agent-system/references/android-veteran-standards.md` (sections relevant to task).

Handoff format: `~/.cursor/skills/multi-agent-system/protocol/handoff-format.md`

Spawn model policy: `~/.cursor/skills/multi-agent-system/protocol/spawn-model-policy.md`

Spec briefs (from Spec Reader): `.ai/context/specs/{TASK_ID}.md`

Brainstorm briefs (from Brainstorm): `.ai/context/brainstorms/{TASK_ID}.md`

Debate briefs (from Debate Synthesizer): `.ai/context/debates/{TASK_ID}.md`

Audit briefs (from Token Auditor): `.ai/context/audits/{TASK_ID}.md`
