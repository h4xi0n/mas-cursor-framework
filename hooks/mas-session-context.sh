#!/usr/bin/env bash
# MAS session/subagent hooks for Cursor (macOS/Linux)
set -euo pipefail

EVENT="${1:-unknown}"
INPUT_RAW=""

if [ -t 0 ] || [ -p /dev/stdin ]; then
  INPUT_RAW="$(cat 2>/dev/null || true)"
fi

workspace_root=""
if command -v jq >/dev/null 2>&1 && [ -n "$INPUT_RAW" ]; then
  workspace_root="$(echo "$INPUT_RAW" | jq -r '.workspace_roots[0] // .root // .cwd // empty' 2>/dev/null || true)"
fi

get_latest_handoff() {
  local root="$1"
  local dir="$root/.ai/handoffs"
  [ -d "$dir" ] || return 0
  ls -t "$dir"/*.md 2>/dev/null | head -1
}

get_next_agent() {
  local file="$1"
  [ -f "$file" ] || return 0
  local next
  next="$(grep -E '^NEXT_AGENT:' "$file" 2>/dev/null | head -1 | sed -E 's/^NEXT_AGENT:[[:space:]]*//; s/[[:space:]]+$//' | tr '[:upper:]' '[:lower:]')"
  [ "$next" = "none" ] && return 0
  echo "$next"
}

get_pending_handoff() {
  local root="$1"
  local dir="$root/.ai/handoffs"
  [ -d "$dir" ] || return 0
  local f
  for f in $(ls -t "$dir"/*.md 2>/dev/null); do
    if grep -qE '^NEXT_AGENT:[[:space:]]*[^[:space:]]' "$f" 2>/dev/null && \
       ! grep -qE '^NEXT_AGENT:[[:space:]]*none[[:space:]]*$' "$f" 2>/dev/null; then
      if grep -qE '^SPAWN_STATUS:[[:space:]]*spawned[[:space:]]*$' "$f" 2>/dev/null; then
        echo "$f"
        return 0
      fi
      if ! grep -qE '^SPAWN_STATUS:[[:space:]]*complete' "$f" 2>/dev/null; then
        echo "$f"
        return 0
      fi
    fi
  done
}

if [ "$EVENT" = "sessionStart" ]; then
  if [ -n "$workspace_root" ] && [ -d "$workspace_root/.ai/context" ]; then
    msg='Multi-agent context at .ai/context/. Use /mas-lite for low-token orchestration (memory.md only) or /mas for full pipeline (project + standards + memory).'
    printf '{"additional_context":"%s"}' "$msg"
    exit 0
  fi
  echo '{}'
  exit 0
fi

if [ "$EVENT" = "subagentStop" ]; then
  if [ -n "$workspace_root" ]; then
    pending="$(get_pending_handoff "$workspace_root")"
    [ -z "$pending" ] && pending="$(get_latest_handoff "$workspace_root")"
    if [ -n "$pending" ]; then
      next="$(get_next_agent "$pending")"
      if [ -n "$next" ]; then
        base="$(basename "$pending")"
        followup="Coordinator: Task subagent finished. Handoff ${base} has NEXT_AGENT: ${next}. Set SPAWN_STATUS complete, write new handoff, spawn Task (generalPurpose, run_in_background false). Do not implement inline."
        printf '{"followup_message":"%s"}' "$followup"
        exit 0
      fi
    fi
  fi
  echo '{}'
  exit 0
fi

echo '{}'
exit 0
