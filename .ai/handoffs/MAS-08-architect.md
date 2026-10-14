TASK_ID: MAS-08
MODE: FULL
TIER: none
TARGET_AGENT: architect
SPAWN_STATUS: spawned
MODEL_CLASS: thinking
BRIEF_PATH: .ai/context/plans/MAS-08.md
SECTIONS: Tasks, Dependencies, Required Agents
UI_SCOPE: logic-only
GOAL: Design MAS v1.6 architecture for Cursor 2.5+ compatibility — plugin topology, hook contracts, agent stub template, delegation map, platform parity.
CONTEXT:
* Option 2: platform-native plugin + phased P0/P1/P2
* Resolve open questions: plugin vs global precedence, stub generation CI, hook fail-open, async audit verification
* Preserve reviewer Approved gate and .ai/ artifact model
FILES:
* skills/multi-agent-system/
* skills/mas-coordinator/SKILL.md
DELIVERABLE: Brief at .ai/context/architecture/MAS-08.md
NEXT_AGENT: reviewer
DONE
