# Test Strategy — MAS-04-FIX-P0-ALL

## Feature

P0 dogfood spawn validation — synthetic fixture `MAS-04-FIX-P0-ALL` exercises the Phase A quartet (`dependency-risk`, `api-contract`, `security-auditor`, `test-executor`) with all four routing flags. This brief scopes **bounded, read-only verification** for test-executor: manifest JSON parse, protocol `rg` checks on `brief-schemas` / handoff flags, and existence + section headings for the four P0 brief paths.

## Scope

| Layer | Paths |
|-------|-------|
| Install manifest | `skills/multi-agent-system/install/manifest.json` |
| Protocol registry | `skills/multi-agent-system/protocol/brief-schemas.md`, `handoff-format.md` |
| Dogfood fixture | `.ai/fixtures/MAS-04-FIX-P0-ALL/openapi.yaml` |
| P0 brief paths (TASK_ID) | `.ai/context/supply-chain/`, `api-contracts/`, `security-audits/`, `test-runs/` |
| Session evidence | `.ai/context/workflow-sessions/MAS-04-FIX-P0-ALL.json` |

**Out of scope:** Gradle/Android tests, export script dry-run (writes outside repo), live CVE/OSV network calls, full `/mas` coordinator chain replay, production code patches.

## Test Surfaces

`schema` (manifest parse, brief registry) · `integration` (protocol flags, brief path existence) · `manual` (coordinator chain order — covered by reviewer, not test-executor)

No unit test pyramid — framework is markdown/skills only.

---

## Tests to Write

| # | Type | Target | Scenario | Rationale | Priority | Flaky risk | Mitigation | Command hint |
|---|------|--------|----------|-----------|----------|------------|------------|--------------|
| 1 | integration | `manifest.json` | Parse JSON; `version` is `1.2.0`; skills array contains all four P0 slugs | Install acceptance A4; malformed manifest blocks export | P0 | LOW | Single-file read; `ConvertFrom-Json` throws on invalid JSON | See **Recommended Commands** §1 |
| 2 | integration | `brief-schemas.md` | Registry table lists all four P0 types with correct path patterns and required sections | Reviewer schema validation depends on registry | P0 | LOW | Bounded `rg` to one file | See **Recommended Commands** §2 |
| 3 | integration | `handoff-format.md` | Four routing flags (`SECURITY_AUDIT`, `API_CONTRACT`, `SUPPLY_CHAIN`, `RUN_TESTS`) documented | Zero-token coordinator predicates | P0 | LOW | Bounded `rg` to one file | See **Recommended Commands** §3 |
| 4 | integration | P0 brief paths | Three specialist briefs exist at registry paths for `MAS-04-FIX-P0-ALL`; `test-runs` brief is executor output (verify after write) | Plan task 20 — four brief paths | P0 | LOW | `Test-Path` on fixed paths only | See **Recommended Commands** §4–§5 |
| 5 | schema | Specialist brief headings | Each existing specialist brief contains required section headings per `brief-schemas.md` | Schema gap detection pre-reviewer | P0 | LOW | `rg` per brief file; no file writes | See **Recommended Commands** §6 |
| 6 | integration | Dogfood fixture | `openapi.yaml` exists and declares `openapi: 3.0.0` | `API_CONTRACT` + FILES predicate input | P1 | LOW | Single-file `rg` | See **Recommended Commands** §7 |
| 7 | integration | `subagent-spawn.md` | Four P0 slug rows present in spawn table | Task spawn contract | P1 | LOW | Bounded `rg` | See **Recommended Commands** §8 |
| 8 | integration | Session JSON | `workflow-sessions/MAS-04-FIX-P0-ALL.json` parses; lists `dependency-risk` and `api-contract` in steps | Spawn evidence for dogfood | P1 | LOW | Read-only JSON parse | See **Recommended Commands** §9 |

**test-executor boundary:** Execute only P0 rows (#1–#5). Run P1 rows (#6–#8) if time permits; document skip in Gaps if omitted. Row #4 `test-runs` path: verify existence **after** writing `.ai/context/test-runs/MAS-04-FIX-P0-ALL.md` (self-check only).

---

## Tests to Skip

| # | Target | Reason | Covered by |
|----|--------|--------|------------|
| 1 | `export-mas-framework.ps1` dry-run | Writes to `$env:TEMP`; side-effect outside repo; not required for P0 path verification | Manual install QA; MAS-04 strategy row #11 |
| 2 | Live CVE/OSV network lookup | Offline-friendly dogfood; dependency-risk brief is advisory | supply-chain brief review |
| 3 | Gradle / npm / pytest suites | No JVM/Node test harness in MAS repo | N/A |
| 4 | Full `/mas` coordinator chain replay | E2E spawn order verified manually + reviewer | Reviewer + session JSON |
| 5 | `handoff-format-lite.md` abbreviations | Out of FIX-P0-ALL handoff scope | MAS-04 strategy row #4 |
| 6 | Export skill folder enumeration | Requires temp dir writes | Skip table #1 |
| 7 | Patching or re-running specialist agents | test-executor is run-only v1 | Coordinator chain |
| 8 | `test-runs` brief pre-existence check | File is executor deliverable; checking before write is N/A | Row #4 post-write self-check |

---

## Edge Cases

| Case | Layer | Test approach | Priority |
|------|-------|---------------|----------|
| Malformed `manifest.json` | Install | `ConvertFrom-Json` throws → FAIL | P0 |
| P0 skill missing from manifest array | Install | Assert count of four slugs == 4 | P0 |
| Specialist brief exists but missing required heading | Schema | `rg` section name → exit 1 → FAIL with path | P0 |
| `security-audits` brief not yet written when executor runs | Chain | FAIL row #4; document in Gaps; route bug-fix | P0 |
| `test-runs` path checked before executor write | Executor | Skip pre-check; post-write `Test-Path` only | P0 |
| Fixture OpenAPI missing `openapi:` key | Fixture | `rg` on fixture → FAIL | P1 |
| Session JSON missing or invalid | Evidence | Parse failure → FAIL row #8 or SKIP with rationale | P1 |
| `rg` not installed | Shell | Fall back to `Select-String` equivalent; document in test-run brief | P2 |

---

## Regression Risks

**MAS-04** (2026-07-28, feature): Phase A v1.2.0 shipped protocol, quartet skills, routing, manifest 1.2.0. This fixture must not regress MAS-01 routing (`spawn-model-policy`, debate, token-auditor). Spot-check: manifest still lists pre-Phase-A skills (`mas-debate`, `mas-token-auditor`) alongside P0 quartet.

---

## Flaky Test Risks

| Risk | Surface | Mitigation |
|------|---------|------------|
| Specialist brief not yet on disk when executor spawns early | Brief path checks | Coordinator must spawn test-executor post-dev + post security-auditor; if brief missing, FAIL and document — do not retry spawn |
| `rg` vs `Select-String` variance on Windows | Protocol checks | Use `rg` when available; bounded single-file patterns; no repo-wide search |
| JSON parse encoding (BOM) | manifest / session | `Get-Content -Raw`; fail fast on parse error |
| Self-referential test-runs check | Executor output | Verify test-runs path only after brief write |

---

## Recommended Commands

**Safety constraints for test-executor (mandatory):**

- Read-only except writing `.ai/context/test-runs/MAS-04-FIX-P0-ALL.md`
- No `git`, `npm`, `curl`, network, or recursive repo scans
- Each command targets **one file or fixed path list** — no wildcards beyond listed paths
- Max **one attempt** per command; no unbounded retry
- Working directory: repo root (`mas-cursor-framework`)
- Expected pass: exit code `0` and non-empty match output where noted

### §1 — Manifest JSON parse (P0, test #1)

```powershell
$m = Get-Content skills/multi-agent-system/install/manifest.json -Raw | ConvertFrom-Json
if ($m.version -ne '1.2.0') { throw "version mismatch: $($m.version)" }
$required = @('mas-security-auditor','mas-dependency-risk','mas-api-contract','mas-test-executor')
$missing = $required | Where-Object { $m.skills -notcontains $_ }
if ($missing) { throw "missing P0 skills: $($missing -join ', ')" }
'PASS manifest parse'
```

### §2 — brief-schemas registry (P0, test #2)

```powershell
rg -n "security-audit|api-contract|supply-chain|test-run" skills/multi-agent-system/protocol/brief-schemas.md
```

**Pass criteria:** ≥4 matching lines; each of `security-audit`, `api-contract`, `supply-chain`, `test-run` appears.

### §3 — handoff routing flags (P0, test #3)

```powershell
rg -n "SECURITY_AUDIT|API_CONTRACT|SUPPLY_CHAIN|RUN_TESTS" skills/multi-agent-system/protocol/handoff-format.md
```

**Pass criteria:** all four flag strings match at least once.

### §4 — P0 brief path existence (P0, test #4)

```powershell
$briefs = @(
  '.ai/context/supply-chain/MAS-04-FIX-P0-ALL.md',
  '.ai/context/api-contracts/MAS-04-FIX-P0-ALL.md',
  '.ai/context/security-audits/MAS-04-FIX-P0-ALL.md'
)
$briefs | ForEach-Object {
  if (-not (Test-Path $_)) { throw "missing brief: $_" }
  $_
}
'PASS specialist brief paths'
```

**Note:** `test-runs` path verified post-write (§5).

### §5 — test-runs brief post-write check (P0, test #4 cont.)

```powershell
if (-not (Test-Path '.ai/context/test-runs/MAS-04-FIX-P0-ALL.md')) {
  throw 'test-runs brief not written'
}
'PASS test-runs brief path'
```

Run **after** executor writes the test-run brief.

### §6 — Required section headings per specialist brief (P0, test #5)

```powershell
rg -n "^## (Dependency delta|CVE summary|Blast radius|Remediation)" .ai/context/supply-chain/MAS-04-FIX-P0-ALL.md
rg -n "^## (Spec [Ii]nventory|Breaking changes|Drift|Recommendations)" .ai/context/api-contracts/MAS-04-FIX-P0-ALL.md
rg -n "^## (Threat model|Findings|Validation|Blockers)" .ai/context/security-audits/MAS-04-FIX-P0-ALL.md
```

**Pass criteria:** each `rg` returns ≥1 match. Case Relaxed on `Spec inventory` via pattern above.

### §7 — Dogfood OpenAPI fixture (P1, test #6)

```powershell
rg -n "^openapi:\s*3\.0\.0" .ai/fixtures/MAS-04-FIX-P0-ALL/openapi.yaml
```

### §8 — subagent-spawn P0 slugs (P1, test #7)

```powershell
rg -n "security-auditor|dependency-risk|api-contract|test-executor" skills/multi-agent-system/protocol/subagent-spawn.md
```

**Pass criteria:** all four slugs match.

### §9 — Session JSON evidence (P1, test #8)

```powershell
$s = Get-Content .ai/context/workflow-sessions/MAS-04-FIX-P0-ALL.json -Raw | ConvertFrom-Json
$s.task_id
$s.steps.agent
```

**Pass criteria:** `task_id` equals `MAS-04-FIX-P0-ALL`; `steps.agent` includes `dependency-risk` and `api-contract`.

---

## Expected P0 Brief Paths (registry)

| Type | Path | Required sections |
|------|------|-------------------|
| supply-chain | `.ai/context/supply-chain/MAS-04-FIX-P0-ALL.md` | Dependency delta, CVE summary, Blast radius, Remediation |
| api-contract | `.ai/context/api-contracts/MAS-04-FIX-P0-ALL.md` | Spec inventory, Breaking changes, Drift, Recommendations |
| security-audit | `.ai/context/security-audits/MAS-04-FIX-P0-ALL.md` | Threat model, Findings, Validation, Blockers |
| test-run | `.ai/context/test-runs/MAS-04-FIX-P0-ALL.md` | Commands, Pass/fail, Failures, Gaps |

---

## Overall Confidence

**HIGH** — Handoff scope is narrow (manifest parse, bounded `rg`, four brief paths). Commands are read-only, single-file, offline-safe, and aligned with `mas-test-executor` run-only v1. Parent MAS-04 strategy provides permutation matrix; this brief is the executor playbook for the `MAS-04-FIX-P0-ALL` fixture only.

---

## Files Reviewed

- `.ai/handoffs/MAS-04-FIX-P0-ALL-test-strategy.md`
- `.ai/handoffs/MAS-04-FIX-P0-ALL.md`
- `.ai/context/memory.md`
- `.ai/context/daily-changelog.md`
- `.ai/context/test-strategies/MAS-04.md` (parent fixture matrix)
- `skills/multi-agent-system/install/manifest.json`
- `skills/multi-agent-system/protocol/brief-schemas.md`
- `skills/multi-agent-system/protocol/handoff-format.md`
- `.ai/fixtures/MAS-04-FIX-P0-ALL/openapi.yaml`
- `.ai/context/supply-chain/MAS-04-FIX-P0-ALL.md`
- `.ai/context/api-contracts/MAS-04-FIX-P0-ALL.md`
- `.ai/context/workflow-sessions/MAS-04-FIX-P0-ALL.json`

---

## Open Questions

1. **security-auditor timing** — If test-executor spawns before security-auditor completes, row #4 will fail; coordinator must enforce post-security-auditor slot per MAS-04 chain invariant #2.
2. **Section heading casing** — Specialist briefs may use title case (`Spec Inventory` vs `Spec inventory`); `rg` patterns use case-relaxed forms; reviewer is authoritative for schema gaps.

---

## Usage Report

Model: default
Class: normal
Tokens: unknown

DONE
