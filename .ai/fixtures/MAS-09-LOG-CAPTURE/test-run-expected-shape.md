# Expected test-run shape — MAS-09 Device Logs

Required when `LOG_CAPTURE: yes` and capture attempted.

```markdown
## Device Logs

| Field | Value |
|-------|-------|
| Capture gate | PASS \| FAIL \| SKIPPED |
| Prep prerequisite | PASS (serial) \| FAIL \| SKIPPED |
| Clear executed | yes \| no |
| Dump path | .ai/context/device-logs/MAS-09/capture-meta.json |
| Format | json \| threadtime |
| Line count | <integer> |
| Tag filter | APP_TRACE |
| Package | com.example.app \| — |
| Message | <from script stdout JSON message> |
```

Omit **Device Logs** when `LOG_CAPTURE: no` with documented JVM-only skip rationale.
