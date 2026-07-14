---
description: Token-efficient multi-agent workflow (1–3 subagents). Below full /mas and typical Opus cost on small/medium tasks.
---

# /mas-lite — MAS Lite (low token)

Run the **MAS Lite** orchestration. Load and follow:

`~/.cursor/skills/mas-lite/SKILL.md`

Then act as **Coordinator** per `~/.cursor/skills/mas-coordinator/SKILL.md` (**MAS Lite Mode** section only).

## User message

Treat everything after `/mas-lite` as the task. Optional tier prefix:

- `S` — single agent (bug fix, ≤2 files)
- `M` — dev → reviewer lite (default small feature)
- `L` — planner → dev → reviewer lite

Example: `/mas-lite M add retry on export failure`

## Rules

- Read `.ai/context/memory.md` only at startup
- Handoffs: `handoff-format-lite.md` (max 12 lines, `SPAWN_STATUS: spawned`)
- **Every specialist step = `Task` tool** (`generalPurpose`, `run_in_background: false`) — see `protocol/subagent-spawn.md`
- Wait for Task return before next agent; Coordinator never implements inline
- Escalate to full `/mas` if user attaches PRD/API docs or asks for Documenter / full Reviewer / Commit
