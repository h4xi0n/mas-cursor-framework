#!/usr/bin/env bash
# MAS host mutex wrapper — POSIX twin of mas-host-exec.ps1
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_SCRIPT="$SCRIPT_DIR/mas-host-lock.sh"
DEFAULT_LEASE=7200

usage() {
  cat <<'EOF'
Usage: mas-host-exec.sh --task-id ID --workspace PATH [options] -- <child argv...>
Options: --lease-sec N --wait-sec N --lanes build,install --dry-run --agent-slug NAME
EOF
}

lanes_from_argv() {
  local joined
  joined=$(printf '%s ' "$@" | tr '\\' '/')
  local lanes=""
  if [[ "$joined" =~ (^|[[:space:]/])(\./)?gradlew(\.bat)?([[:space:]]|$) ]]; then lanes="build"; fi
  if [[ "$joined" =~ gradlew(\.bat)?[[:space:]]+[^[:space:]]*install ]]; then
    lanes="build install"
  elif [[ "$joined" =~ gradlew(\.bat)?[[:space:]]+[^[:space:]]*connected[^[:space:]]*AndroidTest ]]; then
    lanes="build"
  elif [[ "$joined" =~ gradlew(\.bat)?[[:space:]]+ ]]; then
    lanes="build"
  fi
  if [[ "$joined" =~ [[:space:]]adb[[:space:]]+install-multiple ]]; then
    lanes="${lanes} install"
  fi
  if [[ "$joined" =~ [[:space:]]adb[[:space:]]+install ]]; then
    lanes="${lanes} install"
  fi
  echo "$lanes" | tr ' ' '\n' | awk '!seen[$0]++' | paste -sd' ' -
}

invoke_lock() {
  bash "$LOCK_SCRIPT" "$@"
}

TASK_ID="" WORKSPACE="$(pwd)" LEASE_SEC=$DEFAULT_LEASE WAIT_SEC=0 LANES_OVERRIDE="" DRY_RUN=false AGENT_SLUG=""
CHILD=()
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "--" ]]; then
    shift
    CHILD=("$@")
    break
  fi
  case "$1" in
    --task-id) TASK_ID="$2"; shift 2 ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --lease-sec) LEASE_SEC="$2"; shift 2 ;;
    --wait-sec) WAIT_SEC="$2"; shift 2 ;;
    --lanes) LANES_OVERRIDE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --agent-slug) AGENT_SLUG="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown flag: $1" >&2; exit 7 ;;
  esac
done

[[ ${#CHILD[@]} -gt 0 ]] || { echo "Missing child after --" >&2; exit 7; }

hint=$(printf '%s ' "${CHILD[@]}")
[[ ${#hint} -gt 500 ]] && hint="${hint:0:500}"

if [[ "${MAS_HOST_LOCK:-}" == "skip" ]]; then
  "${CHILD[@]}"
  ec=$?
  printf '{"status":"PASS","exit_code":"PASS","message":"Skipped host lock","skipped":true,"child_exit":%s}\n' "$ec"
  exit "$ec"
fi

[[ -n "$TASK_ID" ]] || { echo "Missing --task-id" >&2; exit 7; }

if [[ -n "$LANES_OVERRIDE" ]]; then
  read -r -a LANES <<< "${LANES_OVERRIDE//,/ }"
else
  read -r -a LANES <<< "$(lanes_from_argv "${CHILD[@]}")"
fi

if [[ ${#LANES[@]} -eq 0 || -z "${LANES[0]:-}" ]]; then
  "${CHILD[@]}"
  ec=$?
  printf '{"status":"PASS","exit_code":"PASS","message":"Ungated","child_exit":%s,"lanes":[]}\n' "$ec"
  exit "$ec"
fi

if $DRY_RUN; then
  printf '{"status":"PASS","exit_code":"PASS","message":"Dry run","dry_run":true,"lanes":["%s"]}\n' "$(IFS=,; echo "${LANES[*]}")"
  exit 0
fi

HELD=()
refresh_pid=""

cleanup() {
  [[ -n "$refresh_pid" ]] && kill "$refresh_pid" 2>/dev/null || true
  for (( i=${#HELD[@]}-1; i>=0; i-- )); do
    invoke_lock release --lane "${HELD[$i]}" --task-id "$TASK_ID" >/dev/null || true
  done
}
trap cleanup EXIT

for lane in "${LANES[@]}"; do
  args=(acquire --lane "$lane" --task-id "$TASK_ID" --workspace "$WORKSPACE" --lease-sec "$LEASE_SEC" --wait-sec "$WAIT_SEC" --command-hint "$hint")
  [[ -n "$AGENT_SLUG" ]] && args+=(--agent-slug "$AGENT_SLUG")
  if ! out=$(invoke_lock "${args[@]}"); then
    echo "$out"
    exit 22
  fi
  HELD+=("$lane")
done

(
  while true; do
    sleep 300
    for lane in "${HELD[@]}"; do
      invoke_lock refresh --lane "$lane" --task-id "$TASK_ID" --lease-sec "$LEASE_SEC" >/dev/null || true
    done
  done
) &
refresh_pid=$!

"${CHILD[@]}"
child_ec=$?

printf '{"status":"PASS","exit_code":"PASS","message":"Child completed","child_exit":%s}\n' "$child_ec"
exit "$child_ec"
