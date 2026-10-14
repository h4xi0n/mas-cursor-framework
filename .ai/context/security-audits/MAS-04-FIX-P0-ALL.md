# Security Audit Brief — MAS-04-FIX-P0-ALL

**TASK_ID:** MAS-04-FIX-P0-ALL  
**MODE:** FULL (dogfood P0 spawn validation)  
**SCOPE:** auth, API, mas-framework  
**Audited:** 2026-07-28  
**SECURITY_BLOCKER:** no (advisory v1 — reviewer remains sole `Approved:` gate)  
**Confidence:** HIGH (static review of in-scope FILES); MEDIUM (runtime shell behavior — not executed this pass)

## Threat model

### Actors

| Actor | Capability | Motivation |
|-------|------------|------------|
| **Coordinator** | Writes handoffs, spawns specialists via Task | Trusted orchestrator |
| **test-strategy agent** | Authors `Recommended Commands` in `.ai/context/test-strategies/{TASK_ID}.md` | Plans bounded verification |
| **test-executor agent** | Invokes Shell tool per strategy brief | Run-only evidence capture |
| **security-auditor agent** | Read-only STRIDE/OWASP analysis; writes advisory brief | No shell mandate |
| **Malicious / compromised brief author** | Edits `.ai/context/test-strategies/` or handoff `CONTEXT` | Command injection, data exfil, destructive ops |
| **Prompt-injection attacker** | Embeds instructions in markdown briefs, fixtures, or skill text | Hijack agent behavior (OWASP LLM) |
| **External API client** | Calls deployed API derived from fixture | N/A today — fixture is spec-only dogfood |

### Assets

| Asset | Sensitivity | Location |
|-------|-------------|----------|
| Host filesystem (workspace + user profile) | HIGH | Shell cwd = repo root |
| `.ai/handoffs/`, `.ai/context/**` | MEDIUM | Chain routing + command source |
| `skills/**` (install bundle) | HIGH | Prompt/rule injection surface |
| Dogfood OpenAPI stub | LOW | `.ai/fixtures/MAS-04-FIX-P0-ALL/openapi.yaml` |
| Credentials / `.env` (out of scope but reachable via shell) | HIGH | Not in FILES — reachable if executor deviates |

### Trust boundaries

```
User / Coordinator
    │ handoff flags (SECURITY_AUDIT, RUN_TESTS, FILES, SCOPE)
    ▼
test-strategy ──writes──► test-strategies/{TASK_ID}.md (Recommended Commands)
    │                              │
    │ pre-dev, no shell            │ trust: executor treats commands as authoritative
    ▼                              ▼
dev (fixture only)            test-executor ──Shell tool──► host OS
    │
    ▼
security-auditor ──read-only──► security-audits/{TASK_ID}.md (this brief)
```

**Boundary 1 — Strategy → Executor:** No cryptographic or schema validation of commands at skill layer; enforcement is procedural (reviewer, strategy author discipline, dogfood safety notes).

**Boundary 2 — Fixture → Runtime API:** OpenAPI stub is synthetic; no handlers in `FILES`. Auth/crypto in `SCOPE` applies to framework workflow, not to the stub's `/health` surface.

**Boundary 3 — Advisory specialists:** `mas-security-auditor` forbids patches and spawn; `disable-model-invocation: true` on all P0 quartet skills limits direct user invocation.

### Data flows

1. Handoff `SECURITY_AUDIT: yes` + `SCOPE: auth, API` → security-auditor reads fixture + skills → advisory brief.
2. Handoff `RUN_TESTS: yes` + test-strategy brief → test-executor runs PowerShell/`rg` → writes `test-runs/{TASK_ID}.md`.
3. Fixture `openapi.yaml` → api-contract inventory only; no network egress from fixture itself.

---

## Findings

| # | Category | Finding | Exploit path | Severity | Validation | Recommendation |
|---|----------|---------|--------------|----------|------------|----------------|
| 1 | **E / OWASP LLM06** | `mas-test-executor` delegates shell execution to strategy brief without skill-level command allowlist/denylist | Compromised or careless test-strategy brief embeds `Remove-Item -Recurse`, `curl` exfil, or `git` credential access; executor skill line 49 mandates "Execute commands via shell" with no parser gate | **P1** | validated | Add skill-level guardrails: explicit denylist (`git`, `curl`, `npm`, network, recursive wildcards), require commands originate only from `Recommended Commands` fenced blocks, max one file/path target per command; reviewer checklist item |
| 2 | **T / OWASP LLM01** | Test-strategy brief is a prompt-injection channel into test-executor | Attacker or drifted agent inserts prose "ignore safety constraints" adjacent to PowerShell blocks; subagent-role.md line 21 encourages running commands without content inspection | **P1** | validated | Keep dogfood **Safety constraints** section (test-strategy §93–100); extend protocol: strategy brief must use fenced `powershell` blocks only; executor skill: refuse commands outside fenced blocks; log command hash in test-run brief |
| 3 | **I / OWASP API2** | Dogfood `GET /health` is unauthenticated with no `securitySchemes` | If stub is copied to production BFF without hardening, health endpoint leaks liveness and becomes reconnaissance pivot | **P2** | validated | Accept for P0 predicate; document in fixture README that auth must be added before any deployment; api-contract brief rec #2–4 |
| 4 | **I / OWASP API3** | Health `200` response has no `content` schema | Consumers cannot validate response shape; enables ambiguous parsing bugs if extended ad hoc | **P3** | validated | Add minimal JSON schema when fixture graduates from dogfood (api-contract rec #2) |
| 5 | **T / STRIDE** | `.ai/context/test-strategies/` integrity unauthenticated | Any agent or user with workspace write can replace commands between strategy and executor spawns | **P2** | validated | Reviewer compares strategy brief hash/timestamp vs test-run `Source` column; optional session JSON records strategy mtime |
| 6 | **D / Availability** | `MAX_CHAIN_AGENTS` overflow drops **test-executor** before **security-auditor** | Long chains skip shell verification first (`token-rules.md` lines 18–22) while security audit may still run — uneven assurance | **P2** | validated | Document trade-off; for security-critical tasks user sets explicit cap or runs test-executor manually; consider swapping skip order when `RUN_TESTS: yes` + `SECURITY_AUDIT: yes` |
| 7 | **E / OWASP A03** | `RUN_TESTS: yes` path allows commands in handoff `CONTEXT` without strategy file | handoff-format.md: executor may run with flag only — weaker than strategy-brief path | **P2** | partial | Prefer strategy brief as sole command source; if CONTEXT override allowed, require Coordinator to paste commands in fenced block and reviewer sign-off |
| 8 | **R / OWASP LLM07** | security-auditor is advisory-only; no `Approved:` authority | Findings may be ignored unless reviewer enforces; `SECURITY_BLOCKER: yes` not set on this handoff | **P3** | validated | By design v1; user enables `SECURITY_BLOCKER: yes` for merge-blocking blockers on production tasks |
| 9 | **S / OWASP LLM03** | P0 skill bundle expands install trust surface | Four new `~/.cursor/skills/` trees; poisoned SKILL.md affects every `/mas` session | **P2** | validated | Supply-chain brief #4 — PR review for hidden instructions; pin install to tagged releases |
| 10 | **I** | Fixture declares `info.title: Dogfood API` with no `servers` | Misconfiguration if used as conformance target without base URL | **P3** | validated | Add `servers` when used beyond spawn predicate (api-contract rec #4) |
| 11 | **T** | Dogfood test-strategy §1 uses `ConvertFrom-Json` + `throw` on manifest | Bounded read-only; failure modes are safe (exit non-zero) | **P3** | validated | No change required for dogfood; pattern is acceptable |
| 12 | **E** | Executor may write only `test-runs` brief but shell can modify any path | Safety constraints are prose-only in strategy brief, not enforced in `mas-test-executor/SKILL.md` | **P1** | validated | Mirror dogfood constraints into executor skill **Rules** section as mandatory; fail closed on denylist match |

### STRIDE coverage summary

| STRIDE | Applicable finding(s) | Dogfood residual risk |
|--------|----------------------|------------------------|
| Spoofing | #3 (unauthenticated health) | LOW — spec-only |
| Tampering | #5 (brief integrity), #2 (injection) | MEDIUM — procedural controls only |
| Repudiation | #8 (advisory audit) | LOW — by design |
| Information disclosure | #3, #4, #1 (shell reads secrets) | MEDIUM — shell boundary |
| Denial of service | #6 (cap skip), #1 (destructive commands) | LOW for dogfood (bounded commands) |
| Elevation of privilege | #1, #7, #12 (unrestricted shell) | MEDIUM — mitigated in FIX-P0-ALL strategy, not in skill |

### OWASP Top 10 (2021) mapping (framework lens)

| OWASP | Relevance | Finding |
|-------|-----------|---------|
| A01 Broken Access Control | MEDIUM | #3, #7 — workflow flags vs executor command source |
| A03 Injection | HIGH | #1, #2, #12 — shell injection via strategy brief |
| A04 Insecure Design | MEDIUM | #6, #8 — cap skip order, advisory-only audit |
| A05 Security Misconfiguration | LOW | #3, #10 — minimal OpenAPI stub |
| A08 Software/Data Integrity | MEDIUM | #5, #9 — brief and skill integrity |
| A10 SSRF | N/A | No network commands in dogfood strategy |

### OWASP LLM Top 10 mapping

| LLM risk | Finding |
|----------|---------|
| LLM01 Prompt injection | #2 |
| LLM03 Training data poisoning → supply chain | #9 |
| LLM06 Sensitive information disclosure | #1 (shell reads) |
| LLM07 Insecure plugin design | #1, #12 (executor as shell plugin) |
| LLM08 Excessive agency | #1, #7 — executor runs arbitrary strategy commands |

---

## Validation

### Finding #1 / #12 — Shell execution without skill-level enforcement (P1)

**Evidence:**

- `skills/mas-test-executor/SKILL.md` workflow step 2: *"Execute commands via shell — bounded attempts; no unbounded flaky retry."* — no allowlist, denylist, or path scoping.
- `skills/mas-test-executor/SKILL.md` rules: *"Smallest command scope — strategy brief commands only unless handoff overrides"* — procedural, not machine-enforced.
- Contrast: `.ai/context/test-strategies/MAS-04-FIX-P0-ALL.md` lines 93–100 define explicit **Safety constraints** (read-only, no `git`/`npm`/`curl`/network, fixed paths) — present for this TASK_ID only.
- `skills/mas-test-strategy/SKILL.md` line 36: test-strategy never runs shell — mutual exclusion holds; risk is deferred to executor.

**Conclusion:** Exploit path is **validated** for generic tasks; **mitigated but not enforced** for `MAS-04-FIX-P0-ALL` dogfood.

### Finding #2 — Prompt injection via strategy brief (P1)

**Evidence:**

- `skills/multi-agent-system/protocol/subagent-spawn.md` line 91: subagents instructed to *"run builds/tests as your skill requires"* without content-safety step.
- Dogfood strategy includes mandatory safety preamble; skill files do not require parsing it.

**Conclusion:** **Validated** — reliance on reviewer + author discipline; dogfood brief reduces likelihood.

### Finding #3 — Unauthenticated fixture endpoint (P2)

**Evidence:**

```6:11:.ai/fixtures/MAS-04-FIX-P0-ALL/openapi.yaml
  /health:
    get:
      summary: Health check
      responses:
        '200':
          description: OK
```

- No `security`, `securitySchemes`, or `components` in fixture (confirmed api-contract brief).
- Handoff `SCOPE` includes `auth` — applies to framework workflow audit, not stub content.

**Conclusion:** **Validated** as spec gap; acceptable for P0 spawn predicate.

### Finding #5 — Brief integrity (P2)

**Evidence:**

- `.ai/context/test-strategies/MAS-04-FIX-P0-ALL.md` is writable by any workspace agent before executor spawn.
- Session JSON (`.ai/context/workflow-sessions/MAS-04-FIX-P0-ALL.json`) records spawn order but not brief checksums.

**Conclusion:** **Validated** — no TOCTOU protection in protocol v1.2.0.

### Finding #6 — Cap overflow skip order (P2)

**Evidence:**

- `skills/multi-agent-system/protocol/token-rules.md` lines 18–22: test-executor dropped before security-auditor.

**Conclusion:** **Validated** — intentional token policy; security assurance gap under cap stress.

### Finding #9 — Skill supply chain (P2)

**Evidence:**

- `skills/multi-agent-system/install/manifest.json` registers four P0 skills.
- All four SKILL.md files set `disable-model-invocation: true` (supply-chain brief table).

**Conclusion:** **Validated** — install surface expanded; static review only this pass.

### Dogfood fixture — auth/API scope alignment

| Check | Result |
|-------|--------|
| `SECURITY_AUDIT: yes` handoff | PASS |
| `SCOPE` includes auth + API | PASS (framework); fixture has no auth — documented gap #3 |
| OpenAPI in FILES audited | PASS |
| test-executor shell risk reviewed | PASS |
| Code patches applied | **None** (advisory v1) |

---

## Blockers

> Advisory only — `SECURITY_BLOCKER: yes` **not** set on handoff. Reviewer may reference these; merge block requires user opt-in per `handoff-format.md`.

| # | Finding | Rationale | Fix agent |
|---|---------|-----------|-----------|
| 1 | Shell execution without skill-level denylist (#1, #12) | Highest blast-radius among P0 quartet; strategy safety notes are not enforceable at executor | general-dev / protocol maintainer |
| 2 | Prompt-injection channel in strategy → executor (#2) | LLM agents treat markdown commands as authoritative; dogfood mitigations are per-TASK_ID | general-dev (skill + protocol) |

---

## Recommendations (consolidated)

| Priority | Action | Owner |
|----------|--------|-------|
| P1 | Encode dogfood **Safety constraints** into `mas-test-executor/SKILL.md` **Rules** as mandatory denylist and single-file path scope | general-dev |
| P1 | Require executor to extract commands only from fenced `powershell`/`bash` blocks in strategy brief | general-dev |
| P2 | Reviewer step: verify test-run `Source` column cites strategy § numbers; flag commands not in strategy | mas-reviewer skill |
| P2 | When both `RUN_TESTS` and `SECURITY_AUDIT` set, document cap-overflow assurance gap in coordinator user summary | mas-coordinator |
| P2 | Add fixture comment or companion README: not production-ready; auth required before deploy | general-dev |
| P3 | Enable `SECURITY_BLOCKER: yes` on production feature handoffs where audit blockers must gate merge | user / coordinator |

---

## Usage Report

Model: claude-opus-4-7-thinking-high  
Class: thinking  
Tokens: unknown

DONE
