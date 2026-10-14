TASK_ID: MAS-08
MODE: FULL
TIER: none
TARGET_AGENT: planner
SPAWN_STATUS: spawned
MODEL_CLASS: normal
BRIEF_PATH: .ai/context/brainstorms/MAS-08.md
SECTIONS: Recommended, Logic Flow, Domain & Contracts, Quality Bar
UI_SCOPE: logic-only
GOAL: Decompose MAS v1.6 Cursor compatibility improvements into ordered tasks with acceptance criteria.
CONTEXT:
* Recommended: Option 2 platform-native plugin + phased P0/P1/P2 upgrade
* P0: plugin packaging, project hooks, model policy refresh
* P1: hybrid .cursor/agents/ stubs, built-in explore/bash/browser delegation
* P2: async audit lane, MCP plugin template, Plan Mode bridge
FILES:
* skills/multi-agent-system/install/manifest.json
* skills/multi-agent-system/protocol/spawn-model-policy.md
DELIVERABLE: Brief at .ai/context/plans/MAS-08.md
NEXT_AGENT: architect
DONE
