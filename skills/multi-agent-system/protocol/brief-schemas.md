# Brief Schema Registry

Required markdown headings per brief type. Specialists complete even when sections are missing; **Reviewer** flags gaps as `Approved: NO` with schema gap notes.

## Registry

| Type | Path pattern | Required sections |
|------|--------------|-------------------|
| osint | `.ai/context/osint/{TASK_ID}.md` | Research Summary, Findings table, Recommended Approach (FEATURE) or Recommended Fix Strategy (BUG), Confidence |
| brainstorm | `.ai/context/brainstorms/{TASK_ID}.md` | Options table, Recommended, Logic Flow, Risks |
| plan | `.ai/context/plans/{TASK_ID}.md` | Tasks, Dependencies, Acceptance criteria |
| architecture | `.ai/context/architecture/{TASK_ID}.md` | Architecture, Modules, Layers, Contracts, Files |
| debate | `.ai/context/debates/{TASK_ID}.md` | Critics, Consensus, Action items, Dissent |
| audit | `.ai/context/audits/{TASK_ID}.md` | Step breakdown, Outliers, Recommendations |

## Validation guidance

| Role | Behavior |
|------|----------|
| Brief writers (osint, brainstorm, planner, architect, debate-synthesizer, token-auditor) | Include required sections when writing briefs; cite this file in skill Startup — do not paste full schema |
| Reviewer | On review, check briefs in chain against this registry; missing required sections → note in findings; may set `Approved: NO` for schema gaps on deliverable briefs |
| Coordinator | Does not validate headings inline — forwards `BRIEF_PATH` only |

## Subscription matrix

See [read-order.md](read-order.md) for which agents read which briefs at startup.

## `BRIEF_PATH` + `SECTIONS:` slice semantics

When handoff includes `BRIEF_PATH:` and optional `SECTIONS:` (lite: `BP:` / `SEC:`):

- Read only listed markdown headings from the brief file
- Invalid or missing `SECTIONS` headers → read full brief; Coordinator logs warning in user summary
- Omit `SECTIONS` → read full brief

## Related

- [handoff-format.md](handoff-format.md) — `BRIEF_PATH`, `SECTIONS:`
- [spawn-model-policy.md](spawn-model-policy.md) — model class per agent
