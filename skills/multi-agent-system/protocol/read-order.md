# Context Read Order

## MAS Lite (`MODE: LITE`)

1. `.ai/context/memory.md` only — unless handoff lists `project.md` or `coding_standards.md`
2. Specialist skill + handoff only — no full `protocol/` folder
3. **Bug-fix only (optional):** `.ai/context/daily-changelog.md` — same-day regression context when present

## Full `/mas`

Every agent reads shared context in this order before additional files:

1. `.ai/context/project.md` — stack, modules, entry points
2. `.ai/context/coding_standards.md` — conventions for this project
3. `.ai/context/memory.md` — durable architecture decisions and constraints
4. **Bug-fix only (optional):** `.ai/context/daily-changelog.md` — same-day regression context when present

## Rules

- Load additional files only when required for the task.
- Never repeat content already in `memory.md` in handoffs or responses.
- Reference memory by section name (e.g. "See memory.md — Architecture Decisions").

## Protocol Location

Agent-specific rules: `~/.cursor/skills/mas-{role}/SKILL.md`

Android projects: also read `~/.cursor/skills/multi-agent-system/references/android-veteran-standards.md` (sections relevant to task).

Handoff format: `~/.cursor/skills/multi-agent-system/protocol/handoff-format.md`

Spec briefs (from Spec Reader): `.ai/context/specs/{TASK_ID}.md`

Brainstorm briefs (from Brainstorm): `.ai/context/brainstorms/{TASK_ID}.md`
