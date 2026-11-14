TASK_ID: MAS-10
MODE: FULL
TIER: none
TARGET_AGENT: general-dev
SPAWN_STATUS: spawned
MODEL_CLASS: fast
BRIEF_PATH: .ai/context/architecture/MAS-10.md
SECTIONS: Architecture, CLI contracts, Lock schema, Integration points, Acceptance
UI_SCOPE: logic-only
GOAL: Implement host-wide build/install mutex scripts and wire MAS skills/docs per architecture MAS-10.
CONTEXT:
* Implement mas-host-lock.{ps1,sh} and mas-host-exec.{ps1,sh} under skills/multi-agent-system/scripts/
* Add references/host-build-install-mutex.md (SOT)
* Update mas-reviewer, mas-test-executor, mas-android-dev, build-test-visual-qa.md, platform-parity if present
* Add .ai/fixtures/MAS-10-HOST-LOCK/ and Test-MasHostLock.ps1 per plan
* Mirror changes under repo skills/ path (this workspace IS mas-cursor-framework)
* P1 optional: hooks/mas-host-lock-warn.ps1 — warn-only, fail-open
* Do NOT run gradle build on Android consumer projects
FILES:
* skills/multi-agent-system/scripts/
* skills/multi-agent-system/references/
* skills/mas-reviewer/SKILL.md
* skills/mas-test-executor/SKILL.md
* skills/mas-android-dev/SKILL.md
* hooks/
UI_CHANGES: NO
DELIVERABLE: Working mutex wrappers + docs; list all touched paths in output
NEXT_AGENT: test-strategy
DONE
