#!/usr/bin/env bash
# Install MAS Cursor framework on macOS/Linux
set -euo pipefail

BUNDLE_ROOT=""
ZIP_PATH=""
TARGET_CURSOR_HOME="${HOME}/.cursor"
FORCE=0
SKIP_HOOKS=0

usage() {
  echo "Usage: $0 [-b bundle_dir] [-z zip_file] [-t ~/.cursor] [-f] [--skip-hooks]"
  exit 1
}

while getopts "b:z:t:f" opt; do
  case "$opt" in
    b) BUNDLE_ROOT="$OPTARG" ;;
    z) ZIP_PATH="$OPTARG" ;;
    t) TARGET_CURSOR_HOME="$OPTARG" ;;
    f) FORCE=1 ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ "${1:-}" = "--skip-hooks" ] && SKIP_HOOKS=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_EXTRACT=""

if [ -n "$ZIP_PATH" ]; then
  TEMP_EXTRACT="$(mktemp -d)"
  unzip -q "$ZIP_PATH" -d "$TEMP_EXTRACT"
  if [ -d "$TEMP_EXTRACT/mas-cursor-framework" ]; then
    BUNDLE_ROOT="$TEMP_EXTRACT/mas-cursor-framework"
  else
    BUNDLE_ROOT="$(find "$TEMP_EXTRACT" -mindepth 1 -maxdepth 1 -type d | head -1)"
  fi
fi

if [ -z "$BUNDLE_ROOT" ]; then
  if [ -d "$SCRIPT_DIR/../skills/multi-agent-system" ]; then
    BUNDLE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  elif [ -d "$SCRIPT_DIR/skills/multi-agent-system" ]; then
    BUNDLE_ROOT="$SCRIPT_DIR"
  else
    echo "Error: specify -b bundle_dir or -z zip_file" >&2
    exit 1
  fi
fi

MANIFEST="$SCRIPT_DIR/manifest.json"
[ -f "$MANIFEST" ] || MANIFEST="$BUNDLE_ROOT/install/manifest.json"

mkdir -p "$TARGET_CURSOR_HOME"

copy_tree() {
  local src="$1" dest="$2"
  [ -e "$src" ] || return 0
  if [ -e "$dest" ] && [ "$FORCE" -eq 0 ]; then
    echo "Skip (exists, use -f): $dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest" 2>/dev/null || true
  cp -R "$src" "$dest"
  echo "Installed: $dest"
}

echo "Installing MAS to: $TARGET_CURSOR_HOME"
echo "From bundle: $BUNDLE_ROOT"
echo ""

SKILLS=""
if command -v python3 >/dev/null 2>&1; then
  SKILLS="$(python3 -c "import json; m=json.load(open('$MANIFEST')); print(' '.join(m['skills']))")"
elif command -v node >/dev/null 2>&1; then
  SKILLS="$(node -e "const m=require('$MANIFEST'); console.log(m.skills.join(' '))")"
else
  SKILLS="multi-agent-system mas mas-coordinator mas-brainstorm mas-planner mas-architect mas-android-dev mas-general-dev mas-bug-fix mas-reviewer mas-documenter mas-spec-reader mas-commit mas-lite"
fi

for skill in $SKILLS; do
  copy_tree "$BUNDLE_ROOT/skills/$skill" "$TARGET_CURSOR_HOME/skills/$skill"
done

for cmd in mas.md mas-lite.md; do
  [ -f "$BUNDLE_ROOT/commands/$cmd" ] && \
    copy_tree "$BUNDLE_ROOT/commands/$cmd" "$TARGET_CURSOR_HOME/commands/$cmd"
done

[ -f "$BUNDLE_ROOT/rules/multi-agent-hybrid.mdc" ] && \
  copy_tree "$BUNDLE_ROOT/rules/multi-agent-hybrid.mdc" "$TARGET_CURSOR_HOME/rules/multi-agent-hybrid.mdc"

mkdir -p "$TARGET_CURSOR_HOME/hooks"
for hook in mas-session-context.ps1 mas-session-context.sh; do
  [ -f "$BUNDLE_ROOT/hooks/$hook" ] && cp "$BUNDLE_ROOT/hooks/$hook" "$TARGET_CURSOR_HOME/hooks/$hook"
done
[ -f "$TARGET_CURSOR_HOME/hooks/mas-session-context.sh" ] && chmod +x "$TARGET_CURSOR_HOME/hooks/mas-session-context.sh"

[ -f "$BUNDLE_ROOT/USER-RULE-MAS.md" ] && \
  cp "$BUNDLE_ROOT/USER-RULE-MAS.md" "$TARGET_CURSOR_HOME/USER-RULE-MAS.md"

if [ "$SKIP_HOOKS" -eq 0 ]; then
  HOOK_SESSION='bash ./hooks/mas-session-context.sh sessionStart'
  HOOK_SUB='bash ./hooks/mas-session-context.sh subagentStop'
  HOOKS_JSON="$TARGET_CURSOR_HOME/hooks.json"

  if [ -f "$HOOKS_JSON" ] && command -v jq >/dev/null 2>&1; then
    cp "$HOOKS_JSON" "$HOOKS_JSON.bak.mas" 2>/dev/null || true
    jq --arg s "$HOOK_SESSION" --arg u "$HOOK_SUB" '
      .version = (.version // 1) |
      .hooks.sessionStart = ((.hooks.sessionStart // []) + [{command: $s}] | unique_by(.command)) |
      .hooks.subagentStop = ((.hooks.subagentStop // []) + [{command: $u}] | unique_by(.command))
    ' "$HOOKS_JSON" > "$HOOKS_JSON.tmp" && mv "$HOOKS_JSON.tmp" "$HOOKS_JSON"
    echo "Updated: hooks.json (merged with jq)"
  else
    cat > "$HOOKS_JSON" <<EOF
{
  "version": 1,
  "hooks": {
    "sessionStart": [{ "command": "$HOOK_SESSION" }],
    "subagentStop": [{ "command": "$HOOK_SUB" }]
  }
}
EOF
    echo "Created: hooks.json"
  fi
fi

[ -n "$TEMP_EXTRACT" ] && rm -rf "$TEMP_EXTRACT"

echo ""
echo "MAS installed. Reload Cursor, then use /mas or /mas-lite."
echo "Bootstrap project (requires pwsh):"
echo "  pwsh $TARGET_CURSOR_HOME/skills/multi-agent-system/scripts/init-mas-context.ps1 -ProjectPath <path> -Stack auto"
