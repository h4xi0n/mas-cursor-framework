#!/usr/bin/env bash
# MAS capture-device-logs Cursor hook — opt-in logcat clear and stop dump.
# POSIX twin of capture-device-logs-hook.ps1.
#
# Fail-open: always emits valid JSON; never blocks agent stop.
# Opt-in via latest handoff with LOG_CAPTURE: yes (or legacy LOG: y).
# Reads LOG_PACKAGE, LOG_TAG, LOG_FORMAT from that handoff.
#
# Events:
#   beforeSubmitPrompt — keyword-gated clear (repro|bug|logcat); D8 opt-in only
#   stop               — dump on completed status; returns additional_context path
set -euo pipefail

EVENT="${1:-unknown}"
INPUT_RAW=""
if [ -t 0 ]; then
  INPUT_RAW=""
else
  INPUT_RAW="$(cat)"
fi

emit_empty() {
  echo '{}'
  exit 0
}

get_workspace_root() {
  echo "$INPUT_RAW" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    for k in ('workspace_roots','root','cwd'):
        if k in d and d[k]:
            v=d[k]
            print(v[0] if isinstance(v,list) else v)
            break
except: pass
" 2>/dev/null || true
}

# Resolve workspace and latest LOG_CAPTURE handoff (newest matching file wins)
WORKSPACE_ROOT="$(get_workspace_root)"
[[ -z "$WORKSPACE_ROOT" ]] && emit_empty

HANDOFF_DIR="$WORKSPACE_ROOT/.ai/handoffs"
[[ ! -d "$HANDOFF_DIR" ]] && emit_empty

HANDOFF_FILE=""
for f in $(ls -t "$HANDOFF_DIR"/*.md 2>/dev/null); do
  if grep -qE '^LOG_CAPTURE:\s*yes\s*$|^LOG:\s*y\s*$' "$f" 2>/dev/null; then
    HANDOFF_FILE="$f"
    break
  fi
done
[[ -z "$HANDOFF_FILE" ]] && emit_empty

TASK_ID="$(grep -m1 '^TASK_ID:' "$HANDOFF_FILE" | sed 's/^TASK_ID:[[:space:]]*//')"
LOG_PACKAGE="$(grep -m1 '^LOG_PACKAGE:' "$HANDOFF_FILE" | sed 's/^LOG_PACKAGE:[[:space:]]*//' || true)"
LOG_TAG="$(grep -m1 '^LOG_TAG:' "$HANDOFF_FILE" | sed 's/^LOG_TAG:[[:space:]]*//' || true)"
LOG_TAG="${LOG_TAG:-APP_TRACE}"
LOG_FORMAT="$(grep -m1 '^LOG_FORMAT:' "$HANDOFF_FILE" | sed 's/^LOG_FORMAT:[[:space:]]*//' || true)"

[[ -z "$TASK_ID" ]] && emit_empty

SCRIPT_PATH="$WORKSPACE_ROOT/skills/multi-agent-system/scripts/capture-device-logs.sh"
[[ ! -f "$SCRIPT_PATH" ]] && SCRIPT_PATH="$HOME/.cursor/skills/multi-agent-system/scripts/capture-device-logs.sh"
[[ ! -f "$SCRIPT_PATH" ]] && emit_empty

HOOK_EVENT="$(echo "$INPUT_RAW" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('hook_event',''))" 2>/dev/null || true)"
[[ -n "$HOOK_EVENT" ]] && EVENT="$HOOK_EVENT"

# beforeSubmitPrompt: opt-in clear only when prompt mentions repro/bug/logcat (D8)
if [[ "$EVENT" == "beforeSubmitPrompt" ]]; then
  PROMPT="$(echo "$INPUT_RAW" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('prompt',''))" 2>/dev/null || true)"
  if echo "$PROMPT" | grep -qiE 'repro|bug|logcat'; then
    bash "$SCRIPT_PATH" clear --task-id "$TASK_ID" --json-only 2>/dev/null || true
  fi
  emit_empty
fi

# stop: dump logcat when agent completed; surface capture-meta path to follow-up turn
if [[ "$EVENT" == "stop" ]]; then
  STATUS="$(echo "$INPUT_RAW" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('status',''))" 2>/dev/null || true)"
  [[ "$STATUS" != "completed" ]] && emit_empty

  ARGS=(dump --task-id "$TASK_ID" --tag "$LOG_TAG" --json-only)
  [[ -n "$LOG_PACKAGE" ]] && ARGS+=(--package "$LOG_PACKAGE")
  [[ -n "$LOG_FORMAT" ]] && ARGS+=(--format "$LOG_FORMAT")

  OUTPUT="$(bash "$SCRIPT_PATH" "${ARGS[@]}" 2>/dev/null || true)"
  LAST_LINE="$(echo "$OUTPUT" | tail -n1)"
  if [[ -n "$LAST_LINE" ]]; then
    PARSED_STATUS="$(echo "$LAST_LINE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('status',''))" 2>/dev/null || true)"
    PARSED_META="$(echo "$LAST_LINE" | python3 -c "import json,sys; d=json.load(sys.stdin); p=d.get('capture_meta_path'); print(p if p else '')" 2>/dev/null || true)"
    if [[ "$PARSED_STATUS" == "PASS" && -n "$PARSED_META" ]]; then
      CONTEXT="Device logs: $PARSED_META"
      [[ ${#CONTEXT} -gt 200 ]] && CONTEXT="${CONTEXT:0:200}"
      printf '{"additional_context":"%s"}\n' "$CONTEXT"
      exit 0
    fi
  fi
  emit_empty
fi

emit_empty
