#!/usr/bin/env bash
# MAS connected-device adb capture — gate, launch, screencap, optional crop.
#
# Exit codes:
#   0 = Success (warnings allowed)
#   1 = adb not found on PATH
#   2 = Zero authorized devices
#   3 = Multiple devices; serial not specified
#   4 = Device unauthorized or offline
#   5 = Launch failed (app not installed, activity not found, deeplink error)
#   6 = Screencap or write failure
#   7 = Invalid arguments / missing required flag

set -euo pipefail

# Capture env before local assignments shadow them
_env_adb_serial="${ANDROID_SERIAL:-${ADB_SERIAL:-}}"
_env_package="${PACKAGE:-}"
_env_activity="${ACTIVITY:-}"
_env_deeplink="${DEEPLINK:-}"
_env_output="${OUTPUT:-}"

SERIAL=""
PACKAGE=""
ACTIVITY=""
DEEPLINK=""
ACTION="android.intent.action.VIEW"
EXTRAS=""
WAIT_MS=2000
OUTPUT=""
CLEAR_TASK=false
FONT_SCALE=""
UI_MODE=""
CROP=""
DRY_RUN=false
WARNINGS=()

usage() {
  cat <<'EOF'
Usage: capture-connected-device.sh --package <id> --output <path> [options]

Required:
  --package          Application ID
  --output           PNG output path

Optional:
  --serial           Device serial (env: ANDROID_SERIAL or ADB_SERIAL)
  --activity         Activity component
  --deeplink         Deeplink URI
  --action           Intent action (default: android.intent.action.VIEW)
  --extras           JSON map of intent extras
  --wait-ms          Post-launch wait ms (default: 2000)
  --clear-task       FLAG_ACTIVITY_CLEAR_TASK
  --font-scale       Pre-capture font_scale setting
  --ui-mode          night | day
  --crop             x,y,w,h crop rect (requires ImageMagick)
  --dry-run          Print adb commands without executing
  --help             Show this help

Exit codes: 0=success, 1=adb missing, 2=no devices, 3=multi-device no serial,
            4=unauthorized/offline, 5=launch failed, 6=screencap failed, 7=invalid args
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --serial) SERIAL="$2"; shift 2 ;;
    --package) PACKAGE="$2"; shift 2 ;;
    --activity) ACTIVITY="$2"; shift 2 ;;
    --deeplink) DEEPLINK="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --extras) EXTRAS="$2"; shift 2 ;;
    --wait-ms) WAIT_MS="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --clear-task) CLEAR_TASK=true; shift ;;
    --font-scale) FONT_SCALE="$2"; shift 2 ;;
    --ui-mode) UI_MODE="$2"; shift 2 ;;
    --crop) CROP="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 7 ;;
  esac
done

# Env fallbacks (after CLI parse)
[[ -z "$SERIAL" && -n "$_env_adb_serial" ]] && SERIAL="$_env_adb_serial"
[[ -z "$PACKAGE" && -n "$_env_package" ]] && PACKAGE="$_env_package"
[[ -z "$ACTIVITY" && -n "$_env_activity" ]] && ACTIVITY="$_env_activity"
[[ -z "$DEEPLINK" && -n "$_env_deeplink" ]] && DEEPLINK="$_env_deeplink"
[[ -z "$EXTRAS" && -n "${INTENT_EXTRAS:-}" ]] && EXTRAS="${INTENT_EXTRAS}"
[[ -n "${POST_LAUNCH_WAIT_MS:-}" ]] && WAIT_MS="${POST_LAUNCH_WAIT_MS}"
[[ -z "$OUTPUT" && -n "$_env_output" ]] && OUTPUT="$_env_output"
[[ -z "$CROP" && -n "${CROP_RECT:-}" ]] && CROP="${CROP_RECT}"
[[ -n "${FONT_SCALE:-}" ]] && FONT_SCALE="${FONT_SCALE}"
[[ -z "$UI_MODE" && -n "${UI_MODE:-}" ]] && UI_MODE="${UI_MODE}"
[[ "${CLEAR_TASK:-}" == "true" || "${CLEAR_TASK:-}" == "1" ]] && CLEAR_TASK=true

if [[ -z "$PACKAGE" || -z "$OUTPUT" ]]; then
  echo "Missing required --package and/or --output." >&2
  usage
  exit 7
fi

if [[ -z "$DEEPLINK" && -z "$ACTIVITY" ]]; then
  echo "At least one of --deeplink or --activity is required." >&2
  exit 7
fi

adb_cmd() {
  local args=()
  [[ -n "$SERIAL" ]] && args+=("-s" "$SERIAL")
  args+=("$@")
  if $DRY_RUN; then
    echo "[dry-run] adb ${args[*]}"
    return 0
  fi
  adb "${args[@]}"
}

if ! $DRY_RUN && ! command -v adb >/dev/null 2>&1; then
  echo "adb not found on PATH." >&2
  exit 1
fi

# Device gate
if $DRY_RUN; then
  [[ -z "$SERIAL" ]] && SERIAL="emulator-5554"
else
  mapfile -t device_lines < <(adb devices | tail -n +2)
  authorized=()
  bad=()
  for line in "${device_lines[@]}"; do
    [[ -z "$line" ]] && continue
    ser=$(echo "$line" | awk '{print $1}')
    state=$(echo "$line" | awk '{print $2}')
    if [[ "$state" == "device" ]]; then
      authorized+=("$ser")
    elif [[ "$state" == "unauthorized" || "$state" == "offline" ]]; then
      bad+=("$ser:$state")
    fi
  done

  if [[ ${#authorized[@]} -eq 0 && ${#bad[@]} -gt 0 ]]; then
    echo "Device unauthorized or offline: ${bad[0]}" >&2
    exit 4
  fi
  if [[ ${#authorized[@]} -eq 0 ]]; then
    echo "No authorized devices connected." >&2
    exit 2
  fi
  if [[ ${#authorized[@]} -gt 1 && -z "$SERIAL" ]]; then
    echo "Multiple devices connected; specify --serial, ANDROID_SERIAL, or ADB_SERIAL." >&2
    exit 3
  fi
  if [[ -z "$SERIAL" && ${#authorized[@]} -eq 1 ]]; then
    SERIAL="${authorized[0]}"
  fi
  if [[ -n "$SERIAL" ]]; then
    found=false
    for s in "${authorized[@]}"; do
      [[ "$s" == "$SERIAL" ]] && found=true
    done
    if ! $found; then
      echo "Device $SERIAL not found among authorized devices." >&2
      exit 2
    fi
  fi
fi

# Pre-capture
if [[ -n "$FONT_SCALE" ]]; then
  adb_cmd shell settings put system font_scale "$FONT_SCALE" || true
fi
if [[ -n "$UI_MODE" ]]; then
  mode_val="1"
  [[ "$UI_MODE" == "night" ]] && mode_val="2"
  adb_cmd shell settings put secure ui_night_mode "$mode_val" || true
fi

# Launch
launch_args=(shell am start)
[[ -n "$ACTION" ]] && launch_args+=(-a "$ACTION")
$CLEAR_TASK && launch_args+=(-f "0x08000000")
[[ -n "$DEEPLINK" ]] && launch_args+=(-d "$DEEPLINK")
if [[ -n "$ACTIVITY" ]]; then
  if [[ "$ACTIVITY" == .* ]]; then
    component="${PACKAGE}/${ACTIVITY}"
  elif [[ "$ACTIVITY" == */* ]]; then
    component="$ACTIVITY"
  else
    component="${PACKAGE}/${ACTIVITY}"
  fi
  launch_args+=(-n "$component")
fi

if [[ -n "$EXTRAS" ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 required to parse --extras JSON." >&2
    exit 7
  fi
  while IFS= read -r line; do
    launch_args+=($line)
  done < <(python3 -c "
import json, sys
m = json.loads(sys.argv[1])
for k, v in m.items():
    if isinstance(v, bool):
        print('--ez', k, 'true' if v else 'false')
    else:
        print('--es', k, str(v))
" "$EXTRAS")
fi

if $DRY_RUN; then
  adb_cmd "${launch_args[@]}"
  echo "[dry-run] sleep ${WAIT_MS} ms"
  adb_cmd exec-out screencap -p
  echo "[dry-run] write output -> $OUTPUT"
  [[ -n "$CROP" ]] && echo "[dry-run] magick crop $CROP"
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"serial\":\"${SERIAL}\",\"output\":\"${OUTPUT}\",\"width\":0,\"height\":0,\"timestamp\":\"${timestamp}\",\"warnings\":[\"dry-run\"]}"
  exit 0
fi

launch_out=$(adb_cmd "${launch_args[@]}" 2>&1) || true
if echo "$launch_out" | grep -qiE 'Error|Exception|does not exist|not found'; then
  echo "Launch failed: $launch_out" >&2
  exit 5
fi

sleep_sec=$((WAIT_MS / 1000))
[[ "$sleep_sec" -lt 1 ]] && sleep_sec=1
sleep "$sleep_sec"

mkdir -p "$(dirname "$OUTPUT")"

if ! adb_cmd exec-out screencap -p > "$OUTPUT"; then
  echo "Screencap failed." >&2
  exit 6
fi

# Optional crop
if [[ -n "$CROP" ]]; then
  if command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1; then
    IFS=',' read -r x y w h <<< "$CROP"
    if [[ -n "$x" && -n "$y" && -n "$w" && -n "$h" ]]; then
      tmp="${OUTPUT}.tmp.png"
      mv "$OUTPUT" "$tmp"
      if command -v magick >/dev/null 2>&1; then
        magick "$tmp" -crop "${w}x${h}+${x}+${y}" "$OUTPUT"
      else
        convert "$tmp" -crop "${w}x${h}+${x}+${y}" "$OUTPUT"
      fi
      rm -f "$tmp"
    else
      WARNINGS+=("Invalid crop rect format; expected x,y,w,h")
    fi
  else
    WARNINGS+=("ImageMagick not available; full-frame capture retained")
  fi
fi

# Dimensions via python or file
width=0
height=0
if command -v python3 >/dev/null 2>&1; then
  read -r width height < <(python3 -c "
from struct import unpack
with open('$OUTPUT', 'rb') as f:
    f.read(16)
    w, h = unpack('>II', f.read(8))
    print(w, h)
" 2>/dev/null || echo "0 0")
fi

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
warnings_json="[]"
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  warnings_json=$(printf '%s\n' "${WARNINGS[@]}" | python3 -c "import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))")
fi

summary="{\"serial\":\"${SERIAL}\",\"output\":\"${OUTPUT}\",\"width\":${width},\"height\":${height},\"timestamp\":\"${timestamp}\",\"warnings\":${warnings_json}}"
echo "$summary"

summary_path="${OUTPUT%.png}.summary.json"
echo "$summary" | python3 -m json.tool > "$summary_path" 2>/dev/null || echo "$summary" > "$summary_path"

exit 0
