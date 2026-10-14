# UI Widget Stub — MAS-04-B-FIX-ALL

Synthetic interactive widget for Phase B dogfood. **Not production code** — describes a component with a known a11y gap for P1-2 `FILES` predicate testing.

## Component

**Name:** `IconOnlyActionButton`  
**Type:** Interactive button (icon-only, no visible text label)  
**Surface:** Web / React (logic-only stub — no Gradle module)

## Intended behavior

- Renders a circular button with a trash-can SVG icon.
- On click, removes the selected item from a list.
- Keyboard: should be focusable and activatable via Enter/Space.

## Markup stub (intentional gap)

```tsx
<button
  type="button"
  className="rounded-full p-2 hover:bg-muted"
  onClick={handleRemove}
>
  <TrashIcon aria-hidden="true" />
</button>
```

## Known accessibility issues (dogfood seed)

| Issue | WCAG | Notes |
|-------|------|-------|
| **Missing `aria-label`** | 4.1.2 Name, Role, Value (A) | Icon-only control has no accessible name; screen readers announce "button" with no purpose. |
| No `title` fallback | 2.4.6 Headings and Labels (AA) | No visible or programmatic label for sighted AT users. |

## Expected specialist action

a11y agent should flag missing accessible name and recommend `aria-label="Remove item"` (or equivalent, tied to list context).
