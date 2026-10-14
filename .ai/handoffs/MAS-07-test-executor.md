TASK_ID: MAS-07
MODE: FULL
TIER: none
TARGET_AGENT: test-executor
SPAWN_STATUS: spawned
MODEL_CLASS: normal
RUN_TESTS: yes
TEST_STRATEGY_BRIEF: .ai/context/test-strategies/MAS-07.md
DEVICE_POLICY: physical
GOAL: Execute P0 fixture validation for android-device-prep scripts and document evidence in test-run brief.
CONTEXT:
* Run all P0 fixture commands from test-strategy Recommended Commands
* Use ADB_DEVICES_FIXTURE for mocked adb devices output
* Document Device section per new brief-schemas
* Do NOT patch source — run-only
FILES:
* skills/multi-agent-system/scripts/android-device-prep.ps1
* .ai/fixtures/MAS-07-ADB-PREP/
DELIVERABLE: Brief at .ai/context/test-runs/MAS-07.md
NEXT_AGENT: documenter
DONE
