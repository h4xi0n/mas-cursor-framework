TASK_ID: MAS-01
MODE: FULL
TIER: none
TARGET_AGENT: general-dev
SPAWN_STATUS: spawned
GOAL: Implement MAS framework upgrade Phases 1-5 per architecture and plan.
CONTEXT:
* Architecture: .ai/context/architecture/MAS-01.md
* Plan: .ai/context/plans/MAS-01.md
* Brainstorm: .ai/context/brainstorms/MAS-01.md
* OSINT: .ai/context/osint/MAS-01.md
SCOPE:
* Phase 1: install dedup, spawn-model-policy.md, handoff MODEL_CLASS/BRIEF_PATH
* Phase 2: brief-schemas.md, token caps, read-order matrix, session JSON fields
* Phase 3: mas-debate skill, coordinator rejection loop, debates/ context dir
* Phase 4: mas-token-auditor skill, audits/ context dir
* Phase 5: README updates
FILES:
* skills/multi-agent-system/protocol/
* skills/mas-coordinator/SKILL.md
* skills/mas-lite/SKILL.md
* skills/multi-agent-system/SKILL.md
* install/
* README.md
UI_CHANGES: NO
DELIVERABLE: All phases implemented; no duplicate install scripts at repo root
NEXT_AGENT: documenter
DONE
