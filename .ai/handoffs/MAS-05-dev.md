TASK_ID: MAS-05
MODE: FULL
TIER: none
TARGET_AGENT: general-dev
SPAWN_STATUS: spawned
MODEL_CLASS: normal
BRIEF_PATH: .ai/context/architecture/MAS-05.md
TEST_STRATEGY_BRIEF: .ai/context/test-strategies/MAS-05.md
PLAN_PATH: .ai/context/plans/MAS-05.md
GOAL: Implement mas-figma specialist per architecture brief — skill, protocol updates, coordinator routing, manifest 1.3.0.
CONTEXT:
* Read architecture/MAS-05.md for full file touch list and contracts
* Read test-strategies/MAS-05.md for validation checklist
* Create skills/mas-figma/SKILL.md with inspect-first MCP recipe
* Update protocol files, coordinator, multi-agent-system SKILL, manifest
* Create .ai/context/design-specs/.gitkeep
* UI_CHANGES: NO (framework/protocol only)
FILES:
* skills/mas-figma/SKILL.md (create)
* skills/multi-agent-system/protocol/brief-schemas.md
* skills/multi-agent-system/protocol/read-order.md
* skills/multi-agent-system/protocol/handoff-format.md
* skills/multi-agent-system/protocol/spawn-model-policy.md
* skills/multi-agent-system/protocol/subagent-spawn.md
* skills/mas-coordinator/SKILL.md
* skills/mas-lite/SKILL.md
* skills/multi-agent-system/SKILL.md
* skills/multi-agent-system/install/manifest.json
* .ai/context/design-specs/.gitkeep
DELIVERABLE: Full implementation per architecture brief
NEXT_AGENT: documenter
DONE
