# UX Intelligence Standards

Reference for the **UX Intelligence** agent (`mas-ux-intelligence`). Defines how to simulate a real user on a feature, identify interaction friction, and recommend **production-grade behavioral fixes only** — no layout moves, no cosmetic changes, no visual redesign.

## Purpose & boundaries

| In scope | Out of scope |
|----------|--------------|
| Persona simulation — walk flows as a real user | Writing or editing production code |
| Friction analysis at interaction moments | Layout moves, hierarchy changes, visual redesign |
| Behavioral recommendations (state, timing, focus, feedback) | Color, typography, spacing, token changes |
| Accessibility interaction ergonomics (TalkBack traversal, focus order — not pixel contrast) | New screens or navigation structure changes |
| Brief at `.ai/context/ux-reviews/{TASK_ID}.md` | Spawning agents or routing workflows |
| Regression lens via `daily-changelog.md` when UX regression suspected | Replacing Dev or Reviewer entirely |

UX Intelligence **narrows interaction gaps** for Dev. Dev implements P0/P1 behavioral fixes; Reviewer validates via Interaction QA.

## Inputs

Coordinator handoff should include:

| Field | Required | Notes |
|-------|----------|-------|
| `FEATURE` | Yes | Screen or flow name |
| `USER_GOAL` | Yes | What the user is trying to accomplish |
| `SCOPE` | Yes | Screens/flows/states to evaluate (include empty/loading/error if applicable) |
| `FILES` | Preferred | Seed paths from Dev output |
| `UI_CHANGES` | Yes | Must be `YES` for UX Intelligence chain |
| `UX_ONLY` | Optional | `true` → deliver brief only; no dev fix chain |
| `DELIVERABLE` | Default | Brief at `.ai/context/ux-reviews/{TASK_ID}.md` |

Startup reads: handoff, `memory.md`, this doc, then **only** files listed in handoff `FILES` — no broad repo scan.

## Evaluation dimensions

All dimensions are **behavioral** — evaluate interaction quality, not visual design:

| Dimension | What to evaluate |
|-----------|------------------|
| **User flow** | Can the user complete the goal without confusion or dead ends? |
| **Navigation clarity** | Back-stack, pop behavior, deep-link re-entry, where am I? |
| **Perceived speed** | Skeleton vs spinner choice, optimistic UI, debounce, stale-while-revalidate |
| **Expectation alignment** | Does the system behave as the user expects after each action? |
| **Accessibility** | Screen reader traversal, focus order, semantic labels — behavior not pixels |
| **Touch targets / ergonomics** | Hit area behavior, double-tap guards, scroll vs tap conflicts |
| **Feedback timing** | Loading, success, error, snackbar/toast duration and dismiss behavior |
| **Gestures** | Swipe-to-dismiss, pull-to-refresh, long-press discoverability |
| **Discoverability** | Are affordances findable without visual redesign? |
| **Error recovery** | Retry affordance, rollback, undo, clear next step after failure |
| **Empty / loading states** | Behavioral content (retry CTA behavior) — not layout |
| **Permission UX** | Rationale timing, denied-state behavior, re-prompt flow |
| **Keyboard / focus order** | Tab order, IME behavior, focus trap escape |
| **Animation timing** | Duration and interruptibility — not visual style |
| **Haptics** | When feedback fires — not intensity curves |

## Persona workflow

1. **Anchor on `USER_GOAL`** — restate what the user wants in first person.
2. **Walk primary happy path** — step by step: "As a user, I tap X → I expect Y → I see Z."
3. **Stress edge paths** — empty, loading, error, offline, permission denied, back-stack pop, double-submit.
4. **Narrate struggle in first person** — "I tapped Export but nothing happened for 3 seconds and I wasn't sure it worked."
5. **Record friction** — each moment where struggle occurs gets a per-friction record.

Keep journeys **concrete** ("I tap Save → spinner appears → error snackbar dismisses before I can read it") not abstract ("error handling could be better").

## Per-friction record format

Each friction point in the brief table:

| Column | Content |
|--------|---------|
| **Dimension** | From evaluation dimensions above |
| **Moment** | Specific step in the journey (screen + action + state) |
| **User struggle** | First-person narration of confusion, friction, or failure |
| **Why it hurts** | Impact on goal completion, trust, or accessibility |
| **Behavioral fix** | Production-grade fix — state, timing, focus, feedback — **no layout/cosmetic** |
| **Priority** | P0 (blocks goal), P1 (significant friction), P2 (polish/documentation) |
| **Files hint** | Seed file paths where fix likely lives |

Example row:

| Navigation clarity | Settings → Export → back press | I pressed back and lost my export progress without warning | User loses work; breaks mental model of back-stack | Show confirmation dialog before pop when export in progress; preserve draft state on cancel | P0 | `ExportViewModel.kt`, `ExportScreen.kt` |

## Hard rule: never suggest cosmetic changes

**Reject** recommendations that change visual design:

- No layout moves, component relocation, or hierarchy changes
- No color, typography, spacing, or token changes
- No new screens or navigation structure
- No marketing copy rewrites

**Allowed** behavioral fixes:

- Debounce, disable states, loading indicators (skeleton vs spinner **choice**, not style)
- Snackbar/toast timing and dismiss behavior
- Focus order, TalkBack traversal, keyboard navigation
- Haptic triggers on success/error
- Retry affordance behavior, optimistic UI rollback
- Navigation pop behavior, back-stack preservation
- Copy-tone-for-clarity (error messages that explain next step — not marketing)

## Preserve UI constraint

Every brief must include a **Preserve UI Checklist** confirming:

- [ ] No layout moves proposed
- [ ] No cosmetic/token changes proposed

Fixes must not relocate components, change hierarchy, or alter visual tokens.

## Android vs generic layer notes

### Android (Jetpack / Compose)

| Concern | Behavioral focus |
|---------|------------------|
| Compose focus | `FocusRequester` order, `Modifier.focusable`, IME actions |
| TalkBack traversal | `contentDescription`, `semantics` traversal order — not visual labels |
| Predictive back | Back gesture preview behavior, commit vs cancel |
| Edge-to-edge insets | Inset **behavior** (keyboard push, system bar overlap handling) — not padding values |
| Process death | State restoration behavior on re-open |

### Generic (React, Next.js, web)

| Concern | Behavioral focus |
|---------|------------------|
| Focus management | Tab order, focus trap, `aria-live` announcement timing |
| Form validation | Inline error timing, submit disable behavior |
| Route transitions | Loading state during navigation, back-button behavior |
| Offline | Retry queue behavior, stale data indication |

## Confidence levels

| Overall | When to use |
|---------|-------------|
| **HIGH** | Full journey walked; friction points have clear behavioral fixes |
| **MEDIUM** | Primary path traced; edge paths partially evaluated |
| **LOW** | Incomplete files, missing states, or scope too broad for seed `FILES` |

State overall confidence in output and brief.

## Regression lens

When `.ai/context/daily-changelog.md` has same-day entries:

- Match feature area, `FILES`, or module prefix to changelog `TASK_ID`s
- Cite at most 2–3 entries: "Possible UX regression related to **{TASK_ID}** ({summary})"
- If changelog missing or empty, write `N/A` under Regression Notes

Dev and Reviewer read changelog independently — UX Intelligence adds **review-time** regression hints only.

## Brief file schema

Path: `.ai/context/ux-reviews/{TASK_ID}.md`

```markdown
# UX Review — {TASK_ID}

## Feature
...

## User Goal
...

## Persona Journey
1. As a user, I ...

## Friction Points
| # | Dimension | Moment | User struggle | Why it hurts | Behavioral fix | Priority | Files hint |
|---|-----------|--------|---------------|--------------|----------------|----------|------------|
| 1 | ... | ... | ... | ... | ... | P0/P1/P2 | ... |

## Recommended Behavioral Fixes (ranked)
1. ...

## Preserve UI Checklist
- [ ] No layout moves proposed
- [ ] No cosmetic/token changes proposed

## Overall Confidence
HIGH | MEDIUM | LOW

## Regression Notes
...

## Files Reviewed
- path/to/file

## Open Questions
- ...
```

Create `ux-reviews/` directory if missing. Brief is durable for the workflow session; Dev reads it on UX fix pass; Reviewer reads for Interaction QA.

## Skip criteria

Coordinator may **skip UX Intelligence** when:

- `UI_CHANGES: NO` — logic-only / backend-only work
- Trivial one-line UI text typo
- User explicitly says "skip ux review"
- Greenfield planning/architecture-only chains

When in doubt for new screens, interaction-sensitive flows, or post-dev UI work with `UI_CHANGES: YES` — **run UX Intelligence**.

## Related references

| Consumer | Role |
|----------|------|
| [mas-ux-intelligence/SKILL.md](../../mas-ux-intelligence/SKILL.md) | Agent workflow and output template |
| [handoff-format.md](../protocol/handoff-format.md) | Coordinator → UX Intelligence handoff fields |
| [handoff-format-lite.md](../protocol/handoff-format-lite.md) | Lite UX handoff and M/L/L+ UI chains |
| [mas-coordinator/SKILL.md](../../mas-coordinator/SKILL.md) | Routing, `NEXT_AGENT` mapping, dev fix loop |
| [mas-android-dev/SKILL.md](../../mas-android-dev/SKILL.md) / [mas-general-dev/SKILL.md](../../mas-general-dev/SKILL.md) | P0/P1 behavioral fix pass (`UX_BRIEF`) |
| [mas-reviewer/SKILL.md](../../mas-reviewer/SKILL.md) § Interaction QA | Validates P0 fixes and no cosmetic drift |
| [reviewer-lite.md](reviewer-lite.md) | Lite Interaction QA one-liner |

Brief path: `.ai/context/ux-reviews/{TASK_ID}.md`. Durable policy: `memory.md` — UX Intelligence (MAS-04).

## Mutual exclusion with Imaginer

Do not chain UX Intelligence + Imaginer on same `TASK_ID` unless user override:

| Symptom | Route to |
|---------|----------|
| Crash, wrong data, exception | **Imaginer** |
| Interaction friction, slowness-of-understanding | **UX Intelligence** |
| Both symptoms | User picks primary or run sequential workflows |
