# UX Review — MAS-04-B-FIX-ALL

## Feature

Phase B dogfood UI widget — `IconOnlyActionButton` on a settings-style list surface (synthetic stub).

## User Goal

Complete the primary action on the settings screen: remove the selected item from a list via the icon-only trash control.

## Persona Journey

1. As a user, I open the settings screen and scan the list for the item I want to remove.
2. I locate the circular trash icon button beside (or on) the target row and tap it, expecting the item to be removed.
3. On success, I expect the list to update and my selection/focus to remain coherent so I can continue editing settings.
4. If I tapped by mistake, I expect a way to undo or confirm before the removal is final.
5. If I use keyboard only, I tab to the button, activate with Enter/Space, and expect focus to land somewhere sensible after the row disappears.

## Friction Points

| # | Dimension | Moment | User struggle | Why it hurts | Behavioral fix | Priority | Files hint |
|---|-----------|--------|---------------|--------------|----------------|----------|------------|
| 1 | Expectation alignment / Error recovery | Settings list → tap trash icon on a row | I tapped the trash icon and the row vanished instantly with no warning; I wasn't sure I hit the right row and couldn't take it back | Destructive delete with zero guardrail erodes trust; mis-taps cause irreversible loss on a settings screen where users often skim | Gate `handleRemove` behind a lightweight confirm step (e.g., `window.confirm` or inline confirm-on-second-tap within 3s) before calling remove; or show an undo snackbar for 5–8s that restores the item on dismiss/action | P1 | `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md` |
| 2 | Feedback timing | Immediately after trash click, item removed from DOM | The item just disappeared — I didn't get any signal that *my* action caused the change vs. a background refresh | Without action-attributed feedback, users double-check the screen or repeat the tap, slowing the flow and risking duplicate actions | After successful removal, announce via `aria-live="polite"` region ("Item removed") and/or surface a brief undo toast; keep focus context stable | P1 | `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md` |
| 3 | Keyboard / focus order | Keyboard user activates trash → list item unmounts | After pressing Enter on the trash button, focus dropped to nowhere (or the page root) and I lost my place in the list | Breaks keyboard traversal on settings lists; users must re-tab from the top, increasing effort and error rate | Before unmount, capture `document.activeElement`; on remove, move focus to the next sibling row's primary control, previous row, or a `tabIndex={-1}` list container fallback | P1 | `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md` |
| 4 | Touch targets / ergonomics | Rapid double-tap on trash icon while list re-renders | I tapped twice quickly and wasn't sure whether one or two items were removed | Missing transient guard allows duplicate `handleRemove` invocations during async or slow re-render | Disable the button (`disabled` or `aria-disabled`) from first click until removal settles; ignore subsequent clicks while `isRemoving` is true | P2 | `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md` |
| 5 | Discoverability | First visit to settings list, icon-only control | I saw a small circle with a trash icon but wasn't 100% sure it removes *this* row vs. clears the whole list | Icon-only affordances rely on convention; without row-scoped context users hesitate before acting | Pass row/item identifier into click handler and scope feedback copy to that item ("Remove {itemName}?"); defer visible text labels to a11y/i18n — no layout change required | P2 | `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md` |

### Deferred to a11y (not evaluated here)

- Missing `aria-label` / accessible name (WCAG 4.1.2) — screen reader announces generic "button"
- No `title` / tooltip fallback (WCAG 2.4.6) — programmatic naming gap

## Recommended Behavioral Fixes (ranked)

1. **P1 — Add undo or confirm before destructive remove.** Prefer undo snackbar (5–8s) to preserve one-tap speed for intentional deletes while allowing mistake recovery; confirm dialog acceptable for high-stakes settings.
2. **P1 — Post-remove feedback + focus restoration.** Pair `aria-live` announcement with explicit focus move to next/previous row or list container after unmount.
3. **P1 — Scope removal feedback to the affected item.** Include item name in undo/confirm copy so users know which row was targeted.
4. **P2 — Idempotent click guard.** Set `isRemoving` flag; disable control until parent list confirms removal complete.

## Preserve UI Checklist

- [x] No layout moves proposed
- [x] No cosmetic/token changes proposed

## Overall Confidence

**MEDIUM** — Primary happy path and keyboard edge traced against the stub markup; parent list/screen orchestration is not in seed `FILES`, so confirm/undo wiring and focus targets are inferred from intended behavior.

## Regression Notes

N/A — No same-day changelog entries reference this widget or `IconOnlyActionButton`; Phase B chain (`MAS-04-B`) added specialist routing only.

## Files Reviewed

- `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md`

## Open Questions

- Is removal synchronous (local list state) or async (API)? Undo semantics differ — API delete may need optimistic rollback vs. local-only restore.
- Does the settings list support multi-select removal, or strictly one row per trash button? Affects double-submit severity.
- What is the desired confirm pattern for this product — modal confirm vs. undo toast? (Product policy, not UX-only.)
