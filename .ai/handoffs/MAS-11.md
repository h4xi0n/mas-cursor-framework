TASK_ID: MAS-11
MODE: FULL
TIER: none
TARGET_AGENT: commit
SPAWN_STATUS: spawned
MODEL_CLASS: normal
BRIEF_PATH: .ai/context/architecture/MAS-11.md
UI_SCOPE: logic-only
GOAL: Analyze git status and diff, draft conventional commit message for MAS-11 full product engineering team & GenAI expansion, present commit proposal, and commit upon user approval.
CONTEXT:
* User invoked: "/mas commit"
* Workflow MAS-11 was approved with `Approved: YES` by mas-reviewer.
* Reviewer report: .ai/context/architecture/MAS-11.md
* Files changed:
  - 4 new skills: `skills/mas-genai/`, `skills/mas-pm/`, `skills/mas-backend-dev/`, `skills/mas-devops/`
  - 4 new reference standards: `skills/multi-agent-system/references/{genai-engineering-standards,prd-authoring-standards,backend-engineering-standards,devops-platform-standards}.md`
  - 3 new brief directories: `.ai/context/{genai,prds,devops}/.gitkeep`
  - Context briefs: `.ai/context/{osint,brainstorms,plans,architecture}/MAS-11.md`
  - Protocol & routing updates: `brief-schemas.md`, `spawn-model-policy.md`, `subagent-spawn.md`, `read-order.md`, `token-rules.md`, `handoff-format.md`, `handoff-format-lite.md`, `mas-coordinator/SKILL.md`, `mas-lite/SKILL.md`, `mas-reviewer/SKILL.md`
  - Documentation & manifest: `manifest.json` (v1.9.0), `multi-agent-system/SKILL.md`, `README.md`, `daily-changelog.md`, `memory.md`
DELIVERABLE: Draft commit message, files to stage, and ask confirmation.
NEXT_AGENT: none
DONE
