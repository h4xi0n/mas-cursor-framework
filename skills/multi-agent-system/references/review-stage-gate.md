# Stage 1: Deterministic Mechanical Gate & Fast-Fail Circuit Breaker

Source of Truth (SOT) for Stage 1 of the Multi-Stage Adaptive Review Architecture (v2.0.0). Reference standard for [mas-reviewer](../../mas-reviewer/SKILL.md) deterministic pre-flight verification.

---

## Purpose

Stage 1 executes automated, deterministic tools via the host environment and MAS host mutex (`mas-host-exec`) **prior to invoking any semantic LLM reasoning or domain review profiles**.

Static syntax errors, uncompilable code, test assertion failures, and leaked credentials are confirmed mechanically. If any check fails, the **Fast-Fail Circuit Breaker** trips immediately with `Approved: NO` and raw diagnostics, halting review execution and saving $\ge 75\%$ prompt tokens on broken diffs.

---

## Tool Invocation Sequence

Deterministic checks execute in strict linear sequence:

1. **Static Linter (`ReadLints`):**  
   Run `ReadLints` across every path in handoff `FILES`. Detect syntax errors, missing symbols, and static analysis violations on modified lines.
2. **Compilation Check (`mas-host-exec` build):**  
   Execute module compilation wrapped in the host mutex:
   ```powershell
   # Android Gradle
   mas-host-exec --task-id {TASK_ID} -- ./gradlew :module:compileDebugKotlin
   # Node / TypeScript
   mas-host-exec --task-id {TASK_ID} -- npm run build
   # Python
   mas-host-exec --task-id {TASK_ID} -- python -m py_compile {FILES}
   ```
3. **Unit Test Execution (`mas-host-exec` test):**  
   Execute affected unit tests wrapped in host mutex:
   ```powershell
   mas-host-exec --task-id {TASK_ID} -- ./gradlew :module:testDebugUnitTest
   ```
4. **Secret & Diff Hygiene Scan:**  
   Regex scan git diffs of modified files for committed credentials, API keys, and sensitive tokens (e.g. `AKIA[0-9A-Z]{16}`, `AIza[0-9A-Za-z\\-_]{35}`, `ghp_[0-9a-zA-Z]{36}`, private keys).

---

## Exit Code & Result Mapping

| Check | Tool / Command | PASS Condition | FAIL Condition |
|---|---|---|---|
| **Static Linter** | `ReadLints (FILES)` | 0 errors on modified lines | $\ge 1$ error on modified lines |
| **Compilation** | `mas-host-exec <build>` | Exit code `0` | Exit code $\ne 0$ |
| **Unit Tests** | `mas-host-exec <test>` | Exit code `0` (or `NOT_RUN` with approved rationale) | Exit code $\ne 0$ (failing assertions) |
| **Secret Scan** | Diff regex scan | 0 pattern matches | $\ge 1$ matched credential pattern |

---

## Fast-Fail Circuit Breaker Contract

If **ANY** check in Stage 1 results in `FAIL`:
1. Emit `## Stage 1: Mechanical Gate Results` table with individual check exit codes.
2. Mark `Stage 1 Gate Status: FAIL (Circuit Breaker Tripped)`.
3. Provide raw compiler/linter error output under `### Mechanical Diagnostics`.
4. Output `Approved: NO`.
5. Append `## Daily Summary`, `## Memory Update`, and `## Usage Report`.
6. Terminate execution immediately with `DONE`.

**Invariant:** When Stage 1 fails, the Reviewer **MUST NOT** load Stage 2 profile files, inspect visual layouts, or evaluate subjective edge cases.

---

## Circuit Breaker Output Template

```markdown
## Stage 1: Mechanical Gate Results

| Check | Tool / Command | Exit Code | Result | Diagnostics |
|-------|----------------|-----------|--------|-------------|
| Static Linter | ReadLints (FILES) | 1 | FAIL | 2 syntax errors detected |
| Compilation | mas-host-exec ./gradlew :core:compileDebugKotlin | 1 | FAIL | Unresolved reference: 'UserProfile' |
| Unit Tests | mas-host-exec ./gradlew :core:testDebugUnitTest | — | SKIPPED | Blocked by compilation failure |
| Secret Scan | Diff regex scan | 0 | PASS | Clean |

Stage 1 Gate Status: FAIL (Circuit Breaker Tripped)

### Mechanical Diagnostics
```text
core/src/main/java/com/example/UserProfile.kt:42:15: error: unresolved reference: UserAvatar
core/src/main/java/com/example/UserProfile.kt:88:9: error: missing return statement
```

Approved: NO

## Daily Summary
Fast-fail mechanical gate tripped: compilation failure in :core:compileDebugKotlin.

## Memory Update
None

## Usage Report
Model: inherit
Class: normal
Tokens: unknown

DONE
```

---

## Stage 1 PASS Contract

When all four checks pass (or tests are `NOT_RUN` with documented reason):
```markdown
## Stage 1: Mechanical Gate Results

| Check | Tool / Command | Exit Code | Result | Diagnostics |
|-------|----------------|-----------|--------|-------------|
| Static Linter | ReadLints (FILES) | 0 | PASS | Clean (0 errors, 0 warnings) |
| Compilation | mas-host-exec <build command> | 0 | PASS | Build successful |
| Unit Tests | mas-host-exec <test command> | 0 | PASS | All unit tests passed |
| Secret Scan | Diff regex scan | 0 | PASS | Clean (no secrets detected) |

Stage 1 Gate Status: PASS (Proceed to Stage 2)
```
Proceed immediately to **Stage 2: Situation-Adaptive Domain Deep-Dive**.
