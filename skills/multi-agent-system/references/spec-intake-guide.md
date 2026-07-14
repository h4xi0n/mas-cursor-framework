# Spec Intake Guide

Reference for the Spec Reader agent. Extract facts from source documents — do not invent requirements.

## Document Types

| Type | Examples | Extract |
|------|----------|---------|
| **Requirements** | PRD, user stories, feature brief (.md, .docx path) | Goals, scope, in/out of scope, acceptance criteria |
| **API contracts** | OpenAPI/Swagger, GraphQL schema, REST markdown, protobuf | Endpoints, methods, auth, request/response shapes, errors, versioning |
| **Design** | Figma links, UI spec, wireframes | Screens, flows, states, responsive notes (flag if link-only) |
| **Architecture** | ADR, system diagram docs, module README | Layers, boundaries, integration points |
| **Backend / shared** | `backend changes.md`, contract PDFs, Postman collections | Breaking changes, field nullability, rate limits |
| **Project** | README, AGENTS.md, `.ai/context/project.md` | Stack, modules, existing patterns |
| **Tickets** | Jira/Linear export, issue description pasted in handoff | Title, repro, expected vs actual |

## Reading Rules

1. Read every path listed in handoff `DOCS:` or `FILES:`.
2. If PDF/binary unreadable, note `UNREADABLE — user must paste summary or export markdown`.
3. If Figma/design link only, note `DESIGN_LINK — visual spec not inlined; Planner/Dev need design reference`.
4. Cross-check `.ai/context/memory.md` — flag conflicts with documented requirements.
5. Never paste entire documents into output; distill into brief sections.
6. Quote acceptance criteria and API field names **exactly** when critical.

## Conflicts & Gaps

- **Conflict**: doc A vs doc B or vs memory.md → list under Open Questions with both sides.
- **Gap**: missing auth flow, error codes, empty states → Open Questions with suggested default (not decided).
- **Assumption**: only when doc silent AND blocking; mark `ASSUMPTION — confirm with stakeholder`.

## Output Persistence

Write full brief to `.ai/context/specs/{TASK_ID}.md` (local, gitignored).
Handoff to Planner references this path — do not duplicate full brief in chat.

## Downstream Use

| Consumer | Uses from brief |
|----------|-----------------|
| **Planner** | Requirements, acceptance criteria, dependencies, open questions |
| **Architect** | API contract, modules, integration, constraints |
| **Android Dev / General Dev** | Acceptance criteria, API shapes, UI states (via Planner/Architect handoff) |

Spec Reader does **not** plan tasks or write code.
