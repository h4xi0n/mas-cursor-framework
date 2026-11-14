# List Surface Performance

Reference for the **Performance Optimization** agent when the scope is a collection: feed, catalog, search results, history, inbox, notifications, grid, infinite scroll, or any listing API. Android Dev and General Dev implement the decision. They do not restyle the row.

## Purpose

Decide, with numbers:

1. Whether the collection is paginated, and which strategy.
2. The page size (limit) for the first request and every following request.
3. How the first screen becomes visible within a load budget.
4. Which **container** (composable, XML view group, or web list host) to use so the same item UI loads and scrolls faster.

Item pixels stay the same. Padding, type, color, copy, elevation, and which fields are on the row are out of scope.

## When this applies

Apply when any of these are true:

- Handoff `LIST_SURFACE: true` (lite: `LIST:y`)
- Scope is a list, feed, grid, search results, history, inbox, or a collection endpoint
- Code uses `LazyColumn` / `LazyVerticalGrid` / `LazyRow`, `Column` + scroll of repeated items, `RecyclerView`, `ListView`, `NestedScrollView` of repeated rows, Paging 3, or a web list that renders every row

Skip (write `## List Surface Decision` as `N/A — not a collection`):

- Detail, form, settings, or a menu of **5 or fewer** fixed local text rows
- User said skip list analysis / skip perf

## Visual parity (hard rule)

| Allowed | Forbidden |
|---------|-----------|
| Swap the **scroller** (`Column`+`verticalScroll` → `LazyColumn`, `ListView`/`ScrollView` rows → `RecyclerView`, non-virtual web list → windowed list) | Restyle the item composable, item XML, or row CSS |
| Same item composable / same item layout XML / same row component, same order | Add or remove visible fields, dividers, badges, or images |
| Keys, `contentType`, `ListAdapter`/`DiffUtil`, stable ids | New skeleton, shimmer, or footer the screen does not already have |
| Image **request** sized to the existing slot | Permanent placeholder instead of the image |
| Page size, prefetch, dispatcher, parse off the main thread | Pull-to-refresh, filters, search, or navigation that is not already there |
| `enablePlaceholders = false` when placeholders would shift layout | Turning on Paging placeholders that change row positions |
| Cache headers the server already sends | New query fields, new endpoints, or a fatter/thinner JSON shape |

A container swap is valid only when the item file’s visible output is unchanged. Say which item file is frozen.

If the only way to hit the budget is a visible change, put it under **Significant-Gain Exceptions** with the metric gained. Default is no exception.

## Decision procedure

Run in order. Record every input you used. Unknown inputs stay `unknown` and lower confidence — still pick a number from the defaults below. Do not leave page size as "TBD".

### 1. Classify the collection

| Kind | Default pagination | Client pattern |
|------|--------------------|----------------|
| Feed, inbox, notifications, anything that inserts at the head | **Cursor / keyset** | Paging 3 or equivalent windowed source |
| Search results that need a total, or a stable admin table | **Offset / limit** (page index only if the API is already page-index) | Paging 3 or one-shot pages |
| Grid | Same as the data shape above | `LazyVerticalGrid` / `GridLayoutManager` — page size multiple of span |
| Hard cap ≤ 20 text rows, no images, no growth | **None** — one response | Plain lazy/recycler list, no pager |
| API has no paging params and the server caps the body | **None** — do not loop to "get all" | Render the one response; note the cap under Open Questions |

Prefer cursor for mutable ordered collections. Offset is acceptable when the list is stable, the user needs a total, or the contract is already offset. Do not invent a cursor the API does not return. If the contract is offset-only and the collection is a live feed, choose offset for this change and file a keyset migration under Open Questions (API contract follow-up — not this patch).

### 2. Count a viewport

Use the first source that exists:

1. Design spec or existing item min height.
2. Compact phone content height **640dp** (800dp minus typical app bars) divided by item min height.
3. Defaults when height is unknown: **8** cards, **12** single-line rows, **span × 4** grid cells. Span defaults to **2** when unknown.

`visible` = that count (minimum 1).

### 3. Choose page size

```
raw = visible + visible          # one extra viewport, prefetched
grid: round raw up to a multiple of span
```

Then clamp `raw`:

| Item weight | Min | Max |
|-------------|-----|-----|
| Text-only row | 10 | 30 |
| One remote image | 6 | 15 |
| Two or more images, or a nested horizontal list | 4 | 10 |

`pageSize` = clamped value.

Payload check (estimated p95 JSON for one page, images excluded when they load as separate URLs):

- Target **≤ 100KB** for the first body.
- If `pageSize` at the clamp floor still exceeds 100KB, keep the floor and record a contract note under Open Questions. Do not drop fields the UI shows.

First page and next pages use the **same** `pageSize`. A smaller first page is a Significant-Gain Exception only when a loading state already exists and the smaller page is what makes time-to-first-item fit the budget.

Paging 3 footgun: the default `initialLoadSize` is `pageSize * 3`. For network lists set **`initialLoadSize = pageSize`** so the first request matches this limit. `prefetchDistance` = `visible` (one viewport, minimum 2). `enablePlaceholders = false` unless every item has a fixed height **and** the current UI already reserves those slots.

Name the existing query parameter (`limit`, `page_size`, `per_page`, `count`, cursor). Do not rename it.

### 4. Load-time budget

Split the first screen. Mark each stage `measured` or `estimated`:

| Stage | Budget (typical network) | Flag |
|-------|--------------------------|------|
| Time to first item (click or enter → first row visible) | **< 800ms** | **> 1200ms** |
| Same, warm cache | **< 300ms** | **> 500ms** |
| Server wait (TTFB) vs body size | Call out which one dominates | Body over 100KB on first page |
| Parse and map | Off the main thread | JSON or DB on the main thread |
| Scroll | No frame over **16ms** from the list (8ms only if the project is already 120Hz) | New allocations per row during fling |
| Images | Decode at the slot size in px | Full-size decode or `Size.ORIGINAL` |

Static reading of the code without a trace is **MEDIUM** at best. Do not invent millisecond baselines.

### 5. Pick the container

Choose the fastest host that can render the **current** item without editing that item’s layout.

**Compose**

| Current | Use instead | Why it is faster | Parity |
|---------|-------------|------------------|--------|
| `Column` / `verticalScroll` that emits every row | `LazyColumn` or `LazyVerticalGrid` | Composes visible rows only | Same item composable |
| `LazyColumn` missing `key` or `contentType` | Add stable id `key` and `contentType` per view type | Stops full recompose and wrong reuse | No layout edit |
| List collected as one `List` in `StateFlow` for an unbounded source | `LazyPagingItems` / Pager | First page only | Same item composable |
| Nested `LazyColumn` inside a vertical scroll | One `LazyColumn` with multiple item types | One composition and measure pass | Same item composables, stacked |
| `AndroidView` list whose rows are Compose-shaped | `LazyColumn` | Drops an extra view hierarchy | Same visuals |

Keep `beyondBoundsItemCount` at **0** unless a finding shows composition jank after the page-size fix. Then set it to about half of `visible`, not to a large prefetch.

**XML**

| Current | Use instead | Why it is faster | Parity |
|---------|-------------|------------------|--------|
| `ScrollView` / `NestedScrollView` inflating every row | `RecyclerView` + `ListAdapter` | Recycles row views | Same item layout XML |
| `ListView` | `RecyclerView` + `ListAdapter` | Better recycle and partial updates | Same row XML |
| `RecyclerView` with `notifyDataSetChanged` | `ListAdapter` + `DiffUtil` on a stable id | Binds changed rows only | Same row XML |
| Nested `RecyclerView` with `wrap_content` inside another list | One `RecyclerView` and view types, or a shared `RecycledViewPool` | One measure pass; recycled children | Same item layouts |
| Image loaded at intrinsic size | `override` / `size` equal to the `ImageView` | Decode matches the slot | Same `ImageView` bounds |

`setHasFixedSize(true)` only when the recycler’s own size does not depend on adapter contents (typical `match_parent` list).

**Web (General Dev)**

| Current | Use instead | Parity |
|---------|-------------|--------|
| Map of every row into the document | Windowed list (`content-visibility`, a virtualizer the repo already uses) | Same row component |
| Unbounded fetch | Cursor or offset with the page size above | Same row |

Do not add a virtualizer dependency the repo does not already have if an in-repo pattern exists. If none exists, recommend the smallest in-platform option (`content-visibility: auto` on the row) before a new library, and mark a new library as an Open Question.

### 6. Request and cache

- One page in flight per direction. Do not serially prefetch the whole collection.
- Cancel the previous search page when the query changes.
- Parse on `Dispatchers.IO` (or the platform equivalent). Map to the row model before the UI sees the payload.
- Use ETag / 304 and the HTTP cache only when the server already sends validators. Do not add cache semantics the API does not honor.
- Distinct-until-changed on the row list so an identical page does not recompose.

### 7. Rank

Primary findings, max **5**, list-specific first:

1. Pagination strategy + page size (if today is unbounded, oversized, or `initialLoadSize` is 3×).
2. Container swap, if the current host builds every row or nests scrollers.
3. Main-thread parse, image decode size, or missing stable keys — only if they miss the budget.

Micro-opts (a single `remember` with no scroll or load effect) go to the watch list.

## Brief section (required for collections)

```markdown
## List Surface Decision

| Field | Value |
|-------|-------|
| Surface | <screen and endpoint> |
| Growth | bounded ≤ N \| unbounded |
| Pagination | cursor \| offset \| page \| none — <one line why> |
| Page size | <n> |
| Basis | visible=<n>, prefetch=<n>, span=<n>, weight=<text\|1 image\|heavy>, payload=<KB or unknown> |
| First-page budget | TTFI < 800ms network / < 300ms cache; body ≤ 100KB |
| Paging config | initialLoadSize=<n>, prefetchDistance=<n>, placeholders=false\|true |
| Request | <existing param names and values> |
| Container | `<current>` → `<replacement>` |
| Item UI frozen | `<path>` — no visual edit |
| Image policy | decode to slot \| no remote image \| N/A |
| Confidence | HIGH \| MEDIUM \| LOW |
```

`Expected Improvement` must name at least one of: first-response KB, time to first item, or frames dropped while flinging. "Faster" alone is not a target.

## Dev implementation lock

Dev implements the table. Dev may skip a **LOW** confidence row with a one-line reason. Dev may not:

- Pick a different page size because another round number "feels" better
- Edit the frozen item file except for a non-visual bind (`key` input, image size that matches the existing slot, `remember` that does not move pixels)
- Add a loading composable or XML the screen does not already use

If Architect wrote a different limit, the list decision wins on page size unless Architect cited a hard API maximum. Use the API maximum and note the conflict in `PERF_FIXES_APPLIED`.

## Reviewer checks

Pass only when all are true:

- Code requests the decided page size on the first load (`initialLoadSize` included)
- Strategy matches (cursor vs offset vs single shot)
- The frozen item file has no visual diff (layout, padding, color, text style, visible children)
- The container matches the brief
- No new chrome (skeleton, footer, filter)

Otherwise `Performance Verification` is **NO** and the fix routes back to Dev.
