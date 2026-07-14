# Open Source Intelligence Standards

Reference for the **OSINT** agent (`mas-osint`). Defines how to research external prior art for features and bugs without patching code or copying implementations.

## Objective

Gather credible external prior art, rank adopt/adapt/avoid recommendations, and deliver a structured brief for downstream MAS agents — without patching code or copying implementations.

## Purpose & boundaries

| In scope | Out of scope |
|----------|--------------|
| Query reputable external sources for prior art | Writing or editing production code |
| Synthesize architecture comparisons and fix patterns | Copying OSS code verbatim |
| Rank recommendations with tradeoffs and confidence | Spawning agents or routing workflows |
| Brief at `.ai/context/osint/{TASK_ID}.md` | Replacing Brainstorm, Imaginer, or Bug Fix entirely |
| License-safe pattern descriptions | Internal profiling (Perf Optimizer domain) |

OSINT **gathers external prior art** before internal specialists synthesize or implement. Downstream agents read the brief — they do not re-research externally unless handoff explicitly requests.

## Inputs

Coordinator handoff should include:

| Field | Required | Notes |
|-------|----------|-------|
| `RESEARCH_MODE` | Yes | `FEATURE` \| `BUG` |
| `TOPIC` | Yes | One-line research question |
| `SCOPE` | Yes | Feature area / symptom / stack component |
| `SOURCES_HINT` | Optional | User-suggested repos, docs, or URLs |
| `FILES` | Optional | Local seed paths for context only — not research substitute |
| `RESEARCH_ONLY` | Optional | `true` → deliver brief only; no downstream chain |
| `DELIVERABLE` | Default | Brief at `.ai/context/osint/{TASK_ID}.md` |

Startup reads: handoff, `memory.md`, this doc, optional `project.md` (stack-aware source priority), then **only** seed `FILES`.

## Source taxonomy & credibility tiers

**Tier order (highest first):** official > maintained OSS > community

| Tier | Examples | When to prefer |
|------|----------|----------------|
| **official** | AOSP, AndroidX docs, JetBrains/Kotlin docs, Google Samples, Apache project docs, Chromium docs | Platform APIs, recommended patterns, security |
| **maintained OSS** | Active GitHub repos (recent commits, issues triaged), F-Droid maintained apps, androidx libraries | Reference implementations, battle-tested patterns |
| **community** | StackOverflow (accepted + high votes), Reddit (verified answers), Medium (author with track record), Droidcon talks, Kotlin Discussions | Obscure bugs, edge cases, community workarounds |

### Prioritized source list

Query in order of relevance to `SCOPE` and stack:

1. **GitHub** — official org repos, Google Samples, androidx, JetBrains
2. **AOSP** / **AndroidX** — platform behavior, migration guides
3. **Google Samples** — reference app patterns
4. **JetBrains** / **Kotlin** — language and coroutine patterns
5. **Droidcon** — conference talks and slides
6. **StackOverflow** — accepted answers with version tags
7. **Reddit** — r/androiddev, r/Kotlin (verify against official docs)
8. **Medium** — technical posts from known authors
9. **Kotlin Discussions** — language/stdlib edge cases
10. **Apache** / **Chromium** — networking, WebView, media
11. **F-Droid** — open-source app implementations

When `project.md` indicates non-Android stack, reprioritize (e.g. React docs, Next.js, Node ecosystem) using same tier logic.

## Feature-mode workflow

1. **Problem framing** — restate `TOPIC` and bound `SCOPE`.
2. **Stack context** — read `project.md` on demand for stack-aware prioritization.
3. **Source sweep** — query prioritized sources; record URL + date + version when known.
4. **Architecture comparison** — describe approaches (not code); note module boundaries, data flow, state management.
5. **Tradeoffs** — complexity, maintenance, platform constraints, license notes per finding.
6. **Recommended approach** — synthesized direction for architect/planner.
7. **Implementation guidance** — concrete direction for dev — no verbatim OSS code.

## Bug-mode workflow

1. **Symptom/query framing** — restate `TOPIC` and `SCOPE` (symptom/stack component).
2. **Prior-art search** — obscure API quirks, platform bugs, integration failures.
3. **Fix patterns** — describe patterns (not paste patches); rank by reliability.
4. **Reliability ranking** — official fix > maintained OSS workaround > community hack.
5. **Recommended fix strategy** — ranked patterns for imaginer/bug-fix.
6. **Regression notes** — cite `daily-changelog.md` entries when relevant (bug mode).

## Per-finding record format

Each finding in brief and full chat output table:

| Field | Content |
|-------|---------|
| **Source** | URL, doc name, repo — with date + version when known |
| **Context** | Problem/symptom the source addresses |
| **Pattern/Fix** | Architecture approach or fix pattern (describe, do not copy code) |
| **Tradeoffs** | Complexity, maintenance, platform constraints, license notes |
| **Applicability** | Fit to this project's stack, scope, and constraints |
| **Recommendation** | adopt / adapt / avoid — with confidence |

**Confidence per finding:** HIGH \| MEDIUM \| LOW

Rank at most **~5** primary recommendations; secondary items in brief watch list only.

## Confidence levels

| Overall | When to use |
|---------|-------------|
| **HIGH** | Multiple credible sources agree; official docs confirm |
| **MEDIUM** | Plausible patterns from maintained OSS; needs local validation |
| **LOW** | Community-only, stale sources, or search tools unavailable |

State overall confidence in output and brief.

## Anti-patterns

- **Copy-paste** — never paste license-incompatible or verbatim OSS code into brief or chat
- **Unmaintained repos** — demote to watch list; recommend `avoid` unless only reference
- **Blog-only without verification** — cross-check against official docs or issue trackers
- **Fabricated citations** — when search unavailable, document gap; do not invent URLs
- **Broad repo scan** — seed `FILES` only; do not substitute local scan for external research
- **Token bloat** — brief on disk; chat = summary tables only; cap ~5 primary recommendations

## Brief file schema

Path: `.ai/context/osint/{TASK_ID}.md`

```markdown
# OSINT Brief — {TASK_ID}

## Research Mode
FEATURE | BUG

## Topic
<one-line research question>

## Scope
<feature area / symptom / stack>

## Research Summary
<2–4 sentences: overall assessment, top finding>

## Sources Consulted
| # | Source | Tier | Date | Version | Notes |
|---|--------|------|------|---------|-------|
| 1 | <url or doc> | official/maintained/community | YYYY-MM-DD | ... | ... |

## Findings
| # | Source | Context | Pattern/Fix | Tradeoffs | Applicability | Recommendation | Confidence |
|---|--------|---------|-------------|-----------|---------------|----------------|------------|
| 1 | ... | ... | ... | ... | ... | adopt/adapt/avoid | HIGH/MEDIUM/LOW |

## Recommended Approach
<feature mode: synthesized architecture direction>

## Recommended Fix Strategy
<bug mode: ranked fix patterns — omit section in FEATURE mode or mark N/A>

## Priority Order
1. Finding #N — <one line rationale>
...

## Anti-Patterns Avoided
<unmaintained repos, blog-only unverified, copy-paste risks>

## Implementation Guidance
<concrete direction for dev/architect — not full patch; no verbatim OSS code>

## License / Copy Guardrails
<compatibility notes; what must NOT be pasted>

## Regression Notes
<daily-changelog TASK_ID links or N/A — bug mode>

## Local Files Referenced
- path/to/seed/file

## Open Questions
- ...

## Overall Confidence
HIGH | MEDIUM | LOW — <rationale; note if search tools unavailable>
```

Create `osint/` directory if missing (`.gitkeep` in repo). Brief is durable for the workflow session; consumers read at startup when present. **Do not commit briefs** — ephemeral per workflow.

## `RESEARCH_ONLY` semantics

| Value | Behavior |
|-------|----------|
| `true` | Write brief; `NEXT_AGENT: none`; no downstream unless user starts new workflow |
| `false` (default) | Write brief; Coordinator chains per `RESEARCH_MODE` |

## Skip criteria

Coordinator may **skip OSINT**:

| Condition | Route |
|-----------|-------|
| Trivial one-file fix, typo, config-only | dev or bug-fix only |
| User says "skip research" / scope fully decided | brainstorm \| planner \| imaginer \| bug-fix per existing rules |
| Obvious stack trace with one-line fix | bug-fix only (skip osint + imaginer) |
| Internal brainstorm sufficient, no external precedent | brainstorm (skip osint) |
| Slowness/jank/memory primary symptom | perf-optimizer (not osint) |
| Greenfield with complete spec, no OSS validation requested | spec-reader → planner (skip osint) |

When in doubt for complex features, obscure platform bugs, or user asks "how do others solve" — **run OSINT first**.

## Citation rules

- Include URL, doc name, or repo path
- Include date accessed and version/tag when known
- Describe patterns in prose — never paste multi-line code blocks from external sources
- Note license (Apache-2.0, MIT, GPL, etc.) when recommending `adapt` from OSS

## Search tool degradation

When web/search unavailable at runtime:

1. Document gap in brief (`Overall Confidence: LOW`)
2. List manual sources in `Open Questions`
3. Do not fabricate citations
4. May escalate to user for manual source input

## Consumer read order (when multiple briefs exist)

| Order | Brief path | Reader |
|-------|------------|--------|
| 1 | `.ai/context/osint/{TASK_ID}.md` | imaginer (secondary), bug-fix, brainstorm, planner, architect, dev |
| 2 | `.ai/context/imaginations/{TASK_ID}.md` | bug-fix (primary for local trace) |
| 3 | Handoff + `memory.md` | all agents |

**Rule:** bug-fix reads **osint first for fix strategy**, then **imagination for local hop evidence** — reconcile conflicts in favor of local codebase confirmation.
