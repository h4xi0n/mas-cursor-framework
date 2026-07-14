# In-Code Documentation Standards

Reference for the Documenter agent. Comments live **in source files only** — not in handoffs or memory.md.

## Purpose

Keep comments aligned with the **current** code after every Dev or Bug Fix change.

## When to Comment

Add or update comments only for:

- Non-obvious business rules or domain constraints
- Workarounds (with ticket/issue reference if available)
- Complex algorithms, coordinate math, media/export pipelines
- Public API (`/** KDoc */` on classes, functions, properties exposed to other modules)
- Side effects easy to miss (threading, lifecycle, ordering requirements)

## When NOT to Comment

- Delete or avoid comments that restate the code (`// increment i`)
- No comments on obvious Compose layout or standard MVVM wiring
- No changelog blocks in source files
- No commented-out dead code — delete the code instead

## Operations

| Action | When |
|--------|------|
| **Create** | New non-obvious logic lacks explanation; new public API needs KDoc |
| **Update** | Behavior, params, or preconditions changed; comment no longer matches code |
| **Delete** | Code removed; comment describes old behavior; redundant with clearer code |
| **Edit** | Wording outdated, wrong module reference, or misleading |

## Style by Language

### Kotlin / Java

- Public API: KDoc `/** */` with `@param`, `@return`, `@throws` when helpful
- Internal non-obvious logic: short `//` above the block
- Multi-line: `/* */` only when KDoc; prefer `//` for internal notes
- Match existing file style ( tense, capitalization, language)

### Compose

- Document **why** state/effect ordering matters, not what `@Composable` does
- Do not annotate every composable — only non-obvious gesture/export/timeline behavior

## Rules

- **Comments only** — never change logic, formatting, or imports except as needed for KDoc targets
- Read the full diff context; compare with similar files in the project
- Preserve author intent; fix inaccuracy, not voice
- Keep comments concise (1–3 lines typical; KDoc can be longer for public API)
- If Dev output included `Visual Notes` or `Fix Strategy`, distill durable **why** into code comments where non-obvious — do not paste handoff text verbatim

## Documenter Must Not

- Write architecture docs outside changed files
- Update README, AGENTS.md, or memory.md (Reviewer/Coordinator handle memory)
- Add license headers unless file already uses them

## Reviewer Spot-Check

Reviewer flags **Major** if:

- Obvious stale comment left after behavior change
- Critical public API changed with no KDoc update
- Misleading comment contradicts code
