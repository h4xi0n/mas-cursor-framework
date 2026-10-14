TASK_ID: MAS-08
MODE: FULL
TIER: none
TARGET_AGENT: osint
SPAWN_STATUS: complete
MODEL_CLASS: thinking
RESEARCH_MODE: FEATURE
TOPIC: What can improve the MAS multi-agent framework to work better with the latest Cursor IDE build (2025–2026)?
SCOPE: mas-cursor-framework — skills/, protocol/, subagent spawn via Task tool, MCP integration, hooks, rules, slash commands, model policy, token efficiency
SOURCES_HINT:
* https://cursor.com/docs
* https://cursor.com/changelog
* Cursor MCP, hooks, skills, subagents, background agents, composer models
* GitHub: cursor docs, community patterns for multi-agent orchestration
FILES:
* skills/multi-agent-system/SKILL.md
* skills/mas-coordinator/SKILL.md
* skills/multi-agent-system/protocol/subagent-spawn.md
* skills/multi-agent-system/protocol/spawn-model-policy.md
* skills/multi-agent-system/install/manifest.json
* README.md
RESEARCH_ONLY: false
UI_SCOPE: logic-only
GOAL: Research external prior art and Cursor platform capabilities to identify concrete improvements for MAS framework compatibility with latest Cursor.
CONTEXT:
* MAS uses Coordinator + Task tool subagents (generalPurpose, foreground)
* Framework at v1.5.0 with specialists, handoffs, workflow sessions, MCP (Figma, browser, etc.)
* Need gaps vs current Cursor features: skills, hooks, rules, MCP, models, subagent types, cloud agents
DELIVERABLE: Brief at .ai/context/osint/MAS-08.md
NEXT_AGENT: brainstorm
DONE
