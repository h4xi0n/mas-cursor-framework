TASK_ID: MAS-01
MODE: FULL
TIER: none
TARGET_AGENT: general-dev
SPAWN_STATUS: spawned
GOAL: Complete install dedup — remove duplicate scripts from root install/ (pointer-only).
CONTEXT:
* Architecture requires root install/ contains ONLY README.md
* Duplicates still present: install.bat, manifest.json, export/install ps1/sh
* Canonical copy: skills/multi-agent-system/install/
FILES:
* install/
SCOPE: Delete duplicate install scripts at repo root; keep install/README.md only
UI_CHANGES: NO
DELIVERABLE: Root install/ pointer-only; export parity still passes
NEXT_AGENT: reviewer
DONE
