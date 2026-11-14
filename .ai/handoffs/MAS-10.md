TASK_ID: MAS-10
MODE: FULL
TIER: none
TARGET_AGENT: planner
SPAWN_STATUS: complete
MODEL_CLASS: normal
UI_SCOPE: logic-only
GOAL: Design cross-chat mutual exclusion so only one Gradle build and one device install run at a time on the host; other MAS chats/agents wait until release.
DOCS:
CONTEXT:
* Problem: parallel Cursor chats each spawn dev/reviewer/test-executor that invoke `./gradlew` and `adb install` concurrently → daemon contention, flaky builds, install races.
* Requirement: machine-wide (not per-repo) queue/lock; waiting chats block until holder completes; document timeout/stale-lock behavior.
* Scope: MAS framework repo (`skills/multi-agent-system/scripts`, protocol docs, specialist skills that run Gradle/adb install); align with MAS-08 hooks/bootstrap if project-level lock path needed.
* Install mutex: `gradlew *install*`, `adb install*`, and prep paths that install APK.
* Out of scope: changing Gradle daemon settings inside Android app projects; cloud agents without shared filesystem (document SKIP).
FILES:
* skills/multi-agent-system/scripts/
* skills/mas-reviewer/SKILL.md
* skills/mas-test-executor/SKILL.md
* skills/mas-android-dev/SKILL.md
* skills/multi-agent-system/references/build-test-visual-qa.md
* hooks/
UI_CHANGES: NO
DELIVERABLE: Plan at .ai/context/plans/MAS-10.md with tasks, lock location, wrapper CLI contract, skill/hook integration points, acceptance tests.
NEXT_AGENT: architect
DONE
