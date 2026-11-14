TASK_ID: MAS-10
MODE: FULL
TIER: none
TARGET_AGENT: architect
SPAWN_STATUS: spawned
MODEL_CLASS: thinking
BRIEF_PATH: .ai/context/plans/MAS-10.md
UI_SCOPE: logic-only
GOAL: Architecture for host-wide Gradle build + adb/install mutex across parallel Cursor chats (MAS-10).
CONTEXT:
* Read planner plan and resolve architect gate Q1–Q5 (lock root, dual lanes, stale lock, CLI contract, hook integration).
* Preserve MAS-08 fail-open hook invariant for v1; optional warn-only preToolUse.
* Cloud agents without shared FS → document SKIP.
FILES:
* skills/multi-agent-system/scripts/
* hooks/
* skills/multi-agent-system/install/
UI_CHANGES: NO
DELIVERABLE: Brief at .ai/context/architecture/MAS-10.md
NEXT_AGENT: general-dev
DONE
