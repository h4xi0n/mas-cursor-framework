TASK_ID: MAS-04
MODE: FULL
TIER: none
TARGET_AGENT: general-dev
SPAWN_STATUS: complete
MODEL_CLASS: normal
UI_SCOPE: logic-only
GOAL: Implement MAS-04 Phase A (v1.2.0) P0 quartet — protocol, skills, coordinator routing, manifest.
BRIEF_PATH: .ai/context/plans/MAS-04.md
SECTIONS: Phase A tasks A1-A4, A5 tasks 17-18
TEST_STRATEGY_BRIEF: .ai/context/test-strategies/MAS-04.md
ARCHITECTURE_BRIEF: .ai/context/architecture/MAS-04.md
CONTEXT:
* A0 architect gate complete — follow architecture/MAS-04.md predicates
* MAS-01 exclusion: extend only; do not re-implement debate/token-auditor core
* Advisory v1 specialists; test-executor run-only; reviewer sole approval gate
SCOPE: Tasks A1-A4 + A5 tasks 17-18 (test-strategy/release-readiness cross-refs). Skip task 19 (documenter) and task 20 (manual dogfood).
FILES:
* skills/multi-agent-system/protocol/
* skills/mas-security-auditor/ (new)
* skills/mas-dependency-risk/ (new)
* skills/mas-api-contract/ (new)
* skills/mas-test-executor/ (new)
* skills/mas-coordinator/SKILL.md
* skills/mas-reviewer/SKILL.md
* skills/mas-lite/SKILL.md
* skills/mas-test-strategy/SKILL.md
* skills/mas-release-readiness/SKILL.md
* skills/multi-agent-system/install/manifest.json
* .ai/context/security-audits/.gitkeep
* .ai/context/api-contracts/.gitkeep
* .ai/context/supply-chain/.gitkeep
* .ai/context/test-runs/.gitkeep
UI_CHANGES: NO
DELIVERABLE: Phase A implementation complete per plan acceptance criteria
NEXT_AGENT: documenter
DONE
