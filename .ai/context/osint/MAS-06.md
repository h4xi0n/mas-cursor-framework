# OSINT Brief — MAS-06

## Research Mode

FEATURE

## Topic

What patterns reduce visual/layout inconsistencies between Figma designs and implemented UI in agentic design-to-code workflows — specifically closing the post-dev fidelity gap where MAS Reviewer Visual QA is imagined-only with no Figma comparison?

## Scope

MAS v1.3.0 `mas-figma` design-spec pipeline (pre-dev extraction → android-dev/general-dev implementation → imagined Visual QA at reviewer), post-dev fidelity verification, visual regression against design baselines, Figma MCP `get_screenshot` comparison, and Android/Compose screenshot testing. Stack: MAS multi-agent framework + Android/Kotlin/Compose target projects.

## Research Summary

Industry practice has moved beyond "mentally render the UI" toward **artifact-mandatory visual fidelity gates**: capture objective evidence (Figma baseline screenshot + implementation screenshot + structured measurements), compare before human/agent judgment, and block approval when artifacts are missing or stale. Figma's own Implement Design skill treats `get_screenshot` as the visual source of truth and recommends side-by-side comparison after implementation — but MAS currently captures the screenshot only at extraction time and never re-compares post-dev. Mature agentic pipelines (OpenAI design-qa, oh-my-openagent Lane C, visual-first-design, Automattic design-qa) separate **objective visual-qa** (screenshots, diffs, measured parity records) from **subjective review**, and require the former before the latter. A critical distinction from standard visual regression (Percy/Chromatic): those tools compare implementation-vs-implementation over time; **design fidelity** requires comparing implementation against the **approved Figma frame** as baseline — a gap tools like figma-audit, Applitools Eyes 10.22 Figma plugin, and SmartUI explicitly address. For agent workflows, the highest-confidence pattern is **measurement-first, screenshot-second**: extract numeric deltas from design-spec tokens vs rendered output (computed styles on web; layout inspector / screenshot tests on Android) and feed structured diffs back to dev — because LLM spatial comparison from screenshots alone is unreliable. For MAS, the fidelity gap is architectural: pre-dev extraction is strong, but post-dev verification has no specialist, no artifact contract, and Reviewer imagined Visual QA cannot detect spacing/token drift against the design-spec.

## Sources Consulted

| # | Source | Tier | Date | Version | Notes |
|---|--------|------|------|---------|-------|
| 1 | [Figma — Skill: Implement Design](https://developers.figma.com/docs/figma-mcp-server/skill-figma-implement-design/) | official | 2026-08 | Dev Mode MCP | `get_screenshot` as visual validation source of truth; post-impl side-by-side compare |
| 2 | [Figma MCP — validation-and-recovery.md](https://github.com/figma/dev-mode-mcp-server-guide/blob/main/skills/figma-use/references/validation-and-recovery.md) | official | 2026 | mcp-server-guide | Milestone `get_screenshot` after major changes; metadata-first cheap checks |
| 3 | [OpenAI role-specific-plugins — design-qa SKILL](https://github.com/openai/role-specific-plugins/blob/main/plugins/product-design/skills/design-qa/SKILL.md) | maintained OSS | 2026 | — | Post-impl comparison; source + implementation screenshots required; P0/P1/P2 iteration loop |
| 4 | [oh-my-openagent — visual-qa + Lane C review](https://github.com/code-yeongyu/oh-my-openagent/blob/main/packages/shared-skills/skills/visual-qa/SKILL.md) | maintained OSS | 2026 | v4.x | Objective visual-qa artifacts before design judgment; dual-oracle pass required |
| 5 | [visual-first-design](https://github.com/Stevekaplanai/visual-first-design) | community | 2026 | v0.1 | Evidence chain; adversarial reviewer fails missing/stale/fabricated visual proof |
| 6 | [figma-audit](https://github.com/sbassomp/figma-audit) | maintained OSS | 2026 | — | Figma-vs-deployed-app audit; 9-category hybrid comparison; fills design-fidelity gap Percy misses |
| 7 | [TestMu — Agentic Figma Visual QA / SmartUI](https://www.testmuai.com/blog/agentic-figma-visual-qa/) | vendor | 2026 | SmartUI | Figma frames as baseline; agent MCP tools for layout/pixel diff summaries |
| 8 | [Applitools — Figma Design Baselines + Eyes MCP](https://applitools.com/solutions/mobile-testing/) | vendor | 2026 | Eyes 10.22 | Figma plugin → visual baselines; MCP for agentic coding; Compose via Espresso/Appium |
| 9 | [Android — Compose Preview Screenshot Testing](https://developer.android.com/studio/preview/compose-screenshot-testing) | official | 2026 | Studio Otter | `@PreviewTest` reference images; CI validate; host-side screenshot tests |
| 10 | [TSH Copilot Collections — ui-verification](https://copilot-collections.tsh.io/docs/skills/ui-verification) | community | 2026 | — | Strict PASS gate: figma-expected + actual + computed-styles.json; 1–2px tolerance |
| 11 | [buildmvpfast — Figma pixel-perfect loop](https://www.buildmvpfast.com/blog/figma-to-code-pixel-perfect-loop-ai-agent-screenshot-iterate-2026) | community | 2026 | — | Measurement > screenshot eyeballing; Playwright getComputedStyle deltas to agent |
| 12 | [Claude orchestrator figma visual qa workflow](https://github.com/ailabph/claude-ai-workflows/blob/main/workflows/CLAUDE_orchestrator_figma_visual_qa.md) | community | 2025 | — | Two-agent implement + visual QA; milestone screenshots vs Figma node IDs |
| 13 | [Figma Code Connect — CI/CD + issue #291](https://developers.figma.com/docs/code-connect/ci-cd/) | official | 2026 | — | CI validates syntax only; no native design→impl drift detection |
| 14 | [FlorianBruniaux — design-to-code Visual Iteration Loop](https://github.com/FlorianBruniaux/claude-code-ultimate-guide/blob/main/guide/workflows/design-to-code.md) | community | 2026 | — | Figma MCP + Playwright MCP; automated visual regression against Figma frames |
| 15 | [Automattic Studio — design-qa SKILL](https://github.com/automattic/studio/blob/trunk/packages/data-liberation-agent/skills/design-qa/SKILL.md) | maintained OSS | 2026 | — | Measured SectionParity records as hard gate; escalation ladder R1–R4 |

## Findings

| # | Source | Context | Pattern/Fix | Tradeoffs | Applicability | Recommendation | Confidence |
|---|--------|---------|-------------|-----------|---------------|----------------|------------|
| 1 | 3,4,5,15 | Post-implementation review approves UI without objective evidence | **Artifact-mandatory fidelity gate:** block approval (or reviewer PASS) unless brief includes paired artifacts — `figma-baseline.png` (from design-spec Screenshot Reference or fresh `get_screenshot`), `implementation.png` (emulator/device/Compose preview capture), viewport/state metadata, and a structured diff or parity record | Requires capture tooling in CI or specialist agent; Android emulator/screenshot infra | Directly closes MAS gap: replace imagined Visual QA with evidence when `design-specs/{TASK_ID}.md` exists; reviewer consumes artifacts, does not re-fetch Figma | **adopt** | HIGH |
| 2 | 10,11,1 | LLM "imagined" or screenshot eyeballing misses spacing/token drift | **Measurement-first verification:** compare design-spec Design Tokens + Layout Spec numeric fields against rendered output — web: `getComputedStyle`/`getBoundingClientRect`; Android: layout inspector metrics or Paparazzi/Compose screenshot test with region probes; emit structured delta JSON (property, expected, actual, severity) for dev fix loop | Platform-specific capture scripts; subpixel/font rendering variance needs 1–2px tolerance on dimensions only | MAS design-spec already has token table + node map — post-dev specialist diffs against these without re-calling `get_design_context` | **adopt** | HIGH |
| 3 | 1,2,6,7,14 | Pre-dev screenshot goes stale; implementation drift undetected | **Re-baseline at review milestone:** at post-dev fidelity check, re-invoke Figma MCP `get_screenshot` on design-spec `node-id` (same node as extraction) for fresh expected frame; pair with implementation capture at matching viewport (design-spec Node Map width/height) | `get_screenshot` is expensive per Figma guidance — reserve for review gate, not every edit; remote/local MCP transport constraints | Fits mas-figma mutual exclusion: fidelity specialist (or test-executor extension) may read Figma for screenshot only — dev still does not call MCP during implementation | **adapt** | HIGH |
| 4 | 6,7,8,14 | Standard visual regression (Percy/Chromatic) catches impl-vs-impl regressions, not design fidelity | **Design-as-baseline comparison:** use Figma frame (via API/MCP/screenshot export) as the expected image, not a prior implementation snapshot; tools: figma-audit pattern, Applitools Figma plugin, SmartUI CLI, or custom Playwright+Figma API pipeline | Commercial tools (Applitools) add cost; OSS figma-audit is web/deployed-URL oriented; Android needs Compose capture path | For MAS Android stack: adapt the *pattern* (Figma frame = baseline) using Compose Preview Screenshot Testing or Paparazzi with Figma-exported reference PNG from design-spec Asset/Screenshot Reference | **adapt** | MEDIUM |
| 5 | 9 | Android has no built-in Figma compare | **Compose Preview Screenshot Testing / Paparazzi:** `@PreviewTest` generates reference images from composable previews; import Figma-exported baseline into `screenshotTest` reference dir; `validateScreenshotTest` in CI; supports `fontScale`/`uiMode` multi-preview | JVM host tests don't catch platform font rendering edge cases; device tests slower; baseline maintenance on design changes | test-executor or new mas-visual-qa specialist runs targeted screenshot tests when design-spec exists; P0 gate in test-strategy brief | **adapt** | MEDIUM |
| 6 | 3,4,12 | Single reviewer agent mixes build/lint/imagination/design QA | **Split objective visual-qa from reviewer judgment:** dedicated post-dev slot (design-qa / visual-qa specialist) produces fidelity brief at `.ai/context/visual-qa/{TASK_ID}.md` or extends `test-runs/` with visual section; reviewer step 0k consumes it like a11y/osint | +1 chain agent; MAX_CHAIN_AGENTS pressure — protect-when-triggered like mas-figma or gate via `VISUAL_FIDELITY: yes` predicate | Mirrors MAS-04 specialist pattern and Lane C ordering: objective evidence → reviewer gate | **adapt** | HIGH |
| 7 | 8 | Agentic pipelines need toolable diff summaries | **Visual AI MCP tools for agent consumption:** Applitools Eyes MCP exposes layout/pixel diff summaries agents query by comparisonId; SmartUI MCP offers `summarizeLayoutDiff`, `analyzeHumanDiff` — reduces raw image token load | Vendor lock-in; API keys; may not support Compose native without Appium bridge | Optional enterprise path; for MAS v1 adapt the *brief shape* (structured diff table) without requiring Applitools | **adapt** | MEDIUM |
| 8 | 13 | Code Connect prevents component reuse drift at mapping layer only | **Code Connect CI validates snippet syntax, not visual fidelity:** `figma connect publish --dry-run` catches parser errors; Figma prop changes can silently break Dev Mode without impl drift detection — separate concern from screen-level fidelity | Does not replace post-dev visual gate | Keep mas-figma reuse table + Code Connect as pre-dev input; do not treat Code Connect as post-dev fidelity substitute | **avoid** as fidelity gate | HIGH |

## Recommended Approach

Close the MAS fidelity gap with a **post-dev, evidence-based visual fidelity layer** that consumes the existing `design-spec` brief — without weakening the pre-dev `mas-figma` extraction contract.

### Problem statement (current MAS gap)

| Phase | Today | Gap |
|-------|-------|-----|
| Pre-dev | `mas-figma` → design-spec with Screenshot Reference, tokens, node map | Strong |
| Dev | android-dev reads spec; told to validate 1:1 vs screenshot | Self-attested; no artifact |
| Review | Imagined Visual QA from Compose tree | **No Figma compare; no screenshots; no measured deltas** |

This is the exact anti-pattern industry sources flag: approval without verifiable visual evidence (Finding #1, #5).

### Proposed architecture (adapt, not wholesale tool adoption)

```
architect → mas-figma → android-dev → [NEW: visual-fidelity pass] → ux/a11y → documenter → reviewer
                                              │
                                              ├─ Read design-specs/{TASK_ID}.md (node-id, tokens, dimensions)
                                              ├─ Capture implementation (Compose preview / emulator screenshot)
                                              ├─ Re-fetch Figma baseline via get_screenshot (same node-id) OR use design-spec Screenshot Reference if fresh
                                              ├─ Run measurement diff (tokens/layout numbers) → structured delta table
                                              ├─ Optional: pixel diff / Paparazzi validate vs Figma-exported baseline
                                              └─ Write .ai/context/visual-qa/{TASK_ID}.md (or visual section in test-runs/)
reviewer → Design-Fidelity Verification (step 0k): artifacts present + P0 deltas resolved or accepted
```

**Three-tier verification (cheapest first):**

1. **Token/layout measurement diff (P0)** — diff design-spec Design Tokens + Node Map dimensions against captured metrics; no LLM spatial reasoning; feeds dev with exact fixes ("padding 24dp vs spec 16dp").
2. **Screenshot pair compare (P1)** — Figma baseline PNG vs implementation PNG at design-spec viewport; pixel diff or visual AI summary; flag layout/color drift.
3. **Subjective polish (P2)** — reviewer imagined walkthrough only for gaps measurement cannot catch (motion, interaction states) — **not** a substitute for tiers 1–2 when design-spec exists.

### Specialist options (brainstorm input)

| Option | Description | Chain cost |
|--------|-------------|------------|
| **A — Extend `mas-test-executor`** | Add visual-fidelity commands to test-run brief when `design-spec` exists | Low — reuses P0 slot |
| **B — New `mas-visual-qa` specialist** | Read-only fidelity auditor; mirrors mas-figma post-dev symmetry | +1 agent; protect-when-triggered |
| **C — Dev-owned artifacts** | android-dev must attach screenshot paths + delta self-check before DONE | Zero agents; weakest enforcement |

**Recommended:** Option **B** (or A as v1 minimal) with predicate `VISUAL_FIDELITY: yes` when `design-specs/{TASK_ID}.md` exists and UI changed — same protection policy as `mas-figma` (user escalation on cap breach, not silent skip).

### Reviewer contract change

When `design-specs/{TASK_ID}.md` exists:

- Imagined Visual QA rows for **layout, typography, color, spacing** → downgrade to **N/A** unless `visual-qa/{TASK_ID}.md` artifacts exist.
- New **Design-Fidelity Verification** step: schema check on visual-qa brief; P0 measurement deltas = Major minimum; unresolved P0 = `Approved: NO`.
- Reviewer does **not** re-call Figma MCP — consumes fidelity brief like osint/a11y.

### Android-specific guidance

- Use **Compose Preview Screenshot Testing** (`@PreviewTest`, `validateDebugScreenshotTest`) for component/screen previews at design-spec dimensions + `fontScale` variants.
- Store Figma baseline PNG from design-spec Screenshot Reference in `screenshotTest/reference/` (dev download-and-commit per existing asset contract).
- Paparazzi as alternative for faster JVM tests without full preview tooling.
- Device-level capture (adb screencap / Macrobenchmark) reserved for integration-critical screens only — costlier, run in test-executor P1.

### What NOT to do

- Do not rely on LLM imagined rendering when a design-spec exists (current build-test-visual-qa.md gap).
- Do not use whole-frame `get_design_context` at fidelity stage — screenshot + token table suffice.
- Do not treat Percy/Chromatic alone as design fidelity (impl-vs-impl only).
- Do not paste Applitools/SmartUI code — adapt artifact + brief schema patterns only.

## Recommended Fix Strategy

N/A — FEATURE mode.

## Priority Order

1. **Finding #1 — Artifact-mandatory fidelity gate** — highest leverage; transforms Reviewer Visual QA from rubber-stamp imagination to verifiable gate when design-spec exists.
2. **Finding #2 — Measurement-first token/layout diff** — cheapest, most deterministic; leverages existing design-spec tables without new Figma MCP calls.
3. **Finding #6 — Dedicated post-dev visual-fidelity specialist slot** — clean MAS role boundary; mirrors mas-figma pre/post symmetry and Lane C evidence-before-judgment ordering.
4. **Finding #3 — Re-baseline via get_screenshot at review** — ensures expected frame matches current Figma file, not stale pre-dev capture.
5. **Finding #5 — Compose Preview Screenshot Testing with Figma-imported baselines** — Android-native CI gate for regression after initial fidelity pass.

## Anti-Patterns Avoided

- **Imagined-only Visual QA for Figma-driven UI** — industry and MAS-05 architecture explicitly intend 1:1 validation, but build-test-visual-qa.md still mandates imagination; this is the root gap.
- **LLM screenshot spatial comparison as primary gate** — buildmvpfast and TSH ui-verification show structured measurement outperforms eyeballing.
- **Impl-vs-impl visual regression as design fidelity** — figma-audit explicitly distinguishes these; Percy/Chromatic default baselines are wrong tool for design parity.
- **Code Connect CI as fidelity substitute** — validates mapping syntax only (Figma issue #291).
- **Re-extracting full design context at review** — token blow-up; screenshot + spec diff sufficient.

## Implementation Guidance

For **brainstorm / architect / planner** (no code in this brief):

1. **New brief type `visual-qa`** (or extend `test-run` with required Visual Fidelity section) at `.ai/context/visual-qa/{TASK_ID}.md`:
   - Viewport/state metadata (from design-spec Node Map width/height)
   - Baseline source (`design-spec Screenshot Reference` path OR fresh `get_screenshot` node-id + timestamp)
   - Implementation capture path(s)
   - Measurement diff table: `property | expected (design-spec) | actual | delta | severity`
   - Screenshot diff summary (PASS/FAIL/PARTIAL + regions)
   - Open Questions / accepted debt (Class-C constraints only with evidence)

2. **Coordinator predicate** (suggested): `VISUAL_FIDELITY: auto` when `design-specs/{TASK_ID}.md` exists AND dev handoff indicates UI changes — spawn visual-qa specialist after dev, before ux-intelligence.

3. **Update `build-test-visual-qa.md`:** when design-spec exists, Visual QA section becomes **artifact-backed** not imagined-only; document fallback to imagined QA only when no design-spec (non-Figma UI).

4. **Update `mas-reviewer`:** add step 0k Design-Fidelity Verification (parallel to 0j design-spec schema check).

5. **Mutual exclusion:** visual-fidelity specialist is read-only (like mas-figma); routes deltas to dev/bug-fix; no `Approved:` authority.

6. **Lite mode:** skip visual-fidelity spawn; warn user that Figma fidelity is unverified.

7. **Iteration loop:** P0 measurement failures → dev fix → re-capture → visual-qa re-run (max 2 iterations before user escalation, per MAS cap discipline).

## License / Copy Guardrails

- Applitools, SmartUI, Percy, Chromatic — commercial; describe integration patterns only; no SDK paste.
- figma-audit, visual-first-design, oh-my-openagent — MIT/OSS; adapt workflow shapes, not code.
- Figma MCP docs — official; cite tool names and workflow order only.

## Regression Notes

N/A — FEATURE mode. Related: MAS-05 shipped mas-figma + design-spec; MAS-06 addresses the downstream verification hole MAS-05 architecture deferred ("Downstream Android responsive/visual QA is deferred to the future UI implementation workflow").

## Local Files Referenced

- `skills/mas-figma/SKILL.md`
- `skills/multi-agent-system/references/figma-extraction-standards.md`
- `skills/multi-agent-system/references/build-test-visual-qa.md`
- `skills/mas-reviewer/SKILL.md`
- `.ai/context/architecture/MAS-05.md`
- `.ai/context/osint/MAS-05.md`

## Open Questions

- **D1:** New specialist `mas-visual-qa` vs extend `mas-test-executor` — chain cap and skill surface area tradeoff; brainstorm should decide.
- **D2:** Emulator screenshot infra in CI — is target Android project already configured for connected tests / screenshot tests?
- **D3:** Staleness policy for design-spec Screenshot Reference — always re-fetch `get_screenshot` at fidelity gate vs trust committed PNG if `<N` days old?
- **D4:** Pixel diff tolerance for Compose font rendering — adopt TSH 1–2px on dimensions only, zero tolerance on colors/tokens?
- **D5:** Interaction/hover states — design-spec often static; fidelity gate scope = default state only for v1?

## Overall Confidence

**HIGH** — Multiple independent sources (Figma official, OpenAI/Automattic agent skills, figma-audit, Applitools, Android official screenshot testing, agentic workflow guides) converge on artifact-mandatory post-implementation visual verification against design baselines. Android-specific Compose screenshot testing is official but Figma-direct integration remains adapt-pattern (no first-party Google Figma fidelity CI). Measurement-first delta reporting confidence is HIGH from multiple 2026 agent-workflow sources.
