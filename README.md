# MAS Cursor Framework

**Version:** 1.9.0 (MAS-11 Full Product Engineering Team & GenAI Expansion)

Portable distribution of the **Multi-Agent System (MAS)** for [Cursor](https://cursor.com). MAS orchestrates specialized AI agents through slash commands — `/mas` for the full pipeline and `/mas-lite` for token-efficient workflows.

This repo contains everything needed to install MAS on another machine: skills, commands, rules, hooks, and install scripts. It does **not** include per-project `.ai/context/` — that is created separately in each workspace via `init-mas-context.ps1`.

## Repository structure

| Path | Contents |
|------|----------|
| `skills/` | MAS skill trees (`multi-agent-system`, coordinator, product engineering team [`mas-pm`, `mas-genai`, `mas-backend-dev`, `mas-devops`], specialists, P0 audit quartet, P1 depth trio, `mas-debate`, `mas-token-auditor`, `mas-lite`) |
| `commands/` | `mas.md`, `mas-lite.md` slash command definitions |
| `rules/` | `multi-agent-hybrid.mdc` workspace rule |
| `hooks/` | Session context hooks (`mas-session-context.ps1`, `.sh`) |
| `install/` | **Pointer only** — see canonical install below |
| `hooks.mas.template.json` | Hook template merged into `~/.cursor/hooks.json` on install |
| `USER-RULE-MAS.md` | Optional global user rule reference |

**Canonical install (edit here only):** `skills/multi-agent-system/install/` — manifest, export/install scripts, `Test-InstallParity` hash guard. Root `install/README.md` redirects to this path. Export copies canonical install into release bundles.

## MAS-01 protocol additions

| File | Purpose |
|------|---------|
| `protocol/spawn-model-policy.md` | Agent slug → `MODEL_CLASS` → Task `model` |
| `protocol/brief-schemas.md` | Required brief sections per artifact type |
| `protocol/token-rules.md` | Chain caps, artifact-forward rule |
| `protocol/read-order.md` | Brief subscription matrix |
| `skills/mas-debate/` | Debate synthesizer on 2nd Reviewer rejection |
| `skills/mas-token-auditor/` | Post-finalize advisory token audit |

Context dirs: `.ai/context/debates/`, `.ai/context/audits/`.

## MAS-04 Phase A — P0 audit specialists (v1.2.0)

Four **advisory-only** specialists audit and brief; they never patch production code or replace reviewer approval.

| Specialist | Skill | Brief path | Model class |
|------------|-------|------------|-------------|
| Security Auditor | `mas-security-auditor` | `.ai/context/security-audits/{TASK_ID}.md` | thinking |
| Dependency Risk | `mas-dependency-risk` | `.ai/context/supply-chain/{TASK_ID}.md` | fast |
| API Contract | `mas-api-contract` | `.ai/context/api-contracts/{TASK_ID}.md` | normal |
| Test Executor | `mas-test-executor` | `.ai/context/test-runs/{TASK_ID}.md` | normal |

### Routing flags (Coordinator handoffs)

| Full `/mas` flag | Lite abbreviation | When Coordinator spawns |
|------------------|-------------------|-------------------------|
| `SECURITY_AUDIT: yes` | `SEC:y` | Auth/crypto/API in `SCOPE`; post-dev pre-reviewer |
| `API_CONTRACT: yes` | `API:y` | OpenAPI/GraphQL/Proto in `FILES`; REST/BFF in `SCOPE` |
| `SUPPLY_CHAIN: yes` | `DEPS:y` | Lockfile/manifest/MCP/skills/hooks delta in `FILES` |
| `RUN_TESTS: yes` | `TEST:y` | Test-strategy brief exists or explicit test run |

Predicates also fire from `FILES`/`SCOPE` without flags. Omit flags when not applicable — existing handoffs remain valid. See [handoff-format.md](skills/multi-agent-system/protocol/handoff-format.md) and [mas-coordinator/SKILL.md](skills/mas-coordinator/SKILL.md) for chain order and overflow skip policy.

**Boundaries:** test-strategy **plans** (pre-dev); test-executor **runs** (post-dev). Reviewer remains sole `Approved:` gate.

## MAS-04 Phase B — P1 depth trio (v1.2.1)

Three **advisory-only** specialists extend UI and regulatory depth audits; they never patch production code or replace reviewer approval.

| Specialist | Skill | Brief path | Model class |
|------------|-------|------------|-------------|
| A11y | `mas-a11y` | `.ai/context/a11y-reviews/{TASK_ID}.md` | normal |
| I18n | `mas-i18n` | `.ai/context/i18n-reviews/{TASK_ID}.md` | normal |
| Compliance | `mas-compliance` | `.ai/context/compliance/{TASK_ID}.md` | thinking |

### Routing flags (Coordinator handoffs)

| Full `/mas` flag | Lite abbreviation | When Coordinator spawns |
|------------------|-------------------|-------------------------|
| `A11Y_AUDIT: yes` | `A11Y:y` | Interactive widgets in `FILES`; release-readiness Accessibility FAIL; post-ux when `UI_CHANGES: yes` |
| `I18N_AUDIT: yes` | `I18N:y` | New strings/locale/RTL in `SCOPE`; release-readiness Localization FAIL; after a11y when both triggered |
| `COMPLIANCE_FRAMEWORK: SOC2 \| GDPR \| HIPAA \| EU_AI_ACT \| FedRAMP` | *(none — full `/mas` only)* | Only when framework enum set; post-i18n segment or post-dev when UI chain skipped |

Predicates also fire from `FILES`/`SCOPE`/release-readiness FAIL without flags. **Compliance** is enterprise opt-in — never spawned in `/mas-lite`. Compliance briefs include a **Not legal advice** disclaimer; HITL required for legal/prod remediation.

### Phase B UI chain order

```
dev → [ux-intelligence?] → [a11y?] → [i18n?] → [compliance?] → [test-executor?] → documenter → reviewer
```

1. `ux-intelligence` before `a11y` when both `UI_CHANGES: yes` and a11y triggered.
2. `a11y` before `i18n` when both triggered — sequential only.
3. `compliance` after i18n segment when both triggered; may spawn without UI chain when only `COMPLIANCE_FRAMEWORK` set.
4. `compliance` never spawns without `COMPLIANCE_FRAMEWORK` set.

**Mutual exclusion:** a11y owns WCAG depth (ux-intelligence owns behavioral friction); i18n owns locale/string architecture (not translation vendor workflow); compliance owns regulatory evidence (security-auditor owns exploitability). Overflow skip order: a11y → i18n → compliance. See [mas-coordinator/SKILL.md](skills/mas-coordinator/SKILL.md) and [handoff-format.md](skills/multi-agent-system/protocol/handoff-format.md).

## MAS-11 — Full Product Engineering Team & GenAI Expansion (v1.9.0)

Upgrades MAS into a complete, autonomous **Full Product Engineering Organization** spanning product discovery, system architecture, generative AI engineering, full-stack implementation, platform DevOps, and centralized quality governance.

### Product Engineering Team Roster

| Specialist | Skill | Focus Area | Brief Artifact |
|------------|-------|------------|----------------|
| **Product Manager** | `mas-pm` | Problem discovery, customer journey maps, Gherkin user stories, NFR budgets, MVP vs deferred scope | `.ai/context/prds/{TASK_ID}.md` |
| **GenAI Specialist** | `mas-genai` | Dual-mode: AI architecture/prompt design (Design) & model pipelines/evals (Dev) | `.ai/context/genai/{TASK_ID}.md` |
| **Backend Dev** | `mas-backend-dev` | Clean architecture, forward-only DB migrations, parameterized queries, idempotency, auth | Application code & migrations |
| **DevOps / Platform** | `mas-devops` | Multi-stage Docker, GitHub Actions (pinned SHAs), Terraform IaC, `.env.example`, health probes | `.ai/context/devops/{TASK_ID}.md` |

### GenAI Specialist Capabilities

`mas-genai` introduces enterprise-grade generative AI engineering across client edge and cloud infrastructure:

- **Dual-Tier Model Routing**:
  - **Tier 1 (On-Device SLM)**: Google MediaPipe Tasks GenAI (`tasks-genai:0.10.20+`) executing quantized models (Gemma 2B / 3B INT4). Enforces pre-flight RAM guard (`ActivityManager.MemoryInfo.totalMem >= 6GB`), background `Dispatchers.IO` execution, and non-blocking `Flow<String>` token streaming.
  - **Tier 2 (Cloud Gateway)**: LiteLLM proxy with automated fallback cascades (primary $\rightarrow$ secondary provider), exponential backoff, and Langfuse/OTLP observability for token spend and latency tracing.
- **Prompt Architecture & Engineering**:
  - Strict XML tag hierarchy (`<context>`, `<system_instructions>`, `<constraints>`, `<tools>`, `<output_schema>`) preventing delimiter collisions.
  - High-leverage few-shot exemplars covering edge cases and counter-examples.
  - Static prompt prefix caching optimization ($\ge 1024$ tokens for Anthropic KV-cache, $\ge 32\text{k}$ for Gemini context caching).
- **Structured Output & Tool Calling**:
  - Strict JSON Schema draft-07 definitions with `additionalProperties: false` and required attribute arrays for zero hallucination during function calling.
- **Hybrid RAG & Retrieval**:
  - Semantic chunking with overlap boundaries, hybrid retrieval combining dense vector search with sparse BM25 keyword matching, cross-encoder reranking, and metadata filtering.
- **Safety Guardrails & OWASP Defenses**:
  - Dual runtime guardrails: input XML escaping and prompt injection classifiers; output JSON validation and PII redaction.
  - Mitigations for OWASP Top 10 for LLMs (prompt injection, insecure output handling, training data poisoning, model denial of service).
- **Automated Evaluation Harnesses**:
  - DeepEval RAG Triad test suites: Faithfulness $\ge 0.85$, Answer Relevancy $\ge 0.85$, Context Recall $\ge 0.80$, Hallucination Score $\le 0.10$.
  - `promptfoo` red-teaming matrix and deterministic schema validation assertions.

### 6-Tier Product Engineering SDLC Assembly Line

The multi-agent workflow operates across six deterministic tiers:
1. **Tier 1: Requirements & Discovery** — `mas-pm` (PRD authoring), `mas-spec-reader` (external doc ingestion), `mas-osint` (prior art research).
2. **Tier 2: Planning & Architecture** — `mas-brainstorm` (technical tradeoffs), `mas-planner` (task breakdown), `mas-architect` (system topology), `mas-genai` (Design Mode: AI specification), `mas-figma` (design spec extraction).
3. **Tier 3: Test Strategy & Implementation** — `mas-test-strategy` (test matrix planning), `mas-backend-dev` (APIs/DB), `mas-genai` (Dev Mode: client/gateway/evals), `mas-android-dev` (Compose/mobile), `mas-general-dev` (web/scripts).
4. **Tier 4: Platform & DevOps** — `mas-devops` (containerization, CI/CD, IaC, health probes).
5. **Tier 5: Quality & Audits** — `mas-visual-fidelity` (post-dev UI parity), P0 audit quartet (`mas-security-auditor`, `mas-dependency-risk`, `mas-api-contract`, `mas-test-executor`), P1 depth trio (`mas-a11y`, `mas-i18n`, `mas-compliance`).
6. **Tier 6: Governance & Delivery** — `mas-documenter` (codebase docs & changelog), `mas-reviewer` (centralized merge gate with steps 0–0o), `mas-commit` (structured git commit).

### Coordinator Routing Flags & Lite Abbreviations

| Full `/mas` Flag | Lite Flag (`/mas-lite`) | Target Specialist | Trigger Conditions |
|------------------|-------------------------|-------------------|-------------------|
| `PRD_AUTH: yes` | `PM:y` | `mas-pm` | Ambiguous greenfield concept or explicit flag |
| `GENAI_SPEC: yes` | `GEN:y` | `mas-genai` (Design) | `GENAI_SPEC: yes`, `SCOPE: genai`, or AI keywords |
| `TARGET_AGENT: mas-genai` | `GEN:y` | `mas-genai` (Dev) | Dev handoff for AI engine/eval implementation |
| `BACKEND: yes` | `BE:y` | `mas-backend-dev` | `BACKEND: yes`, server files touched, or backend scope |
| `DEVOPS: yes` | `OPS:y` | `mas-devops` | `DEVOPS: yes`, infra files touched, or devops scope |

## Quick install

### Windows (double-click)

1. Clone or unzip this repo.
2. Run `skills\multi-agent-system\install\install.bat`.
3. Reload Cursor (**Ctrl+Shift+P** → **Developer: Reload Window**).

### Windows (PowerShell)

```powershell
cd path\to\mas-cursor-framework\skills\multi-agent-system\install
.\install-mas-framework.ps1
```

### macOS / Linux

```bash
cd path/to/mas-cursor-framework/skills/multi-agent-system/install
chmod +x install-mas-framework.sh
./install-mas-framework.sh
```

For detailed transfer steps, Mac notes, and project bootstrap, see [skills/multi-agent-system/install/README.md](skills/multi-agent-system/install/README.md).

## Export from source

To refresh this bundle from a live `~/.cursor` install:

```powershell
cd $env:USERPROFILE\.cursor\skills\multi-agent-system\install
.\export-mas-framework.ps1
```

| Flags | Result |
|-------|--------|
| *(none)* | Zip to Desktop |
| `-OutputPath "D:\backups\mas.zip"` | Zip only |
| `-OutputDir "C:\dev\mas-cursor-framework"` | Folder only |
| Both `-OutputDir` and `-OutputPath` | Folder and zip |

Example — sync into a workspace clone:

```powershell
.\export-mas-framework.ps1 -SourceCursorHome "$env:USERPROFILE\.cursor" -OutputDir "C:\path\to\mas-cursor-framework"
```

`Test-InstallParity` fails if root `install/` duplicate scripts drift from canonical.

## Verify installation

1. Open Cursor Agent chat and type `/` — confirm **mas** and **mas-lite** appear.
2. In a project with `.ai/context/`, session hints should mention `/mas` and `/mas-lite`.
3. Run `/mas-lite S` on a small task or `/mas` for the full coordinator pipeline.

## ADB device testing (MAS-07 v1.5.0)

Android connected tests and tier-3 screencap require **adb** (Android Platform Tools) on PATH and a one-time USB debugging enrollment (RSA "Always allow").

**Prep gate** (test-executor Step 0):

```powershell
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 `
  -Policy physical -JsonOnly
```

On PASS, `ANDROID_SERIAL` is exported for Gradle `connected*AndroidTest` and `capture-connected-device`. Fixture dogfood (no physical device):

```powershell
$env:ADB_DEVICES_FIXTURE = ".ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt"
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 -Policy auto -JsonOnly
```

See [device-prep-automation.md](skills/multi-agent-system/references/device-prep-automation.md) and [scripts/README.md](skills/multi-agent-system/scripts/README.md).

## Log capture (MAS-09 v1.7.0)

Bug-repro workflows clear log buffers before repro and dump filtered logcat after repro to `.ai/context/device-logs/{TASK_ID}/`.

**Capture gate** (test-executor Step 0b + Post, after prep PASS):

```powershell
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  clear-and-marker -TaskId MAS-09 -Tag APP_TRACE

powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  dump -TaskId MAS-09 -Package com.example.app -Tag APP_TRACE -JsonOnly
```

Fixture dogfood (no physical device):

```powershell
$env:ADB_DEVICES_FIXTURE = ".ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt"
$env:ADB_LOGCAT_FIXTURE = ".ai/fixtures/MAS-09-LOG-CAPTURE/adb-logcat-sample.txt"
$env:ANDROID_SERIAL = "R58M90ABCDE"
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 dump -TaskId MAS-09 -Tag APP_TRACE -JsonOnly
```

Coordinator handoff flags: `LOG_CAPTURE: yes`, `LOG_PACKAGE`, `LOG_TAG` (default `APP_TRACE`). See [device-log-capture.md](skills/multi-agent-system/references/device-log-capture.md).

## Bootstrap a project

After global install, initialize per-project MAS context:

```powershell
~/.cursor/skills/multi-agent-system/scripts/init-mas-context.ps1 -ProjectPath "C:\path\to\your\project" -Stack auto
```

## Publish to GitHub

```bash
cd mas-cursor-framework
git init
git add .
git commit -m "feat: package MAS Cursor framework v1.2.1"
git remote add origin https://github.com/<you>/mas-cursor-framework.git
git branch -M main
git push -u origin main
```

## License

License TBD — add your chosen license before public release.
