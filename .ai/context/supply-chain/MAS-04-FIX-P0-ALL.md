# Supply-Chain Brief — MAS-04-FIX-P0-ALL

**TASK_ID:** MAS-04-FIX-P0-ALL  
**MODE:** MAS-self-scan (dogfood P0 spawn validation)  
**SCOPE:** mas-framework  
**Audited:** 2026-07-28  
**Confidence:** HIGH (static inventory); MEDIUM (CVE — no lockfiles present)

## Dependency delta

### Install manifest (`skills/multi-agent-system/install/manifest.json`)

| Change | Item | Detail |
|--------|------|--------|
| Version bump | `mas-cursor-framework` | `1.1.x` → **`1.2.0`** (Phase A P0 quartet) |
| Added skills | `mas-security-auditor` | Advisory STRIDE/OWASP brief writer; `MODEL_CLASS: thinking` |
| Added skills | `mas-dependency-risk` | Advisory CVE/blast-radius + MAS-self-scan; `MODEL_CLASS: fast` |
| Added skills | `mas-api-contract` | Advisory OpenAPI/GraphQL/Proto drift; `MODEL_CLASS: normal` |
| Added skills | `mas-test-executor` | Run-only test evidence; `MODEL_CLASS: normal` |
| Unchanged | `commands`, `rules`, `hooks`, `docs`, `hooksJson` | `mas.md`, `mas-lite.md`; `multi-agent-hybrid.mdc`; `mas-session-context.{ps1,sh}`; `USER-RULE-MAS.md` |

**Manifest skill count:** 26 entries. **On-disk parity:** all 26 `skills/{name}/` trees present; no orphan skill dirs outside manifest.

### Package / lockfile deltas

| Surface | Status |
|---------|--------|
| `package.json` / lockfiles | **None** in repo — framework is markdown + PowerShell/Bash scripts only |
| npm / pnpm / yarn / pip / cargo | **No managed third-party runtime deps** in `skills/` or `hooks/` |
| Dogfood fixture | `.ai/fixtures/MAS-04-FIX-P0-ALL/openapi.yaml` — synthetic OpenAPI 3.0 stub; no external refs or `$ref` imports |

### Skills tree delta (Phase A P0)

| Skill | `disable-model-invocation` | Code patch | Spawn authority | Brief path |
|-------|---------------------------|------------|-----------------|------------|
| `mas-security-auditor` | yes | forbidden | Coordinator only | `.ai/context/security-audits/{TASK_ID}.md` |
| `mas-dependency-risk` | yes | forbidden | Coordinator only | `.ai/context/supply-chain/{TASK_ID}.md` |
| `mas-api-contract` | yes | forbidden | Coordinator only | `.ai/context/api-contracts/{TASK_ID}.md` |
| `mas-test-executor` | yes | forbidden (run-only v1) | Coordinator only | `.ai/context/test-runs/{TASK_ID}.md` |

### MCP / external config

| Surface | Status |
|---------|--------|
| MCP servers in manifest | **Not bundled** — MCP trust boundary is user/workspace config outside install manifest |
| Network calls in skills/hooks grep | **None** in `skills/**` (CVE lookup deferred to agent runtime when applicable) |

## CVE summary

No lockfiles or package manifests exist in this framework repo. Traditional package CVE/EPSS lookup is **not applicable** to the audited delta.

| Package / surface | Version | CVE/EPSS | Severity | Status |
|-------------------|---------|----------|----------|--------|
| npm/pip/cargo deps | — | — | — | **N/A** (no lockfiles) |
| PowerShell hook runtime | OS-bundled | — | — | **unknown** (host OS patch cadence) |
| Bash hook runtime | OS-bundled | — | — | **unknown** (host OS patch cadence) |
| Skill markdown content | v1.2.0 bundle | skill-poisoning (OWASP LLM) | advisory | **known pattern** — trust install source |
| P0 specialist prompts | new in 1.2.0 | — | — | **review** — static scan only this pass |

**Offline OSV commands** (for downstream projects that add lockfiles):

```bash
# Node (when package-lock.json present)
osv-scanner --lockfile=package-lock.json

# Python (when requirements.txt or poetry.lock present)
osv-scanner --lockfile=requirements.txt
```

## Blast radius

### Direct impact (manifest v1.2.0)

Installing or exporting the framework copies **four new coordinator-routable specialists** into `~/.cursor/skills/`. Each expands the deterministic spawn surface defined in `mas-coordinator/SKILL.md` predicates P0-1–P0-4.

### Runtime surfaces

| Surface | Exposure | Notes |
|---------|----------|-------|
| **Coordinator spawn chain** | HIGH | Four new early/post-dev chain slots; overflow skip order documented in `token-rules.md` |
| **test-executor** | **HIGHEST** among P0 quartet | Executes shell commands from test-strategy brief — command injection risk bounded by test-strategy authorship and reviewer gate |
| **Hooks (`mas-session-context`)** | MEDIUM | Runs on `sessionStart` (context inject) and `subagentStop` (chain reminder); reads `.ai/handoffs/*.md`; no network I/O |
| **Install script** | MEDIUM | `install-mas-framework.ps1` copies full skill trees to `~/.cursor`; registers hooks with `-ExecutionPolicy Bypass` |
| **dependency-risk** | LOW–MEDIUM | Optional runtime CVE/OSV network lookup; advisory output only |
| **security-auditor / api-contract** | LOW | Read-only audit; no shell execution mandated by skill |

### MAS-self-scan notes

1. **Skill trust boundary:** Manifest is the install allowlist. A malicious or drifted skill tree copied to `~/.cursor/skills/` affects every `/mas` and `/mas-lite` session in that profile — equivalent to prompt/rule injection across the coordinator chain.
2. **Hook trust boundary:** `subagentStop` hook surfaces pending `NEXT_AGENT` from handoffs — integrity of `.ai/handoffs/` affects chain routing hints (Coordinator still owns Task spawn).
3. **Mutual exclusion preserved:** P0 specialists are advisory-only; `mas-reviewer` remains sole `Approved:` gate; `mas-release-readiness` category sweeps unchanged.
4. **Dogfood fixture scope:** Synthetic `openapi.yaml` carries no supply-chain deps; validates api-contract predicate only.
5. **No transitive package depth:** Framework blast radius is **skill/hook content and spawn topology**, not CVE transitive graphs.

### Transitive depth

**Depth 0** for package CVE purposes. Logical dependency chain for install: `manifest.json` → `install-mas-framework.ps1` → `~/.cursor/skills/*` + `~/.cursor/hooks/*` + `hooks.json`.

## Remediation

| # | Item | Action | Priority | Notes |
|---|------|--------|----------|-------|
| 1 | P0 quartet manifest registration | **review** | P0 | Confirm export/install dry-run includes all four skill dirs before Phase A ship |
| 2 | test-executor command surface | **review** | P1 | Test-strategy brief should list bounded, explicit commands; avoid user-interactive or destructive ops in dogfood matrix |
| 3 | Install hook `-ExecutionPolicy Bypass` | **review** | P2 | Acceptable for Cursor hook registration; document trust assumption that bundle source is verified (git tag / signed release) |
| 4 | Skill content integrity | **pin/review** | P2 | Treat `skills/` as supply-chain artifact; PR review for hidden instructions in new P0 SKILL.md files |
| 5 | Downstream lockfile projects | **document** | P3 | When consuming repos add lockfiles, re-run dependency-risk with OSV commands above; do not infer clean bill from framework-only scan |
| 6 | MCP servers (user-configured) | **review** | P2 | Not in manifest — document that MCP trust is out-of-band; dependency-risk should scan MCP config when listed in handoff `FILES` |
| 7 | Manifest ↔ disk drift | **review** | P1 | `export-mas-framework.ps1` `Test-InstallParity` guards install script parity; extend CI to fail on manifest skill missing on disk |

## Validation (dogfood TASK_ID)

| Check | Result |
|-------|--------|
| `SUPPLY_CHAIN: yes` handoff received | PASS |
| MAS-self-scan of `manifest.json` + `skills/` | PASS |
| Brief written to `.ai/context/supply-chain/MAS-04-FIX-P0-ALL.md` | PASS |
| Code patches applied | **None** (advisory v1) |

## Usage Report

Model: composer-2.5-fast  
Class: fast  
Tokens: unknown

DONE
