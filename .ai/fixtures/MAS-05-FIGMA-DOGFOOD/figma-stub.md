# Figma stub — MAS-05-FIGMA-DOGFOOD

Synthetic handoff input for dogfood when live Figma MCP is unavailable or CI is offline.

## SOURCES_HINT

```
https://www.figma.com/design/MAS05STUB/MAS-Dogfood?node-id=1-42
```

## Parsed fields

| Field | Value |
|-------|-------|
| file-key | `MAS05STUB` |
| node-id | `1-42` |
| node-id (API format) | `1:42` |

## Handoff flags (full `/mas`)

```
FIGMA_SPEC: yes
SOURCES_HINT: https://www.figma.com/design/MAS05STUB/MAS-Dogfood?node-id=1-42
SCOPE: ui-from-figma
```

## Lite handoff (12-line cap)

```
FIG:y
SOURCES_HINT: https://www.figma.com/design/MAS05STUB/MAS-Dogfood?node-id=1-42
```

## Degrade-path stubs

| Case | SOURCES_HINT | Expected mas-figma behavior |
|------|--------------|----------------------------|
| No node-id | `https://www.figma.com/design/MAS05STUB/MAS-Dogfood` | Blocked brief + Open Questions HITL; never guess node |
| RE_EXTRACT | Same URL + `RE_EXTRACT: yes` on second pass | Re-spawn allowed |
| Remote-only MCP | Valid node-id; no `get_variable_defs` | Raw values + `tokens-unresolved (local MCP required)` flag |

## Mock brief fallback

When MCP unreachable, coordinator or mas-figma may copy `design-spec-stub.md` to `.ai/context/design-specs/MAS-05-FIGMA-DOGFOOD.md` with Open Questions noting mock provenance — **not** for merge approval without reviewer schema pass.
