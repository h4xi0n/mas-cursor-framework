TASK_ID: MAS-05
MODE: FULL
TIER: none
TARGET_AGENT: planner
SPAWN_STATUS: spawned
MODEL_CLASS: normal
BRIEF_PATH: .ai/context/brainstorms/MAS-05.md
SECTIONS: Recommended, Logic Flow, Domain & Contracts
GOAL: Plan implementation tasks for mas-figma specialist (skill, protocol, coordinator routing, design-spec brief type).
CONTEXT:
* Read OSINT brief at .ai/context/osint/MAS-05.md
* Recommended: dedicated read-only mas-figma + design-spec brief
* Chain position: after architect, before dev (when FIGMA_SPEC or Figma URL present)
DELIVERABLE: Plan at .ai/context/plans/MAS-05.md
NEXT_AGENT: architect
DONE
