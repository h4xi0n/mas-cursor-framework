TASK_ID: MAS-09
MODE: FULL
TIER: none
TARGET_AGENT: bug-fix
SPAWN_STATUS: spawned
MODEL_CLASS: normal
ORIGINAL_SYMPTOM: capture-device-logs-hook.ps1 stop event returns {} instead of path-only additional_context
ROOT_CAUSE: ParameterBindingException on stdin before Console.In read in hook script
FIX_SUMMARY: Fix stdin binding in capture-device-logs-hook.ps1 so stop hook emits capture-meta path
FILES:
* hooks/capture-device-logs-hook.ps1
* hooks/capture-device-logs-hook.sh
SCOPE: Hook stdin read fix only — minimal diff
UI_CHANGES: NO
DELIVERABLE: Fix hook; verify test-executor row #21 passes
NEXT_AGENT: documenter
DONE
