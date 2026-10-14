# I18n Review — MAS-04-B-FIX-ALL

**Scope:** `.ai/fixtures/MAS-04-B-FIX-ALL/strings-stub.json` — synthetic string resource stub for Phase B dogfood. Cross-reference: `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md` (companion UI stub; extraction-gap check only).  
**Handoff SCOPE:** new strings, locale, RTL.  
**Advisory v1** — findings route to dev; reviewer remains sole `Approved:` gate. No source patches made.

## Audit scope

| Item | Value |
|------|-------|
| Fixture | `MAS-04-B-FIX-ALL` |
| Default locale | `en` |
| Supported locales | `en`, `de` |
| String keys | 8 |
| ICU plural keys | 1 (`plural.items`) |
| RTL locales | none declared |
| Files reviewed | `.ai/fixtures/MAS-04-B-FIX-ALL/strings-stub.json` |

## String inventory

| Key / resource | File | Hardcoded | Extraction status | Notes |
|----------------|------|-----------|-------------------|-------|
| `app.title` | strings-stub.json | no | extracted | Present `en`/`de`; no consumer reference in UI stub |
| `button.remove` | strings-stub.json | no | extracted | Value `"Remove"` / `"Entfernen"` — shorter than a11y-recommended accessible name `"Remove item"` |
| `button.save` | strings-stub.json | no | extracted | Present; no UI stub consumer |
| `list.empty` | strings-stub.json | no | extracted | Empty-state copy; complements `plural.items` |
| `confirm.delete.title` | strings-stub.json | no | extracted | Present; no wiring in UI stub |
| `confirm.delete.body` | strings-stub.json | no | extracted | Present; no wiring in UI stub |
| `error.network` | strings-stub.json | no | extracted | Present; no error-surface stub |
| `plural.items` | strings-stub.json | no | extracted (ICU) | Valid ICU plural for `en` and `de` |
| Accessible name for remove control | ui-widget-stub.md | yes | **missing** | a11y brief recommends `aria-label="Remove item"` — no matching key; `button.remove` is not context-complete |
| Trash icon / button chrome | ui-widget-stub.md | n/a | n/a | Decorative SVG; no user-visible string |

## Locale gaps

| Locale | Missing keys | Notes |
|--------|--------------|-------|
| `de` | 0 of 8 | Full parity with `en` for declared keys |
| `en` | 0 of 8 | Baseline complete for declared keys |
| *(undeclared)* | all 8 + gaps below | No `fr`, `es`, `ja`, or other expansion locales — acceptable for dogfood fixture |
| **RTL (`ar`, `he`, etc.)** | all keys + locale entry | Handoff `SCOPE` includes RTL; `supportedLocales` has no RTL language — **RTL readiness not demonstrated** |

### Locale tag observations

| Issue | Severity | Detail |
|-------|----------|--------|
| Short language tags only | P2 | `meta.defaultLocale` and `supportedLocales` use `en` / `de` without region subtags (`en-US`, `de-DE`). Valid BCP 47 but limits locale fallback precision and regional variant handling. |
| No fallback chain metadata | P2 | Only `defaultLocale: "en"`; no explicit `fallbackLocale` or per-key override rules for partial bundles. |
| German regional variants | P3 | Single `de` bucket; no distinction for `de-AT` / `de-CH` formal address or vocabulary if product expands DACH. |

## ICU and pluralization

| Key | Pattern | `en` | `de` | Status | Notes |
|-----|---------|------|------|--------|-------|
| `plural.items` | `{count, plural, one {...} other {...}}` | one / other | one / other | **pass** | Syntactically valid ICU MessageFormat; `#` placeholder correct |

### ICU / plural gaps

| Issue | Severity | Detail |
|-------|----------|--------|
| No `=0` branch on `plural.items` | P2 | English often wants `"0 items"` via `other` (works) but some products prefer `"No items"` via `=0` — `list.empty` covers empty list UI but not numeric zero in a counter label. |
| No `few` / `many` for locales that need them | P3 | Not required for `en`/`de`; document if future locales (`ar`, `pl`, `ru`) are added. |
| No ICU `select` / `number` / `date` samples | P3 | Fixture exercises plural only; no gendered select or formatted date/number patterns for dogfood breadth. |
| Accessible-name pattern not ICU-ready | P1 | Contextual remove label (`Remove {itemName}`) would need `{name}` interpolation; no key demonstrates variable insertion. |

## RTL

**Status:** Not ready — no RTL locale in `supportedLocales`, no RTL layout notes, no bidirectional string markers.

| Area | Finding | Priority |
|------|---------|----------|
| Locale roster | No `ar`, `he`, `fa`, or other RTL language tags | P1 (per handoff RTL scope) |
| String content | All current strings are LTR-safe (no embedded LTR/RTL mix) | pass |
| Layout coupling | `ui-widget-stub.md` uses physical Tailwind classes (`rounded-full`, `p-2`) — mirroring/icon placement for RTL is a dev/CSS concern; flag for implementation, not string file | P2 |
| Punctuation in `de` | German strings use standard punctuation; no leading/trailing marks that break in RTL contexts | pass |

RTL audit is **N/A for string parity** (no RTL locale declared) but **FAIL for handoff RTL scope** — recommend adding at least one RTL locale stub (e.g. `ar`) with mirrored key set before claiming RTL readiness.

## Extraction gaps

| # | Gap | Location | Priority |
|---|-----|----------|----------|
| 1 | No `button.remove.item` (or equivalent) for accessible name with list context | UI stub vs `button.remove` | P1 |
| 2 | a11y P0 fix (`aria-label="Remove item"`) is hardcoded English in review/stub guidance — not keyed | ui-widget-stub.md / a11y brief | P1 |
| 3 | Delete confirmation strings exist but remove action in UI stub has no confirm flow wiring | strings vs ui-widget-stub | P2 |
| 4 | `button.save`, `app.title`, `error.network` have no fixture consumers — orphan keys for dogfood | strings-stub.json | P3 |
| 5 | No loading / success / in-progress strings for async remove | strings-stub.json | P2 |
| 6 | No interpolation example (`{itemName}`, `{count}` outside plural) | strings-stub.json | P2 |

## Recommendations

| # | Item | Action | Priority | Fix agent |
|---|------|--------|----------|-----------|
| 1 | Accessible name extraction | Add key e.g. `button.remove.item` with ICU or simple template: `en` `"Remove item"` / `de` `"Eintrag entfernen"`; wire to `aria-label` in implementation | P1 | dev |
| 2 | Align `button.remove` semantics | Document or split: `button.remove` = short verb for visible UI; `button.remove.item` = SR label — avoid overloading one key | P1 | dev |
| 3 | RTL scope (handoff) | Add `ar` (or `he`) to `supportedLocales` with full key parity; add `meta.rtlLocales: ["ar"]` or equivalent convention | P1 | dev |
| 4 | Plural zero handling | Add `=0` branch to `plural.items` if counters display numeric zero: e.g. `en` `=0 {No items}` or rely on `list.empty` with explicit UX rule | P2 | dev |
| 5 | Locale tag policy | Adopt BCP 47 region tags (`en-US`, `de-DE`) in `meta` if product targets regional variants; document fallback | P2 | dev |
| 6 | Contextual interpolation | Add sample key with variable: `confirm.delete.named` → `"Delete {name}?"` / `"„{name}" löschen?"` for extraction-pattern dogfood | P2 | dev |
| 7 | Confirm flow strings | When delete is destructive, bind `confirm.delete.*` to remove flow or mark as future-scope in fixture README | P2 | dev |
| 8 | Orphan key hygiene | Add minimal fixture manifest listing key → consumer mapping, or trim unused keys from dogfood scope | P3 | dev |

## Cross-agent notes

- **a11y (MAS-04-B-FIX-ALL):** P0 accessible-name fix must use i18n key, not hardcoded `"Remove item"`. Recommend `aria-label={t('button.remove.item')}` pattern.
- **Mutual exclusion:** RTL *layout* mirroring (logical properties, icon flip) is dev/CSS; this brief owns locale roster and string architecture only.

## Advisory notice

This review is **advisory v1**. Findings route to dev/bug-fix; reviewer remains sole `Approved:` gate. No translation vendor workflow; no source patches were made.

## Files reviewed

- `.ai/fixtures/MAS-04-B-FIX-ALL/strings-stub.json`
- `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md` (extraction cross-check only)

## Confidence

**HIGH** for locale parity (`en`/`de`), ICU plural syntax, and accessible-name extraction gap. **MEDIUM** for RTL and regional locale-tag policy — fixture intentionally minimal; handoff RTL scope not yet reflected in data.
