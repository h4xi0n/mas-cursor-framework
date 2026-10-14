TASK_ID: MAS-09
MODE: FULL
TIER: none
TARGET_AGENT: bug-fix
SPAWN_STATUS: spawned
MODEL_CLASS: normal
ORIGINAL_SYMPTOM: Hook stop emits stale capture-meta path when dump fails
ROOT_CAUSE: Hook always outputs default meta path regardless of dump script status FAIL
FIX_SUMMARY: Emit {} unless dump stdout JSON has status PASS and non-null capture_meta_path
FILES:
* hooks/capture-device-logs-hook.ps1
* hooks/capture-device-logs-hook.sh
SCOPE: Reviewer Major #1 only — fail-open on dump failure (row #22)
UI_CHANGES: NO
DELIVERABLE: Fix hook; verify row #22 passes
NEXT_AGENT: reviewer
DONE
