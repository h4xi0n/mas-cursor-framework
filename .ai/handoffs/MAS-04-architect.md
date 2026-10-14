TASK_ID: MAS-04
MODE: FULL
TIER: none
TARGET_AGENT: architect
SPAWN_STATUS: complete
MODEL_CLASS: thinking
UI_SCOPE: logic-only
GOAL: Design MAS v2 agent architecture — routing topology, skill module layout, brief schemas, chain overflow strategy.
BRIEF_PATH: .ai/context/plans/MAS-04.md
SECTIONS: Plan, Dependencies, Required Agents
CONTEXT:
* 10 new specialists across 3 phases
* Preserve deterministic Coordinator state machine
* MAX_CHAIN_AGENTS overflow strategy required
FILES:
* skills/multi-agent-system/protocol/read-order.md
* skills/multi-agent-system/protocol/brief-schemas.md
* skills/mas-coordinator/SKILL.md
DELIVERABLE: Architecture at .ai/context/architecture/MAS-04.md
NEXT_AGENT: reviewer
DONE
