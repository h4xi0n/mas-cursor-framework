#!/usr/bin/env bash
# MAS-10 P1: preToolUse warn when Shell bypasses mas-host-exec (fail-open).
set +e
input_raw=""
if [ -t 0 ]; then
  input_raw=""
else
  input_raw="$(cat)"
fi

command_str=""
if command -v jq >/dev/null 2>&1 && [ -n "$input_raw" ]; then
  command_str="$(echo "$input_raw" | jq -r '.command // .tool_input.command // .args.command // empty' 2>/dev/null)"
fi

if [ -z "$command_str" ]; then
  echo "{}"
  exit 0
fi

case "$command_str" in
  *mas-host-exec*) echo "{}"; exit 0 ;;
esac

norm=$(echo "$command_str" | tr '\\' '/')
gated=false
if echo "$norm" | grep -Eq '(^|[[:space:]/])(\./)?gradlew(\.bat)?([[:space:]]|$)'; then gated=true; fi
if echo "$norm" | grep -Eq '[[:space:]]adb[[:space:]]+install-multiple'; then gated=true; fi
if echo "$norm" | grep -Eq '[[:space:]]adb[[:space:]]+install'; then gated=true; fi

if $gated; then
  printf '%s\n' '{"warning":"Gradle/adb install should use mas-host-exec (see host-build-install-mutex.md)"}'
else
  echo "{}"
fi
exit 0
