TASK_ID: MAS-07
MODE: FULL
TIER: none
TARGET_AGENT: architect
SPAWN_STATUS: spawned
MODEL_CLASS: thinking
GOAL: Design architecture for MAS ADB device prep gate integration (scripts, schemas, skill contracts).
BRIEF_PATH: .ai/context/plans/MAS-07.md
SECTIONS: Tasks, Dependencies, Files to create/modify
CONTEXT:
* Composite: android-device-prep.ps1/.sh, device-prep-automation.md, Device Prerequisites in test-strategy, Step 0 in test-executor, Device section in test-runs
* Selection policy: DEVICE_SERIAL override → single device → physical over emulator
* JSON stdout contract from prep script
FILES:
* skills/mas-test-executor/SKILL.md
* skills/mas-test-strategy/SKILL.md
* skills/multi-agent-system/protocol/brief-schemas.md
DELIVERABLE: Brief at .ai/context/architecture/MAS-07.md
NEXT_AGENT: test-strategy
DONE
