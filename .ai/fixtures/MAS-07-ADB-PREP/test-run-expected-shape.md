# Test Run Device Section — Expected Shape

Required when prep attempted or device commands in strategy.

```markdown
## Device

| Field | Value |
|-------|-------|
| Prep gate | PASS \| FAIL \| SKIPPED |
| Serial | <serial or —> |
| Policy | physical \| emulator \| auto |
| Exit code | PASS \| NO_DEVICE \| UNAUTHORIZED \| … \| — |
| Grants applied | <list or —> |
| Message | <actionable text from prep JSON> |
```

**PASS example:** Prep gate PASS; Serial R58M90ABCDE; Policy physical; Exit code PASS.

**FAIL example:** Prep gate FAIL; Serial —; Exit code UNAUTHORIZED; Message cites enrollment checklist.

**SKIP example:** Prep gate SKIPPED; Serial —; Message cites JVM-only or BLOCKED rationale.
