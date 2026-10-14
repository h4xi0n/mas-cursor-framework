TASK_ID: MAS-03
MODE: FULL
TIER: none
TARGET_AGENT: spec-reader
SPAWN_STATUS: complete
UI_SCOPE: logic-only
GOAL: Define MAS integration acceptance criteria from install docs for cross-project audit
DOCS:
* skills/multi-agent-system/install/README.md
* skills/multi-agent-system/install/manifest.json
CONTEXT:
* Framework source: C:\Users\arunk\AndroidStudioProjects\mas-cursor-framework
* Global install target: ~/.cursor (skills, commands, rules, hooks)
* Per-project bootstrap via init-mas-context.ps1
* Projects to audit: C:\Users\arunk\AndroidStudioProjects\* (BMAD-setup, EditPrime, EditPrime-Phase2, mas-cursor-framework, mas-cursor-framework-export-test, .ai, .cursor)
* Distinguish global vs per-project integration requirements
FILES:
* skills/multi-agent-system/install/README.md
* skills/multi-agent-system/install/manifest.json
UI_CHANGES: NO
DELIVERABLE: Brief at .ai/context/specs/MAS-03.md with checklist for global + per-project integration
NEXT_AGENT: general-dev
DONE
