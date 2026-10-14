TASK_ID: MAS-07
MODE: FULL
TIER: none
TARGET_AGENT: planner
SPAWN_STATUS: complete
MODEL_CLASS: normal
GOAL: Plan connected-device screenshot capture for mas-visual-fidelity — launch screen on device, adb screencap, compare vs Figma baseline.
CONTEXT:
* User requires agent runs screens on connected devices and captures screenshots for Figma parity check
* MAS-06 v1.4.0 has Paparazzi > Preview > emulator adb as last resort — no first-class connected-device recipe
* mas-visual-fidelity is read-only; may invoke adb/shell scripts, not patch app code
* Target: Android adb workflow (physical device + emulator)
FILES:
* skills/mas-visual-fidelity/SKILL.md
* skills/multi-agent-system/references/visual-fidelity-standards.md
* skills/mas-figma/SKILL.md
* skills/mas-android-dev/SKILL.md
* .ai/context/architecture/MAS-06.md
DELIVERABLE: Plan at .ai/context/plans/MAS-07.md
NEXT_AGENT: architect
DONE
