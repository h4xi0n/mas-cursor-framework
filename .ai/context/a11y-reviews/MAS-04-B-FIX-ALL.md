# A11y Review — MAS-04-B-FIX-ALL

**Scope:** `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md` — `IconOnlyActionButton` markup stub only.  
**Standard:** WCAG 2.2 Level AA (advisory).  
**Excluded:** Behavioral friction (confirm/undo, focus restoration after unmount, double-submit guards) — owned by ux-intelligence per mutual-exclusion matrix.

## Audit scope

| Item | Value |
|------|-------|
| Component | `IconOnlyActionButton` |
| Surface | Web / React (logic-only stub) |
| Control type | Native `<button type="button">` with icon-only child (`TrashIcon aria-hidden="true"`) |
| Files reviewed | `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md` |

## WCAG table

| # | Criterion | Level | Status | Finding | Recommendation | Priority |
|---|-----------|-------|--------|---------|----------------|----------|
| 1 | 1.3.1 Info and Relationships | A | pass | Native `<button>` conveys correct role; decorative icon correctly marked `aria-hidden="true"`. | No change required for role/relationship semantics. | — |
| 2 | 2.1.1 Keyboard | A | pass | Native button is in tab order and activatable via Enter/Space per HTML spec; intended behavior aligns. | Verify in manual test with no `tabIndex` overrides or parent `pointer-events: none`. | P2 |
| 3 | 2.4.6 Headings and Labels | AA | fail | Icon-only control has no visible text and no programmatic accessible name (`aria-label`, `aria-labelledby`, or visually hidden text). | Add `aria-label` scoped to list context, e.g. `aria-label="Remove item"` or `aria-label={\`Remove ${itemName}\`}` when row context is available. | P0 |
| 4 | 2.4.7 Focus Visible | AA | partial | Stub classes define hover (`hover:bg-muted`) only; no explicit `:focus` / `:focus-visible` ring. Conformance depends on global CSS or UA default outline. | Add visible `:focus-visible` indicator (e.g. `focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2`) that meets 3:1 contrast against adjacent colors. | P1 |
| 5 | 2.5.8 Target Size (Minimum) | AA | partial | `p-2` padding around SVG implies ~32×32 px hit area if icon is 16 px — likely meets 24×24 minimum, but dimensions are not declared in stub. | Confirm rendered size ≥ 24×24 CSS px; increase padding or `min-h`/`min-w` if icon or density tokens shrink below threshold. | P2 |
| 6 | 4.1.2 Name, Role, Value | A | fail | Role and state are correct; **accessible name is missing**. Screen readers will announce a generic "button" with no purpose because the only child is `aria-hidden`. | Same as row 3: `aria-label="Remove item"` (or context-specific variant). Prefer `aria-label` over `title` alone for primary naming. | P0 |
| 7 | 1.4.3 Contrast (Minimum) | AA | n/a | Text contrast not applicable (no visible text). Icon/background colors reference `hover:bg-muted` token without resolved values in stub. | Verify icon stroke/fill against default and hover backgrounds in implementation; aim ≥ 4.5:1 if any text is added. | P2 |
| 8 | 1.4.11 Non-text Contrast | AA | n/a | Trash icon and button boundary colors not specified with concrete values in stub. | Verify icon and focus ring meet 3:1 against adjacent background in light/dark themes. | P2 |
| 9 | 3.2.1 On Focus | A | pass | No context change on focus in stub markup. | None. | — |
| 10 | 3.2.2 On Input | A | pass | `onClick` only; no unexpected navigation or submit on activation. | None for stub; parent form context should keep `type="button"`. | — |
| 11 | 4.1.3 Status Messages | AA | n/a | Status/result messaging is parent/list responsibility, not present in this stub. | Parent should expose removal outcome via `aria-live` if required — out of this component stub scope. | — |

## Findings

| # | Component | Issue | WCAG ref | Severity | Fix agent |
|---|-----------|-------|----------|----------|-----------|
| 1 | `IconOnlyActionButton` | Missing accessible name on icon-only button; SR users hear "button" with no purpose | 4.1.2 (A), 2.4.6 (AA) | P0 | dev |
| 2 | `IconOnlyActionButton` | No explicit focus-visible styling in stub; risk of insufficient focus indicator if global CSS suppresses outline | 2.4.7 (AA) | P1 | dev |
| 3 | `IconOnlyActionButton` | Hit target size assumed from `p-2` but not verified in stub | 2.5.8 (AA) | P2 | dev |
| 4 | `IconOnlyActionButton` | Icon/background contrast not verifiable from token-only stub | 1.4.3, 1.4.11 (AA) | P2 | dev |

## Fix priority

1. **P0 — Add accessible name.** Set `aria-label="Remove item"` (minimum) or bind to row context: `aria-label={\`Remove ${itemName}\`}`. Do not rely on `title` alone; `title` is supplemental, not a primary accessible name.
2. **P1 — Ensure visible focus indicator.** Add `focus-visible` ring styles that remain visible in light and dark themes and meet non-text contrast requirements.
3. **P2 — Validate target size and contrast at implementation.** Confirm rendered control ≥ 24×24 px and icon/focus colors pass contrast checks once design tokens resolve.

## Keyboard navigation notes

- Native `<button type="button">` participates in document tab order by default.
- Activation: Enter and Space trigger `onClick` without additional handlers.
- No `disabled` / `aria-disabled` state in stub; if added during async removal, ensure `aria-disabled` is paired with explanatory text or `aria-describedby` if the control remains focusable.

## Screen reader notes

- Current stub: announced as unnamed button; purpose is opaque.
- `TrashIcon aria-hidden="true"` is correct — decorative icon must not duplicate the accessible name once `aria-label` is added.
- Recommended announcement after fix: "Remove item, button" (or "Remove [item name], button" when row context is wired).
- Do **not** add visible text solely for SR; use `aria-label` or visually hidden text per project i18n patterns.

## Manual checklist

- [ ] Tab to trash button; confirm it receives focus in logical list order
- [ ] Activate with Enter and Space; confirm `handleRemove` fires once
- [ ] Screen reader (NVDA/VoiceOver): verify button exposes meaningful name after `aria-label` is added
- [ ] Keyboard-only: confirm focus indicator is visible on `:focus-visible`
- [ ] Measure rendered control; confirm ≥ 24×24 CSS px touch target
- [ ] Spot-check icon and focus ring contrast in light and dark themes

## Advisory notice

This review is **advisory v1**. Findings route to dev/bug-fix; reviewer remains sole `Approved:` gate. No source patches were made.

## Files reviewed

- `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md`

## Confidence

**HIGH** for P0 naming gap (explicit in stub seed). **MEDIUM** for focus/contrast/target-size rows — depend on global styles and token resolution not present in stub.
