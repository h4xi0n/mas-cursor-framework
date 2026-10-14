#!/usr/bin/env bash
# MAS android-device-prep gate — device discovery, selection, boot wait, grants, reverse.
# POSIX twin of android-device-prep.ps1.
#
# Upstream prep gate for test-executor Step 0, Gradle connected tests, and tier-3 capture.
# Emits a single JSON object on stdout (last line). Idempotent re-run safe.
# --dry-run prints planned adb ops without a device. ADB_DEVICES_FIXTURE bypasses real adb.
#
# Exit codes:
#   0  PASS              1  ADB_NOT_FOUND       7  INVALID_ARGS
#   10 NO_DEVICE         11 UNAUTHORIZED       12 OFFLINE
#   13 AMBIGUOUS_DEVICE  14 SERIAL_NOT_FOUND   15 BOOT_TIMEOUT
#
# Env:
#   ADB_DEVICES_FIXTURE  — path to mock `adb devices -l` output; adb not required when set
#                          (fixtures: .ai/fixtures/MAS-07-ADB-PREP/)
#   ADB_BOOT_COMPLETED   — when "0", mock boot incomplete (fixture testing only)
#   ANDROID_SERIAL       — exported on PASS for child processes
set -euo pipefail

POLICY="auto"
SERIAL=""
PACKAGE=""
GRANTS=""
BOOT_TIMEOUT=120
REVERSE_LIST=()
NO_ANIMATION_OFF=false
DRY_RUN=false
JSON_ONLY=false

usage() {
  cat <<'EOF'
Usage: android-device-prep.sh [options]

  --policy physical|emulator|auto   Selection when multiple devices (default: auto)
  --serial <id>                     Explicit device serial override
  --package <id>                    Application id for pm grant loop
  --grants <p1,p2,...>              Comma-separated permission names
  --boot-timeout <sec>              Max boot wait (default: 120)
  --reverse <tcp:host:device>       Repeatable adb reverse pairs
  --no-animation-off                Skip animator scale disable
  --dry-run                         Print planned ops; no device required
  --json-only                       Suppress non-JSON stderr on success
  --help                            Show this help

Exit codes: 0=PASS, 1=ADB_NOT_FOUND, 7=INVALID_ARGS, 10=NO_DEVICE,
            11=UNAUTHORIZED, 12=OFFLINE, 13=AMBIGUOUS_DEVICE,
            14=SERIAL_NOT_FOUND, 15=BOOT_TIMEOUT

Fixture testing: set ADB_DEVICES_FIXTURE to mock adb devices -l output.
See device-prep-automation.md and .ai/fixtures/MAS-07-ADB-PREP/
EOF
}

log_info() {
  if [[ "$JSON_ONLY" != "true" ]]; then
    echo "$1"
  fi
}

emit_result() {
  local status="$1" serial="$2" exit_code="$3" message="$4" policy_applied="$5"
  local boot_wait_ms="${6:-null}" animations="${7:-false}"
  local grants_applied="${8:-[]}" grants_skipped="${9:-[]}" reverse_applied="${10:-[]}" warnings="${11:-[]}"

  if [[ "$serial" == "null" || -z "$serial" ]]; then
    serial_json="null"
  else
    serial_json="\"$serial\""
  fi

  if [[ "$boot_wait_ms" == "null" ]]; then
    boot_json="null"
  else
    boot_json="$boot_wait_ms"
  fi

  printf '{"status":"%s","serial":%s,"exit_code":"%s","message":"%s","policy_applied":"%s","boot_wait_ms":%s,"grants_applied":%s,"grants_skipped":%s,"reverse_applied":%s,"animations_disabled":%s,"warnings":%s}\n' \
    "$status" "$serial_json" "$exit_code" "$message" "$policy_applied" "$boot_json" \
    "$grants_applied" "$grants_skipped" "$reverse_applied" "$animations" "$warnings"

  case "$exit_code" in
    PASS) exit 0 ;;
    ADB_NOT_FOUND) exit 1 ;;
    INVALID_ARGS) exit 7 ;;
    NO_DEVICE) exit 10 ;;
    UNAUTHORIZED) exit 11 ;;
    OFFLINE) exit 12 ;;
    AMBIGUOUS_DEVICE) exit 13 ;;
    SERIAL_NOT_FOUND) exit 14 ;;
    BOOT_TIMEOUT) exit 15 ;;
    *) exit 1 ;;
  esac
}

is_emulator() {
  [[ "$1" =~ ^emulator- ]]
}

parse_devices() {
  local file="$1"
  DEVICES_SERIAL=()
  DEVICES_STATE=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line//$'\r'/}"
    [[ -z "${line// }" ]] && continue
    [[ "$line" =~ ^List\ of\ devices ]] && continue
    if [[ "$line" =~ ^([^[:space:]]+)[[:space:]]+([^[:space:]]+) ]]; then
      DEVICES_SERIAL+=("${BASH_REMATCH[1]}")
      DEVICES_STATE+=("${BASH_REMATCH[2]}")
    fi
  done < "$file"
}

get_devices_list() {
  local tmp
  if [[ -n "${ADB_DEVICES_FIXTURE:-}" ]]; then
    if [[ ! -f "$ADB_DEVICES_FIXTURE" ]]; then
      echo "ADB_DEVICES_FIXTURE not found: $ADB_DEVICES_FIXTURE" >&2
      exit 1
    fi
    parse_devices "$ADB_DEVICES_FIXTURE"
    return
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    DEVICES_SERIAL=("dry-run-device")
    DEVICES_STATE=("device")
    return
  fi
  tmp="$(mktemp)"
  adb devices -l > "$tmp"
  parse_devices "$tmp"
  rm -f "$tmp"
}

invoke_adb() {
  local dev_serial="$1"
  shift
  local args=("$@")
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] adb ${dev_serial:+-s $dev_serial }${args[*]}"
    return 0
  fi
  if [[ -n "${ADB_DEVICES_FIXTURE:-}" ]]; then
    local sub="${args[*]}"
    if [[ "$sub" == "shell getprop sys.boot_completed" ]]; then
      if [[ "${ADB_BOOT_COMPLETED:-}" == "0" ]]; then echo "0"; else echo "1"; fi
      return 0
    fi
    return 0
  fi
  if [[ -n "$dev_serial" ]]; then
    adb -s "$dev_serial" "${args[@]}"
  else
    adb "${args[@]}"
  fi
}

select_device() {
  local policy="$1" serial_override="$2"
  local i authorized_count=0 unauthorized_count=0
  local -a auth_serials=() hw_serials=() emu_serials=()

  for i in "${!DEVICES_STATE[@]}"; do
    case "${DEVICES_STATE[$i]}" in
      device)
        authorized_count=$((authorized_count + 1))
        auth_serials+=("${DEVICES_SERIAL[$i]}")
        if is_emulator "${DEVICES_SERIAL[$i]}"; then
          emu_serials+=("${DEVICES_SERIAL[$i]}")
        else
          hw_serials+=("${DEVICES_SERIAL[$i]}")
        fi
        ;;
      unauthorized) unauthorized_count=$((unauthorized_count + 1)) ;;
    esac
  done

  if [[ $authorized_count -eq 0 && $unauthorized_count -gt 0 ]]; then
    SEL_EXIT="UNAUTHORIZED"
    SEL_MSG="Device unauthorized — unlock phone and tap Always allow on USB debugging prompt. See device-prep-automation.md enrollment checklist."
    return 1
  fi
  if [[ $authorized_count -eq 0 ]]; then
    SEL_EXIT="NO_DEVICE"
    SEL_MSG="No devices in device state. Connect a phone or start an emulator, then retry."
    return 1
  fi

  if [[ -n "$serial_override" ]]; then
    for i in "${!DEVICES_SERIAL[@]}"; do
      if [[ "${DEVICES_SERIAL[$i]}" == "$serial_override" && "${DEVICES_STATE[$i]}" == "device" ]]; then
        SEL_SERIAL="$serial_override"
        SEL_MSG="Device ready; ANDROID_SERIAL=$serial_override"
        return 0
      fi
    done
    SEL_EXIT="SERIAL_NOT_FOUND"
    SEL_MSG="Serial $serial_override not found among authorized devices."
    return 1
  fi

  if [[ $authorized_count -eq 1 ]]; then
    SEL_SERIAL="${auth_serials[0]}"
    SEL_MSG="Device ready; ANDROID_SERIAL=${SEL_SERIAL}"
    return 0
  fi

  case "$policy" in
    physical)
      if [[ ${#hw_serials[@]} -eq 1 ]]; then
        SEL_SERIAL="${hw_serials[0]}"
        SEL_MSG="Device ready; ANDROID_SERIAL=${SEL_SERIAL}"
        return 0
      fi
      SEL_EXIT="AMBIGUOUS_DEVICE"
      SEL_MSG="Multiple hardware devices or none; set DEVICE_SERIAL or --serial."
      return 1
      ;;
    emulator)
      if [[ ${#emu_serials[@]} -eq 1 ]]; then
        SEL_SERIAL="${emu_serials[0]}"
        SEL_MSG="Device ready; ANDROID_SERIAL=${SEL_SERIAL}"
        return 0
      fi
      SEL_EXIT="AMBIGUOUS_DEVICE"
      SEL_MSG="Multiple emulators or none; set DEVICE_SERIAL or --serial."
      return 1
      ;;
    *)
      if [[ ${#hw_serials[@]} -eq 1 ]]; then
        SEL_SERIAL="${hw_serials[0]}"
        SEL_MSG="Device ready; ANDROID_SERIAL=${SEL_SERIAL}"
        return 0
      fi
      if [[ ${#hw_serials[@]} -eq 0 && ${#emu_serials[@]} -eq 1 ]]; then
        SEL_SERIAL="${emu_serials[0]}"
        SEL_MSG="Device ready; ANDROID_SERIAL=${SEL_SERIAL}"
        return 0
      fi
      SEL_EXIT="AMBIGUOUS_DEVICE"
      SEL_MSG="Multiple devices; policy auto could not resolve a single target."
      return 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --policy) POLICY="$2"; shift 2 ;;
    --serial) SERIAL="$2"; shift 2 ;;
    --package) PACKAGE="$2"; shift 2 ;;
    --grants) GRANTS="$2"; shift 2 ;;
    --boot-timeout) BOOT_TIMEOUT="$2"; shift 2 ;;
    --reverse) REVERSE_LIST+=("$2"); shift 2 ;;
    --no-animation-off) NO_ANIMATION_OFF=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --json-only) JSON_ONLY=true; shift ;;
    --help) usage; exit 0 ;;
    *) emit_result FAIL null INVALID_ARGS "Unknown argument: $1" "$POLICY" null false '[]' '[]' '[]' '[]' ;;
  esac
done

if [[ "$POLICY" != "physical" && "$POLICY" != "emulator" && "$POLICY" != "auto" ]]; then
  emit_result FAIL null INVALID_ARGS "Invalid policy: $POLICY" auto null false '[]' '[]' '[]' '[]'
fi

if [[ -n "$GRANTS" && -z "$PACKAGE" ]]; then
  emit_result FAIL null INVALID_ARGS "--package is required when --grants is set." "$POLICY" null false '[]' '[]' '[]' '[]'
fi

if [[ "$DRY_RUN" == "true" ]]; then
  sel="${SERIAL:-dry-run-device}"
  anim=false
  if [[ "$NO_ANIMATION_OFF" != "true" ]]; then anim=true; fi
  emit_result PASS "$sel" PASS "Dry-run complete; planned ops printed." "$POLICY" 0 "$anim" '[]' '[]' '[]' '["dry-run"]'
fi

if [[ -z "${ADB_DEVICES_FIXTURE:-}" ]] && ! command -v adb >/dev/null 2>&1; then
  emit_result FAIL null ADB_NOT_FOUND "adb not found on PATH. Install Android Platform Tools." "$POLICY" null false '[]' '[]' '[]' '[]'
fi

invoke_adb "" start-server >/dev/null || true
get_devices_list

if ! select_device "$POLICY" "$SERIAL"; then
  emit_result FAIL null "$SEL_EXIT" "$SEL_MSG" "$POLICY" null false '[]' '[]' '[]' '[]'
fi

boot_start_ms=$(($(date +%s%3N)))
boot_complete=false
while [[ "$boot_complete" != "true" ]]; do
  val="$(invoke_adb "$SEL_SERIAL" shell getprop sys.boot_completed | tr -d '\r')"
  if [[ "$val" == "1" ]]; then
    boot_complete=true
    break
  fi
  now_ms=$(($(date +%s%3N)))
  elapsed=$(( (now_ms - boot_start_ms) / 1000 ))
  if [[ $elapsed -ge $BOOT_TIMEOUT ]]; then
    emit_result FAIL "$SEL_SERIAL" BOOT_TIMEOUT "sys.boot_completed did not become 1 within $BOOT_TIMEOUT seconds." "$POLICY" $((now_ms - boot_start_ms)) false '[]' '[]' '[]' '[]'
  fi
  sleep 0.5
done
boot_wait_ms=$(($(date +%s%3N) - boot_start_ms))

animations=false
if [[ "$NO_ANIMATION_OFF" != "true" ]]; then
  invoke_adb "$SEL_SERIAL" shell settings put global animator_duration_scale 0 >/dev/null || true
  invoke_adb "$SEL_SERIAL" shell settings put global transition_animation_scale 0 >/dev/null || true
  invoke_adb "$SEL_SERIAL" shell settings put global window_animation_scale 0 >/dev/null || true
  animations=true
fi

grants_applied='[]'
grants_skipped='[]'
warnings='[]'

if [[ -n "$PACKAGE" && -n "$GRANTS" ]]; then
  IFS=',' read -ra PERMS <<< "$GRANTS"
  ga=()
  gs=()
  for p in "${PERMS[@]}"; do
    p="${p// /}"
    [[ -z "$p" ]] && continue
    if invoke_adb "$SEL_SERIAL" shell pm grant "$PACKAGE" "$p" >/dev/null 2>&1; then
      ga+=("\"$p\"")
    else
      gs+=("\"$p\"")
    fi
  done
  grants_applied="[$(IFS=,; echo "${ga[*]}")]"
  grants_skipped="[$(IFS=,; echo "${gs[*]}")]"
fi

ra=()
for rev in "${REVERSE_LIST[@]}"; do
  invoke_adb "$SEL_SERIAL" reverse "$rev" >/dev/null || true
  ra+=("\"$rev\"")
done
reverse_applied="[$(IFS=,; echo "${ra[*]}")]"

export ANDROID_SERIAL="$SEL_SERIAL"
emit_result PASS "$SEL_SERIAL" PASS "$SEL_MSG" "$POLICY" "$boot_wait_ms" "$animations" "$grants_applied" "$grants_skipped" "$reverse_applied" "$warnings"
