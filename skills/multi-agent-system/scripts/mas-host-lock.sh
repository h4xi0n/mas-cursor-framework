#!/usr/bin/env bash
# MAS host-wide build/install mutex — POSIX twin of mas-host-lock.ps1
# Exit: 0 PASS, 7 INVALID_ARGS, 20 LOCK_TIMEOUT, 21 LOCK_HELD, 22 LOCK_STALE_BREAK_FAILED
set -euo pipefail

STALE_GRACE_SEC=600
POLL_INITIAL=2
POLL_MAX=30

usage() {
  cat <<'EOF'
Usage: mas-host-lock.sh <subcommand> [options]

Subcommands: acquire | release | status | refresh | break-stale
Options: --lane build|install --task-id ID --workspace PATH --lease-sec N --wait-sec N
         --command-hint TEXT --agent-slug NAME --json
Env: MAS_LOCK_ROOT, MAS_HOST_LOCK=skip, MAS_LOCK_VERBOSE=1
See host-build-install-mutex.md
EOF
}

log_verbose() {
  if [[ "${MAS_LOCK_VERBOSE:-}" == "1" ]]; then
    echo "$1"
  fi
}

lock_root() {
  if [[ -n "${MAS_LOCK_ROOT:-}" ]]; then
    echo "$MAS_LOCK_ROOT"
    return
  fi
  local state="${XDG_STATE_HOME:-$HOME/.local/state}"
  echo "$state/mas/locks"
}

iso_utc_now() {
  date -u +"%Y-%m-%dT%H:%M:%S.000Z"
}

pid_alive() {
  local pid="$1"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null
}

lock_path() {
  echo "$(lock_root)/$1.lock"
}

emit_result() {
  local status="$1" exit_code="$2" message="$3"
  local extra="${4:-{}}"
  local skipped="false"
  if [[ "${MAS_HOST_LOCK:-}" == "skip" ]]; then skipped="true"; fi
  printf '{"status":"%s","exit_code":"%s","message":"%s","skipped":%s' "$status" "$exit_code" "$message" "$skipped"
  if [[ "$extra" != "{}" ]]; then
    printf ',%s' "${extra#?\{}"
    # extra passed as inner fields without braces wrapper — use simple append
  fi
  echo "}"
  case "$exit_code" in
    PASS) exit 0 ;;
    INVALID_ARGS) exit 7 ;;
    LOCK_TIMEOUT) exit 20 ;;
    LOCK_HELD) exit 21 ;;
    LOCK_STALE_BREAK_FAILED) exit 22 ;;
    *) exit 0 ;;
  esac
}

emit_json() {
  local json="$1" code="$2"
  echo "$json"
  exit "$code"
}

read_lock() {
  local path="$1"
  [[ -f "$path" ]] || return 1
  cat "$path"
}

lock_stale() {
  local json="$1"
  local pid lease refresh now lease_epoch refresh_epoch now_epoch
  pid=$(echo "$json" | sed -n 's/.*"holder_pid"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p')
  if ! pid_alive "$pid"; then return 0; fi
  lease=$(echo "$json" | sed -n 's/.*"lease_expires_at"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  refresh=$(echo "$json" | sed -n 's/.*"last_refresh_at"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  [[ -n "$lease" && -n "$refresh" ]] || return 1
  now_epoch=$(date -u +%s)
  lease_epoch=$(date -u -d "$lease" +%s 2>/dev/null || date -u -j -f "%Y-%m-%dT%H:%M:%S.000Z" "$lease" +%s 2>/dev/null || echo 0)
  refresh_epoch=$(date -u -d "$refresh" +%s 2>/dev/null || date -u -j -f "%Y-%m-%dT%H:%M:%S.000Z" "$refresh" +%s 2>/dev/null || echo 0)
  if [[ "$now_epoch" -gt "$lease_epoch" ]]; then
    local delta=$((now_epoch - refresh_epoch))
    [[ "$delta" -gt "$STALE_GRACE_SEC" ]] && return 0
  fi
  return 1
}

try_break_stale() {
  local lane="$1" root="$2"
  local path
  path="$(lock_path "$lane")"
  [[ -f "$path" ]] || return 0
  local json
  json=$(read_lock "$path") || return 0
  if lock_stale "$json"; then
    rm -f "$path"
    return 0
  fi
  return 1
}

write_lock_new() {
  local path="$1" json="$2"
  mkdir -p "$(dirname "$path")"
  set +e
  ( set -o noclobber; printf '%s' "$json" > "$path" ) 2>/dev/null
  local rc=$?
  set -e
  return $rc
}

SUB="${1:-}"
shift || true

LANE="" TASK_ID="" WORKSPACE="" LEASE_SEC=7200 WAIT_SEC=0 COMMAND_HINT="" AGENT_SLUG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lane) LANE="$2"; shift 2 ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --lease-sec) LEASE_SEC="$2"; shift 2 ;;
    --wait-sec) WAIT_SEC="$2"; shift 2 ;;
    --command-hint) COMMAND_HINT="$2"; shift 2 ;;
    --agent-slug) AGENT_SLUG="$2"; shift 2 ;;
    --json) shift ;;
    --help|-h) usage; exit 0 ;;
    *) emit_json '{"status":"FAIL","exit_code":"INVALID_ARGS","message":"Unknown arg"}' 7 ;;
  esac
done

if [[ -z "$SUB" || "$SUB" == "--help" ]]; then usage; exit 0; fi

if [[ "${MAS_HOST_LOCK:-}" == "skip" ]]; then
  emit_json "{\"status\":\"PASS\",\"exit_code\":\"PASS\",\"message\":\"MAS_HOST_LOCK=skip\",\"skipped\":true,\"subcommand\":\"$SUB\"}" 0
fi

ROOT="$(lock_root)"

case "$SUB" in
  acquire)
    [[ -n "$LANE" && -n "$TASK_ID" && -n "$WORKSPACE" ]] || emit_json '{"status":"FAIL","exit_code":"INVALID_ARGS","message":"acquire requires lane, task-id, workspace"}' 7
    path="$(lock_path "$LANE")"
    backoff=$POLL_INITIAL
    wait_start=$(date +%s)
    while true; do
      try_break_stale "$LANE" "$ROOT" || true
      if [[ -f "$path" ]]; then
        holder=$(read_lock "$path" || echo "")
        if [[ "$WAIT_SEC" -gt 0 ]]; then
          now=$(date +%s)
          if [[ $((now - wait_start)) -ge "$WAIT_SEC" ]]; then
            emit_json "{\"status\":\"FAIL\",\"exit_code\":\"LOCK_TIMEOUT\",\"message\":\"Wait exceeded\",\"lane\":\"$LANE\",\"holder\":$holder}" 20
          fi
        fi
        log_verbose "Lane $LANE busy; sleep ${backoff}s"
        sleep "$backoff"
        backoff=$(( backoff * 2 )); [[ $backoff -gt $POLL_MAX ]] && backoff=$POLL_MAX
        continue
      fi
      now=$(iso_utc_now)
      lease_end=$(date -u -d "+${LEASE_SEC} seconds" +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u -v+${LEASE_SEC}S +"%Y-%m-%dT%H:%M:%S.000Z")
      hint="$COMMAND_HINT"
      [[ ${#hint} -gt 500 ]] && hint="${hint:0:500}"
      slug_json="null"
      [[ -n "$AGENT_SLUG" ]] && slug_json="\"$AGENT_SLUG\""
      json=$(printf '{"lane":"%s","holder_pid":%s,"holder_ppid":%s,"task_id":"%s","workspace_root":"%s","command_hint":"%s","acquired_at":"%s","lease_expires_at":"%s","last_refresh_at":"%s","agent_slug":%s}' \
        "$LANE" "$$" "$$" "$TASK_ID" "$WORKSPACE" "$hint" "$now" "$lease_end" "$now" "$slug_json")
      if write_lock_new "$path" "$json"; then
        emit_json "{\"status\":\"PASS\",\"exit_code\":\"PASS\",\"message\":\"Acquired $LANE\",\"lane\":\"$LANE\"}" 0
      fi
      sleep "$backoff"
      backoff=$(( backoff * 2 )); [[ $backoff -gt $POLL_MAX ]] && backoff=$POLL_MAX
    done
    ;;
  release)
    [[ -n "$LANE" && -n "$TASK_ID" ]] || emit_json '{"status":"FAIL","exit_code":"INVALID_ARGS","message":"release requires lane, task-id"}' 7
    path="$(lock_path "$LANE")"
    [[ -f "$path" ]] || emit_json '{"status":"PASS","exit_code":"PASS","message":"Already released"}' 0
    json=$(read_lock "$path")
    file_pid=$(echo "$json" | sed -n 's/.*"holder_pid"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p')
    file_task=$(echo "$json" | sed -n 's/.*"task_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    if [[ "$file_task" == "$TASK_ID" && "$file_pid" == "$$" ]]; then
      rm -f "$path"
      emit_json '{"status":"PASS","exit_code":"PASS","message":"Released"}' 0
    fi
    if [[ "$file_task" == "$TASK_ID" ]] && lock_stale "$json"; then
      rm -f "$path"
      emit_json '{"status":"PASS","exit_code":"PASS","message":"Released stale"}' 0
    fi
    emit_json '{"status":"FAIL","exit_code":"LOCK_HELD","message":"Release refused"}' 21
    ;;
  refresh)
    [[ -n "$LANE" && -n "$TASK_ID" ]] || emit_json '{"status":"FAIL","exit_code":"INVALID_ARGS","message":"refresh requires lane, task-id"}' 7
    path="$(lock_path "$LANE")"
    [[ -f "$path" ]] || emit_json '{"status":"FAIL","exit_code":"LOCK_HELD","message":"No lock"}' 21
    json=$(read_lock "$path")
    file_pid=$(echo "$json" | sed -n 's/.*"holder_pid"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p')
    file_task=$(echo "$json" | sed -n 's/.*"task_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    [[ "$file_task" == "$TASK_ID" && "$file_pid" == "$$" ]] || emit_json '{"status":"FAIL","exit_code":"LOCK_HELD","message":"Not holder"}' 21
    now=$(iso_utc_now)
    lease_end=$(date -u -d "+${LEASE_SEC} seconds" +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u -v+${LEASE_SEC}S +"%Y-%m-%dT%H:%M:%S.000Z")
    new_json=$(echo "$json" | sed "s/\"lease_expires_at\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"lease_expires_at\":\"$lease_end\"/" | sed "s/\"last_refresh_at\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"last_refresh_at\":\"$now\"/")
    printf '%s' "$new_json" > "$path"
    emit_json '{"status":"PASS","exit_code":"PASS","message":"Refreshed"}' 0
    ;;
  status)
    out="{\"status\":\"PASS\",\"exit_code\":\"PASS\",\"message\":\"Status\",\"lock_root\":\"$ROOT\",\"lanes\":["
    first=true
    for ln in build install; do
      [[ -n "$LANE" && "$LANE" != "$ln" ]] && continue
      p="$(lock_path "$ln")"
      [[ -f "$p" ]] || continue
      j=$(read_lock "$p")
      stale="false"
      lock_stale "$j" && stale="true"
      $first || out+=","
      first=false
      out+="{\"lane\":\"$ln\",\"stale\":$stale,\"holder\":$j}"
    done
    out+="]}"
    emit_json "$out" 0
    ;;
  break-stale)
    [[ -n "$LANE" ]] || emit_json '{"status":"FAIL","exit_code":"INVALID_ARGS","message":"break-stale requires lane"}' 7
    path="$(lock_path "$LANE")"
    [[ -f "$path" ]] || emit_json '{"status":"PASS","exit_code":"PASS","message":"No lock"}' 0
    json=$(read_lock "$path")
    if lock_stale "$json"; then
      rm -f "$path"
      emit_json '{"status":"PASS","exit_code":"PASS","message":"Stale removed"}' 0
    fi
    emit_json '{"status":"FAIL","exit_code":"LOCK_STALE_BREAK_FAILED","message":"Not stale"}' 22
    ;;
  *)
    emit_json '{"status":"FAIL","exit_code":"INVALID_ARGS","message":"Unknown subcommand"}' 7
    ;;
esac
