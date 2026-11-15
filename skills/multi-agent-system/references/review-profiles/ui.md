# Review Profile: UI & Visual Presentation (`ui`)

Specialized domain checklist for reviewing mobile and web user interfaces, Compose/XML screens, design fidelity, and interactions.

---

## Invariants

1. **Sealed UiState:** UI must consume a strictly typed, sealed state representation (`Loading`, `Content`, `Empty`, `Error`). No loose concurrent mutable state properties.
2. **Touch Targets & Accessibility:** All interactive elements must maintain minimum $\ge 48\text{dp} \times 48\text{dp}$ touch targets and provide accessible content descriptions.
3. **Responsive & Font Scaling:** UI must withstand `fontScale` up to 2.0x without text clipping and support Compact (phone), Medium (foldable/tablet), and Expanded breakpoints.
4. **Visual Fidelity Verification:**
   - When `.ai/context/visual-qa/{TASK_ID}.md` exists: consume brief findings; do not re-capture.
   - When no Figma spec exists: execute **Imagined Visual QA** covering theme, spacing, loading, error, and rotation.
5. **No Recomposition Loops:** State changes must flow down via immutable parameters and events up via callbacks (UDF); no unstable lambda instantiations causing frame drops.

---

## Domain Checklist

Evaluate each item as `PASS`, `FAIL`, or `N/A`:

| Check Item | Requirement | Status | Notes |
|---|---|:---:|---|
| **UiState Completeness** | Sealed class with Loading, Content, Empty, and Error states. | | |
| **Touch Targets ($\ge 48\text{dp}$)** | Minimum touch target size on buttons, icons, and list items. | | |
| **Accessibility (WCAG AA)** | Content descriptions on icons, semantic headers, high contrast. | | |
| **Font Scaling (2.0x)** | Text wraps cleanly; no button clipping or vertical truncation. | | |
| **Responsive Breakpoints** | Layout adapts across phone, foldable, and tablet widths. | | |
| **Dark Theme & Tokens** | Uses theme tokens (MaterialTheme); zero hardcoded hex colors. | | |
| **Edge-to-Edge & Insets** | Correctly handles status bar, navigation bar, and IME insets. | | |

---

## Required Output Section

Render this section under `## Stage 2: Domain Deep-Dive (Profile: ui)`:

```markdown
## Visual QA & Presentation Verification

| Check | Status | Notes |
|-------|:------:|-------|
| Sealed UiState (Loading/Empty/Error) | PASS / FAIL | <state evaluation> |
| Touch Targets (≥48dp) | PASS / FAIL | <interactive sizing> |
| Accessibility & Semantics | PASS / FAIL | <contentDescription, contrast> |
| Responsive & FontScale (2.0x) | PASS / FAIL | <compact vs expanded, text wrap> |
| Theme & Design Tokens | PASS / FAIL | <color/spacing token usage> |
| Visual Fidelity Brief (if present) | PASS / FAIL / N/A | <visual-qa findings> |
```
