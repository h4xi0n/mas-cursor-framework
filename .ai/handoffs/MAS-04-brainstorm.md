TASK_ID: MAS-04
MODE: FULL
TIER: none
TARGET_AGENT: brainstorm
SPAWN_STATUS: complete
MODEL_CLASS: thinking
UI_SCOPE: logic-only
GOAL: Brainstorm product-level new specialist agents for MAS v2 roster based on OSINT findings.
BRIEF_PATH: .ai/context/osint/MAS-04.md
SECTIONS: Recommended Approach, Priority Order, Findings
CONTEXT:
* MAS-01 already added debate-synthesizer, token-auditor, spawn-model-policy — do not re-propose
* 19 existing agents — new agents must have clear mutual-exclusion vs release-readiness, reviewer, ux-intelligence, test-strategy
* Target: product-level quality for software delivery workflows in Cursor
FILES:
* skills/mas-coordinator/SKILL.md
* skills/multi-agent-system/SKILL.md
DELIVERABLE: Brief at .ai/context/brainstorms/MAS-04.md
NEXT_AGENT: planner
DONE
