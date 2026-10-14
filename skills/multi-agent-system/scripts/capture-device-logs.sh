#!/usr/bin/env bash
# MAS capture-device-logs gate — prep-gated logcat clear, marker, and dump.
# POSIX twin of capture-device-logs.ps1.
#
# Downstream log capture consumer chained after android-device-prep (MAS-07).
# Emits a single JSON object on stdout (last line). Idempotent re-run safe.
# --dry-run prints planned adb ops without a device. Fixture env vars bypass real adb.
#
# Exit codes:
#   0  PASS or CAPTURE_EMPTY    1  ADB_NOT_FOUND    7  INVALID_ARGS
#   10 NO_SERIAL                 11 UNAUTHORIZED     12 OFFLINE
#   21 DUMP_FAILED
#
# Env: ADB_DEVICES_FIXTURE, ADB_LOGCAT_FIXTURE, ADB_CRASH_LOGCAT_FIXTURE,
#      ADB_API_LEVEL_FIXTURE, ADB_PIDOF_FIXTURE, ANDROID_SERIAL
# See device-log-capture.md and .ai/fixtures/MAS-09-LOG-CAPTURE/
set -euo pipefail

SUBCOMMAND=""
SERIAL=""
PACKAGE=""
TAG="APP_TRACE"
BUFFERS="main,crash"
FORMAT=""
OUTPUT_DIR=""
TASK_ID=""
MAX_LINES=0
DRY_RUN=false
JSON_ONLY=false

usage() {
  cat <<'EOF'
Usage: capture-device-logs.sh <subcommand> [options]

Subcommands: clear | marker | dump | clear-and-marker

Options:
  --serial <id>           Device serial (default: ANDROID_SERIAL)
  --package <id>          Application id for pidof PID filter
  --tag <name>            Logcat tag filter (default: APP_TRACE)
  --buffers <list>        Comma-separated buffers (default: main,crash)
  --format json|threadtime Override format detection
  --output-dir <path>     Artifact root
  --task-id <id>          TASK_ID (required for marker/dump/clear-and-marker)
  --max-lines <n>         Truncate tail per buffer (0 = unbounded)
  --dry-run               Print planned adb ops
  --json-only             Suppress non-JSON stderr on success
  --help                  Show this help
EOF
}

log_info() {
  if [[ "$JSON_ONLY" != "true" ]]; then
    echo "$1"
  fi
}

# Last stdout line is always JSON; process exit mirrors exit_code field.
emit_result() {
  local status="$1" exit_code="$2" message="$3" meta_path="$4" line_count="$5"
  local meta_json line_json
  if [[ -z "$meta_path" ]]; then meta_json="null"; else meta_json="\"$meta_path\""; fi
  if [[ -z "$line_count" ]]; then line_json="null"; else line_json="$line_count"; fi
  printf '{"status":"%s","exit_code":"%s","message":"%s","capture_meta_path":%s,"line_count":%s}\n' \
    "$status" "$exit_code" "$message" "$meta_json" "$line_json"
  case "$exit_code" in
    PASS|CAPTURE_EMPTY) exit 0 ;;
    ADB_NOT_FOUND) exit 1 ;;
    INVALID_ARGS) exit 7 ;;
    NO_SERIAL) exit 10 ;;
    UNAUTHORIZED) exit 11 ;;
    OFFLINE) exit 12 ;;
    DUMP_FAILED) exit 21 ;;
    *) exit 1 ;;
  esac
}

get_adb_path() {
  command -v adb 2>/dev/null || true
}

parse_devices() {
  while IFS= read -r line; do
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^List\ of\ devices ]] && continue
    if [[ "$line" =~ ^([^[:space:]]+)[[:space:]]+([^[:space:]]+) ]]; then
      echo "${BASH_REMATCH[1]}|${BASH_REMATCH[2]}"
    fi
  done
}

get_devices_list() {
  if [[ -n "${ADB_DEVICES_FIXTURE:-}" ]]; then
    parse_devices < "$ADB_DEVICES_FIXTURE"
    return
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "dry-run-device|device"
    return
  fi
  adb devices -l 2>/dev/null | parse_devices
}

test_connectivity() {
  local serial="$1" state found=false
  if [[ "$DRY_RUN" == "true" ]]; then return 0; fi
  while IFS='|' read -r dev_serial dev_state; do
    if [[ "$dev_serial" == "$serial" ]]; then
      found=true
      state="$dev_state"
      break
    fi
  done < <(get_devices_list)
  if [[ "$found" != "true" ]]; then
    echo "OFFLINE|Device $serial not found or not in device state."
    return 1
  fi
  if [[ "$state" == "unauthorized" ]]; then
    echo "UNAUTHORIZED|Device $serial unauthorized — complete USB debugging enrollment."
    return 1
  fi
  if [[ "$state" != "device" ]]; then
    echo "OFFLINE|Device $serial is $state."
    return 1
  fi
  return 0
}

# Routes adb calls to fixture files when fixture env set; dry-run logs planned ops only.
invoke_adb() {
  local serial="$1"
  shift
  local args=("$@")
  local cmd="adb"
  [[ -n "$serial" ]] && cmd+=" -s $serial"
  cmd+=" ${args[*]}"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] $cmd"
    echo ""
    return 0
  fi

  if [[ -n "${ADB_DEVICES_FIXTURE:-}" || -n "${ADB_LOGCAT_FIXTURE:-}" || -n "${ADB_API_LEVEL_FIXTURE:-}" ]]; then
    local sub="${args[*]}"
    if [[ "$sub" == "logcat -c" ]]; then echo ""; return 0; fi
    if [[ "$sub" == "shell getprop ro.build.version.sdk" ]]; then
      echo "${ADB_API_LEVEL_FIXTURE:-34}"
      return 0
    fi
    if [[ "$sub" =~ ^shell\ pidof\ -s ]]; then
      if [[ "${ADB_PIDOF_EMPTY:-}" == "1" ]]; then echo ""; return 0; fi
      echo "${ADB_PIDOF_FIXTURE:-12345}"
      return 0
    fi
    if [[ "$sub" =~ ^logcat\ -d\ -b\ crash ]]; then
      if [[ -n "${ADB_CRASH_LOGCAT_FIXTURE:-}" && -f "$ADB_CRASH_LOGCAT_FIXTURE" ]]; then
        cat "$ADB_CRASH_LOGCAT_FIXTURE"
      fi
      return 0
    fi
    if [[ "$sub" =~ ^logcat\ -d\ -b\ main ]]; then
      if [[ -n "${ADB_LOGCAT_FIXTURE:-}" && -f "$ADB_LOGCAT_FIXTURE" ]]; then
        cat "$ADB_LOGCAT_FIXTURE"
      fi
      return 0
    fi
    echo ""
    return 0
  fi

  if [[ -n "$serial" ]]; then
    adb -s "$serial" "${args[@]}" 2>/dev/null || return 1
  else
    adb "${args[@]}" 2>/dev/null || return 1
  fi
}

iso_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%S.000Z"
}

count_lines() {
  local content="$1"
  if [[ -z "${content// }" ]]; then echo 0; return; fi
  echo "$content" | grep -c . || echo 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    clear|marker|dump|clear-and-marker) SUBCOMMAND="$1"; shift ;;
    --serial) SERIAL="$2"; shift 2 ;;
    --package) PACKAGE="$2"; shift 2 ;;
    --tag) TAG="$2"; shift 2 ;;
    --buffers) BUFFERS="$2"; shift 2 ;;
    --format) FORMAT="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    --max-lines) MAX_LINES="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --json-only) JSON_ONLY=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 7 ;;
  esac
done

[[ -z "$SUBCOMMAND" ]] && { usage; exit 7; }

# Serial resolution (ANDROID_SERIAL from prep Step 0; ADB_SERIAL alias)
[[ -z "$SERIAL" && -n "${ANDROID_SERIAL:-}" ]] && SERIAL="$ANDROID_SERIAL"
[[ -z "$SERIAL" && -n "${ADB_SERIAL:-}" ]] && SERIAL="$ADB_SERIAL"

use_fixture=false
[[ -n "${ADB_DEVICES_FIXTURE:-}" || -n "${ADB_LOGCAT_FIXTURE:-}" || -n "${ADB_API_LEVEL_FIXTURE:-}" ]] && use_fixture=true

adb_path="$(get_adb_path)"
if [[ -z "$adb_path" && "$use_fixture" != "true" && "$DRY_RUN" != "true" ]]; then
  emit_result "FAIL" "ADB_NOT_FOUND" "adb not found on PATH. Install Android Platform Tools." "" ""
fi

if [[ -z "$SERIAL" ]]; then
  emit_result "FAIL" "NO_SERIAL" "ANDROID_SERIAL unset — run android-device-prep (Step 0) first" "" ""
fi

if [[ "$SUBCOMMAND" =~ ^(marker|dump|clear-and-marker)$ && -z "$TASK_ID" ]]; then
  emit_result "FAIL" "INVALID_ARGS" "--task-id is required for $SUBCOMMAND subcommand." "" ""
fi

# Connectivity gate — prep-first invariant; no adb when NO_SERIAL/UNAUTHORIZED/OFFLINE
conn_err="$(test_connectivity "$SERIAL" 2>&1 || true)"
if [[ -n "$conn_err" ]]; then
  code="${conn_err%%|*}"
  msg="${conn_err#*|}"
  emit_result "FAIL" "$code" "$msg" "" ""
fi

if [[ -n "$OUTPUT_DIR" ]]; then
  ARTIFACT_DIR="$OUTPUT_DIR"
elif [[ -n "$TASK_ID" ]]; then
  ARTIFACT_DIR=".ai/context/device-logs/$TASK_ID"
else
  ARTIFACT_DIR=".ai/context/device-logs"
fi

if [[ "$SUBCOMMAND" == "clear" ]]; then
  invoke_adb "$SERIAL" logcat -c >/dev/null || emit_result "FAIL" "DUMP_FAILED" "adb logcat -c failed." "" ""
  emit_result "PASS" "PASS" "Logcat buffers cleared for $SERIAL." "" ""
fi

if [[ "$SUBCOMMAND" == "marker" ]]; then
  mkdir -p "$ARTIFACT_DIR"
  printf '{"repro_started_at":"%s","task_id":"%s","serial":"%s"}\n' \
    "$(iso_timestamp)" "$TASK_ID" "$SERIAL" > "$ARTIFACT_DIR/repro-marker.json"
  emit_result "PASS" "PASS" "Repro marker written to .ai/context/device-logs/$TASK_ID/repro-marker.json." "" ""
fi

if [[ "$SUBCOMMAND" == "clear-and-marker" ]]; then
  invoke_adb "$SERIAL" logcat -c >/dev/null || emit_result "FAIL" "DUMP_FAILED" "adb logcat -c failed during clear-and-marker." "" ""
  mkdir -p "$ARTIFACT_DIR"
  printf '{"repro_started_at":"%s","task_id":"%s","serial":"%s"}\n' \
    "$(iso_timestamp)" "$TASK_ID" "$SERIAL" > "$ARTIFACT_DIR/repro-marker.json"
  emit_result "PASS" "PASS" "Cleared logcat and wrote repro marker to .ai/context/device-logs/$TASK_ID/." "" ""
fi

# dump subcommand (clear/marker/clear-and-marker exit above via emit_result)
warnings=()
IFS=',' read -ra BUFFER_LIST <<< "$BUFFERS"

# Format fallback: API 30+ prefers json (-v json); older devices use threadtime (D4)
api_out="$(invoke_adb "$SERIAL" shell getprop ro.build.version.sdk)"
api_level=34
[[ "$api_out" =~ ^[0-9]+$ ]] && api_level="$api_out"

resolved_format="$FORMAT"
if [[ -z "$resolved_format" ]]; then
  if [[ "$api_level" -ge 30 ]]; then resolved_format="json"; else resolved_format="threadtime"; warnings+=("FORMAT_FALLBACK: threadtime"); fi
elif [[ "$resolved_format" == "json" && "$api_level" -lt 30 ]]; then
  resolved_format="threadtime"
  warnings+=("FORMAT_FALLBACK: threadtime")
fi

# PID resolve at dump time only; empty pidof → tag-only filter + PID_NOT_FOUND warning (D13)
pid=""
if [[ -n "$PACKAGE" ]]; then
  pid_out="$(invoke_adb "$SERIAL" shell pidof -s "$PACKAGE" | tr -d '[:space:]')"
  if [[ "$pid_out" =~ ^[0-9]+$ ]]; then
    pid="$pid_out"
  else
    warnings+=("PID_NOT_FOUND")
  fi
fi

mkdir -p "$ARTIFACT_DIR"
main_ext="txt"
[[ "$resolved_format" == "json" ]] && main_ext="jsonl"
main_path="$ARTIFACT_DIR/logcat-main.$main_ext"
crash_path="$ARTIFACT_DIR/logcat-crash.txt"
marker_path="$ARTIFACT_DIR/repro-marker.json"
meta_path="$ARTIFACT_DIR/capture-meta.json"

repro_started_at=""
if [[ -f "$marker_path" ]]; then
  repro_started_at="$(grep -o '"repro_started_at":"[^"]*"' "$marker_path" | head -1 | cut -d'"' -f4 || true)"
fi

# Main buffer: tag filter $TAG:D *:S (default APP_TRACE); optional --pid when package resolved
main_args=(logcat -d -b main -v "$resolved_format")
[[ -n "$pid" ]] && main_args+=(--pid="$pid")
main_args+=("$TAG:D" "*:S")

main_content="$(invoke_adb "$SERIAL" "${main_args[@]}")" || emit_result "FAIL" "DUMP_FAILED" "adb logcat main buffer dump failed." "" ""

if [[ "$MAX_LINES" -gt 0 ]]; then
  line_count_before="$(count_lines "$main_content")"
  main_content="$(echo "$main_content" | grep . | tail -n "$MAX_LINES" || true)"
  line_count_after="$(count_lines "$main_content")"
  [[ "$line_count_before" -gt "$line_count_after" ]] && warnings+=("TRUNCATED: main")
fi

printf '%s' "$main_content" > "$main_path"
main_line_count="$(count_lines "$main_content")"

# Crash buffer: full dump, no tag filter (captures FATAL EXCEPTION / tombstone lines)
crash_content="$(invoke_adb "$SERIAL" logcat -d -b crash)" || emit_result "FAIL" "DUMP_FAILED" "adb logcat crash buffer dump failed." "" ""
printf '%s' "$crash_content" > "$crash_path"
crash_line_count="$(count_lines "$crash_content")"

total_lines=$((main_line_count + crash_line_count))
rel_base=".ai/context/device-logs/$TASK_ID"
rel_main="$rel_base/logcat-main.$main_ext"
rel_crash="$rel_base/logcat-crash.txt"
rel_marker="null"
[[ -f "$marker_path" ]] && rel_marker="\"$rel_base/repro-marker.json\""

exit_code="PASS"
message="Dumped $total_lines lines to $rel_base/"
if [[ "$total_lines" -eq 0 ]]; then
  warnings+=("CAPTURE_EMPTY")
  exit_code="CAPTURE_EMPTY"
  message="Dump succeeded but 0 lines captured — check tag filter or repro window"
fi

pkg_json="null"
[[ -n "$PACKAGE" ]] && pkg_json="\"$PACKAGE\""
pid_json="null"
[[ -n "$pid" ]] && pid_json="$pid"
warnings_json="[]"
if [[ ${#warnings[@]} -gt 0 ]]; then
  warnings_json="["
  for i in "${!warnings[@]}"; do
    [[ $i -gt 0 ]] && warnings_json+=","
    warnings_json+="\"${warnings[$i]}\""
  done
  warnings_json+="]"
fi

cat > "$meta_path" <<METAEOF
{
  "status": "PASS",
  "task_id": "$TASK_ID",
  "serial": "$SERIAL",
  "package": $pkg_json,
  "tag_filter": "$TAG",
  "buffers": ["main","crash"],
  "format": "$resolved_format",
  "api_level": $api_level,
  "pid": $pid_json,
  "paths": {
    "main": "$rel_main",
    "crash": "$rel_crash",
    "marker": $rel_marker
  },
  "line_count": { "main": $main_line_count, "crash": $crash_line_count, "total": $total_lines },
  "repro_started_at": $(if [[ -n "$repro_started_at" ]]; then echo "\"$repro_started_at\""; else echo "null"; fi),
  "dumped_at": "$(iso_timestamp)",
  "warnings": $warnings_json
}
METAEOF

emit_result "PASS" "$exit_code" "$message" "$rel_base/capture-meta.json" "$total_lines"
