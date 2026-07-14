# Memory Management

File: `.ai/context/memory.md`

## Purpose

Store durable project knowledge only.

## Never Store

- Conversations
- Generated code
- Full bug reports
- Temporary decisions
- Daily changelog content (ephemeral `.ai/context/daily-changelog.md`; not copied to `memory.md`)
- Workflow session JSON (`.ai/context/workflow-sessions/`; ephemeral scratch only)
- Full agent outputs or per-turn chat token dumps

## Store

- Architecture decisions
- Technical constraints
- API assumptions
- Important bug discoveries
- Coding conventions
- Lessons learned
- **Workflow telemetry summaries** — one compact line per approved MAS workflow under `### Workflow Usage (MAS-02)` (see [workflow-usage-policy.md](workflow-usage-policy.md))

## Update Workflow

1. Reviewer determines if memory update is needed (`## Memory Update` in output).
2. Coordinator validates the update.
3. Append concise entry to `memory.md`.
4. Remove obsolete information.
5. Keep memory under 300 lines.

**Workflow Usage vs Memory Update:** Workflow Usage (`### Workflow Usage (MAS-02)`) stores per-workflow telemetry (mode, tier, chain, models, tokens). Reviewer `## Memory Update` stores durable project knowledge. Both may append on the same approval — different sections, different purpose.

## Line Cap

Run `~/.cursor/skills/multi-agent-system/scripts/trim-memory.ps1` when approaching 280 lines.

## Version Control

The entire `.ai/` directory is **gitignored** — local agent context per machine. Do not commit `context/` or `handoffs/`.

## Example Structure

```markdown
## Architecture Decisions

* MVVM architecture.
* Repository pattern mandatory.
* StateFlow preferred over LiveData.

## Constraints

* Min SDK 26.
* Compose only.

## Known Issues

* Backend occasionally returns null usage values.
```
