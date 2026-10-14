TASK_ID: MAS-04-FIX-P0-ALL
MODE: FULL
TIER: none
TARGET_AGENT: general-dev
SPAWN_STATUS: spawned
MODEL_CLASS: normal
UI_SCOPE: logic-only
GOAL: Create dogfood fixture files only for P0 quartet spawn validation.
CONTEXT:
* Synthetic dogfood — no production logic changes
* Create minimal OpenAPI 3 stub for api-contract predicate
SUPPLY_CHAIN: yes
API_CONTRACT: yes
SECURITY_AUDIT: yes
RUN_TESTS: yes
FILES:
* skills/multi-agent-system/install/manifest.json
DELIVERABLE: .ai/fixtures/MAS-04-FIX-P0-ALL/openapi.yaml (minimal valid OpenAPI 3.0 stub)
NEXT_AGENT: dependency-risk
DONE
