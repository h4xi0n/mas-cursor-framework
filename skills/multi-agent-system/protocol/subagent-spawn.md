# Subagent Spawn Protocol (Coordinator)

Coordinator **must** delegate every specialist step to Cursor's **Task** tool. Never implement, review, plan, or debug in the Coordinator thread.

## Mandatory Task parameters

| Parameter | Value |
|-----------|--------|
| Tool | `Task` |
| `subagent_type` | `generalPurpose` (all MAS specialists) |
| `run_in_background` | `false` (always foreground — wait for result) |
| `description` | `MAS {agent} {TASK_ID}` — 3–6 words |
| `prompt` | Self-contained — see template below |

**Never:** `run_in_background: true`, parallel specialist Tasks (unless user explicitly requests), or `resume` except re-spawn same agent after Reviewer rejection.

## Agent slug → skill path

| `TARGET_AGENT` | Skill file |
|----------------|------------|
| spec-reader | `~/.cursor/skills/mas-spec-reader/SKILL.md` |
| brainstorm | `~/.cursor/skills/mas-brainstorm/SKILL.md` |
| planner | `~/.cursor/skills/mas-planner/SKILL.md` |
| architect | `~/.cursor/skills/mas-architect/SKILL.md` |
| android-dev | `~/.cursor/skills/mas-android-dev/SKILL.md` |
| general-dev | `~/.cursor/skills/mas-general-dev/SKILL.md` |
| osint | `~/.cursor/skills/mas-osint/SKILL.md` |
| imaginer | `~/.cursor/skills/mas-imaginer/SKILL.md` |
| ux-intelligence | `~/.cursor/skills/mas-ux-intelligence/SKILL.md` |
| perf-optimizer | `~/.cursor/skills/mas-perf-optimizer/SKILL.md` |
| release-readiness | `~/.cursor/skills/mas-release-readiness/SKILL.md` |
| test-strategy | `~/.cursor/skills/mas-test-strategy/SKILL.md` |
| bug-fix | `~/.cursor/skills/mas-bug-fix/SKILL.md` |
| documenter | `~/.cursor/skills/mas-documenter/SKILL.md` |
| reviewer | `~/.cursor/skills/mas-reviewer/SKILL.md` |
| commit | `~/.cursor/skills/mas-commit/SKILL.md` |

## Coordinator spawn sequence

1. Write handoff to `.ai/handoffs/{TASK_ID}.md` (include `NEXT_AGENT`, `SPAWN_STATUS: spawned`).
2. **Call Task** with prompt below — do not proceed until Task returns.
3. Read subagent return; verify output ends with `DONE`.
4. Set `SPAWN_STATUS: complete` on the handoff (append one line or rewrite status line).
5. If `NEXT_AGENT` is not `none` → write **new** handoff for next agent (new file `{TASK_ID}-{agent}.md` or reuse `{TASK_ID}.md` with updated `TARGET_AGENT`) → spawn next Task.
6. If Reviewer `Approved: NO` → spawn **bug-fix** or **android-dev** with findings (loop).

## Self-contained Task prompt (full `/mas`)

Subagents **do not** receive Coordinator chat history. The prompt must include paths and task id.

```
MAS specialist subagent. You have NO parent conversation context.

ROLE: {Human Agent Name} ({TARGET_AGENT})
TASK_ID: {TASK_ID}
WORKSPACE: {absolute workspace root if known}

INSTRUCTIONS:
1. Read handoff: .ai/handoffs/{TASK_ID}.md (or path given in handoff)
2. Read skill: ~/.cursor/skills/mas-{TARGET_AGENT}/SKILL.md
3. Read subagent rules: ~/.cursor/skills/multi-agent-system/protocol/subagent-role.md
4. Read context per ~/.cursor/skills/multi-agent-system/protocol/read-order.md (only files required by handoff)
5. Execute using tools — edit files in workspace, run builds/tests as your skill requires
6. Follow the skill output template exactly
7. Do NOT spawn Task subagents. Do NOT act as Coordinator. Do NOT route to other agents.
8. End your final message with DONE

LITE_MODE: {true|false — from handoff MODE: LITE}
```

## Lite prompt additions

When `MODE: LITE` on handoff, add:

```
Read memory.md only unless handoff lists other context files.
If REVIEWER_MODE: lite, read ~/.cursor/skills/multi-agent-system/references/reviewer-lite.md only.
Do not paste full file bodies in output — paths and one-line summaries only.
```

## What Coordinator must NOT do

- Read a specialist skill and perform that agent's work inline
- Skip Task for "small" fixes while in `/mas` or `/mas-lite` mode
- Paste the full handoff in chat instead of writing `.ai/handoffs/`
- Spawn the next agent before the current Task returns

## Failure handling

| Situation | Action |
|-----------|--------|
| Subagent output missing `DONE` | Ask subagent to continue via **one** new Task with "Complete prior handoff; output must end DONE" |
| Subagent failed / blocked | Summarize blocker to user; do not chain `NEXT_AGENT` |
| Reviewer `Approved: NO` | New handoff with findings → Task to bug-fix or dev |
| User cancels | Stop chain; leave `SPAWN_STATUS: cancelled` on handoff |
