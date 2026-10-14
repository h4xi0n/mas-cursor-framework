# Subagent Spawn Protocol (Coordinator)

Coordinator **must** delegate every specialist step to Cursor's **Task** tool. Never implement, review, plan, or debug in the Coordinator thread.

## Mandatory Task parameters

| Parameter | Value |
|-----------|--------|
| Tool | `Task` |
| `subagent_type` | `generalPurpose` (all MAS specialists) |
| `run_in_background` | `false` (always foreground — wait for result) |
| `description` | `MAS {agent} {TASK_ID}` — 3–6 words |
| `model` | From [spawn-model-policy.md](spawn-model-policy.md) — handoff override → policy default → `default` |
| `prompt` | Self-contained — see template below |

**Never:** `run_in_background: true`, parallel specialist Tasks (unless user explicitly requests), or `resume` except re-spawn same agent after Reviewer rejection.

## Model resolution

1. Read handoff `MODEL_CLASS:` (lite: `MC:`) if present
2. Else default from [spawn-model-policy.md](spawn-model-policy.md) for `TARGET_AGENT` slug
3. Map `MODEL_CLASS` to Task `model` hint (`fast` → `composer-2.5-fast`, `thinking` → thinking-high family, `normal` → default / `composer-2.5`)
4. If Task `model` unsupported → spawn with default; record `model: default`, `model_class` per policy in `record-workflow-step.ps1 -ModelClass`

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
| debate-synthesizer | `~/.cursor/skills/mas-debate/SKILL.md` |
| token-auditor | `~/.cursor/skills/mas-token-auditor/SKILL.md` |
| security-auditor | `~/.cursor/skills/mas-security-auditor/SKILL.md` |
| dependency-risk | `~/.cursor/skills/mas-dependency-risk/SKILL.md` |
| api-contract | `~/.cursor/skills/mas-api-contract/SKILL.md` |
| test-executor | `~/.cursor/skills/mas-test-executor/SKILL.md` |
| a11y | `~/.cursor/skills/mas-a11y/SKILL.md` |
| i18n | `~/.cursor/skills/mas-i18n/SKILL.md` |
| compliance | `~/.cursor/skills/mas-compliance/SKILL.md` |
| mas-figma | `~/.cursor/skills/mas-figma/SKILL.md` |
| mas-visual-fidelity | `~/.cursor/skills/mas-visual-fidelity/SKILL.md` |

## Coordinator spawn sequence

1. Write handoff to `.ai/handoffs/{TASK_ID}.md` (include `NEXT_AGENT`, `SPAWN_STATUS: spawned`, optional `MODEL_CLASS`, `BRIEF_PATH`).
2. Resolve model per **Model resolution** above.
3. **Call Task** with prompt below — do not proceed until Task returns.
4. Read subagent return; verify output ends with `DONE`.
5. **Record workflow step** with `-ModelClass` from resolved policy class.
6. Set `SPAWN_STATUS: complete` on the handoff (append one line or rewrite status line).
7. User summary: **one line + brief path** — artifact-forward; never paste full brief body.
8. If `NEXT_AGENT` is not `none` → write **new** handoff for next agent → spawn next Task.
9. If Reviewer `Approved: NO` → see Reviewer rejection loop below.

## Reviewer rejection loop

On Reviewer `Approved: NO`:

1. Increment `reviewer_loop_count` in session JSON.
2. If `reviewer_loop_count == 1` → bug-fix (or dev) with **filtered findings only** (agents-as-tools pattern — not full chain history).
3. If `reviewer_loop_count == 2` and `debate_used == false` → `debate-synthesizer` then bug-fix with `DEBATE_TRIGGER: reviewer-rejection-2`.
4. Set `debate_used: true` after debate spawn completes.
5. If `reviewer_loop_count >= MAX_REVIEWER_LOOPS` (2) after debate → **user escalation** — no third auto-retry. Include paths to reviewer output and `debates/{TASK_ID}.md`.

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
5. When handoff BRIEF_PATH / SECTIONS set — read brief slice per read-order.md
6. Execute using tools — edit files in workspace, run builds/tests as your skill requires
7. Follow the skill output template exactly
8. Do NOT spawn Task subagents. Do NOT act as Coordinator. Do NOT route to other agents.
9. End your final message with DONE

LITE_MODE: {true|false — from handoff MODE: LITE}
```

Debate slug uses skill folder `mas-debate` (not `mas-debate-synthesizer`). Token auditor uses `mas-token-auditor`.

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
- Paste full brief bodies in user summaries
- Spawn the next agent before the current Task returns

## Failure handling

| Situation | Action |
|-----------|--------|
| Subagent output missing `DONE` | Ask subagent to continue via **one** new Task with "Complete prior handoff; output must end DONE" |
| Subagent failed / blocked | Summarize blocker to user; do not chain `NEXT_AGENT` |
| Reviewer `Approved: NO` | Reviewer rejection loop above |
| Cap breach (`MAX_REVIEWER_LOOPS`, `MAX_CHAIN_AGENTS`) | User escalation with artifact paths |
| User cancels | Stop chain; leave `SPAWN_STATUS: cancelled` on handoff |
