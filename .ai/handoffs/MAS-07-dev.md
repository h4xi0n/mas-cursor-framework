TASK_ID: MAS-07
MODE: FULL
TIER: none
TARGET_AGENT: general-dev
SPAWN_STATUS: spawned
MODEL_CLASS: normal
GOAL: Implement MAS v1.5.0 ADB device prep gate — scripts, reference doc, protocol/skill updates, fixtures per architecture and test strategy.
BRIEF_PATH: .ai/context/architecture/MAS-07.md
SECTIONS: Script JSON contract, Prep gate state machine, Device Prerequisites schema, Step 0 workflow, Files to create/modify
TEST_STRATEGY_BRIEF: .ai/context/test-strategies/MAS-07.md
PLAN_PATH: .ai/context/plans/MAS-07.md
UI_CHANGES: NO
CONTEXT:
* Implement android-device-prep.ps1 and android-device-prep.sh with JSON stdout, exit codes 0/1/7/10-15
* Support ADB_DEVICES_FIXTURE env var for fixture-based testing (mock adb devices output)
* Create device-prep-automation.md reference
* Update brief-schemas, test-strategy-standards, handoff-format, read-order
* Update mas-test-executor (Step 0), mas-test-strategy (Device Prerequisites), build-test-visual-qa, visual-fidelity-standards, mas-coordinator
* Create .ai/fixtures/MAS-07-ADB-PREP/ with adb devices fixture files
* Bump manifest to 1.5.0
* Sync skills/ copies with ~/.cursor/skills where applicable in repo
FILES:
* skills/mas-test-executor/SKILL.md
* skills/mas-test-strategy/SKILL.md
* skills/multi-agent-system/install/manifest.json
DELIVERABLE: All implementation files per architecture MAS-07; runnable fixture tests pass
NEXT_AGENT: test-executor
RUN_TESTS: yes
DONE
