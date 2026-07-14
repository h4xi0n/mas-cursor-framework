---
description: Full multi-agent orchestration — Spec Reader, Brainstorm, Planner, Architect, Dev, Documenter, Reviewer, Commit (Coordinator mode).
---

# /mas — Multi-Agent System (full)

Run the **full MAS** pipeline. Load and follow:

`~/.cursor/skills/multi-agent-system/SKILL.md`

Then act as **Coordinator** per `~/.cursor/skills/mas-coordinator/SKILL.md` (full mode — not MAS Lite).

## User message

Treat everything after `/mas` as the task.

Examples:
- `/mas implement login with Google Sign-In`
- `/mas fix crash when exporting 4K video`
- `/mas commit` (after Reviewer approval — user must confirm commit/push)

## Rules

- Read `.ai/context/` in order: `project.md`, `coding_standards.md`, `memory.md`
- Write handoffs to `.ai/handoffs/{TASK_ID}.md` per `handoff-format.md` (include `SPAWN_STATUS: spawned`)
- **Every specialist step = `Task` tool** (`subagent_type: generalPurpose`, `run_in_background: false`) — see `protocol/subagent-spawn.md`
- Wait for each Task to return before spawning the next agent
- Coordinator never implements, reviews, or debugs directly
- For low token work, tell user to use `/mas-lite` instead
