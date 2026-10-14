TASK_ID: MAS-06
MODE: FULL
TIER: none
TARGET_AGENT: brainstorm
SPAWN_STATUS: spawned
MODEL_CLASS: thinking
BRIEF_PATH: .ai/context/osint/MAS-06.md
UI_SCOPE: logic-only
GOAL: Brainstorm options to close Figma-to-implementation fidelity gaps in MAS pipeline.
CONTEXT:
* User reports inconsistencies comparing Figma vs implemented UI
* Current gap: reviewer Visual QA is imagined-only; no post-dev Figma comparison
* mas-figma extracts design-spec pre-dev; dev re-maps tokens (drift risk)
* OSINT recommends artifact-mandatory fidelity gate + measurement-first diff
DELIVERABLE: Brief at .ai/context/brainstorms/MAS-06.md
NEXT_AGENT: planner
DONE
