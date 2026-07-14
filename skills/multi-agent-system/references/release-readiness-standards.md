# Release Readiness Standards

Reference for the **Release Readiness** agent (`mas-release-readiness`). Defines how to audit production readiness across **17 check categories** with explicit **PASS / FAIL / N/A** criteria — without patching code.

## Purpose & boundaries

| In scope | Out of scope |
|----------|--------------|
| Pre-release audit across 17 production-readiness categories | Writing or editing production code |
| PASS / FAIL / N/A per category with evidence | Adding features or new functionality |
| Rank P0/P1/P2 blockers and fix-agent routing | Cosmetic or layout changes |
| Regression lens via daily changelog | Spawning agents or routing workflows |
| Brief at `.ai/context/release-readiness/{TASK_ID}.md` | Replacing Reviewer change-set validation |
| Gradle/lint/static analysis where feasible | Auto-commit or auto-ship |

Release Readiness **narrows ship-blocking issues** for fix agents. Dev/Bug Fix may confirm, extend, or reject brief items per handoff scope.

**Holistic ship gate** — broader than Reviewer approval on a single change set. `Approved: YES` ≠ `Release Ready: YES`.

## Objective

Evaluate whether the project (or scoped modules) is ready to ship to production / store submission. **Never patch code** — audit and brief only.

## Inputs

Coordinator handoff should include:

| Field | Required | Notes |
|-------|----------|-------|
| `RELEASE_TARGET` | Yes | Version / build / channel or `unknown` |
| `SCOPE` | Yes | Modules, screens, flows, or file prefixes to audit |
| `FILES` | Optional | Seed paths — manifest, Gradle, critical screens |
| `RELEASE_ONLY` | Optional | `true` → deliver brief only; no fix chain |
| `DELIVERABLE` | Default | Brief at `.ai/context/release-readiness/{TASK_ID}.md` |

Startup reads: handoff, `memory.md`, `daily-changelog.md` (if present), this doc, then **only** seed `FILES` and scope-discovered paths.

## Workflow

1. **Intake** — restate `RELEASE_TARGET`, bound `SCOPE`, note seed `FILES`.
2. **Seed read** — handoff `FILES` and paths discovered from scope only; no broad repo scan.
3. **Category sweep** — evaluate all 17 categories below; collect evidence per category.
4. **Verdict** — assign PASS / FAIL / N/A; for FAIL assign blocker level P0 / P1 / P2 and default fix agent.
5. **Ranking** — order failures in `Priority Order` (P0 before P1; within level by ship risk).
6. **Brief write** — persist full schema to `release-readiness/{TASK_ID}.md`.
7. **Summary** — return chat output (full category table or lite bullets + brief path).

## Per-category record format

Each category row in brief and full chat output:

| Field | Content |
|-------|---------|
| **Category** | One of 17 IDs (see matrix below) |
| **Status** | `PASS` \| `FAIL` \| `N/A` |
| **Evidence** | Gradle output, file paths, checklist notes, `MANUAL` with rationale |
| **Blocker level** | `P0` \| `P1` \| `P2` \| `—` (when PASS or N/A) |
| **Finding** | What failed or why N/A |
| **Recommended fix direction** | Concrete remediation hint (not a patch) |
| **Fix agent** | `bug-fix` \| `android-dev` \| `general-dev` \| `user` |

**Overall verdict:** `Release Ready: YES` only when no P0 FAIL. `Release Ready: NO` if any P0 FAIL. P1 FAIL may still block ship per Coordinator/user policy; default: NO if any P0, YES with documented P1 residual risk only when user accepts.

**Confidence per category:** HIGH \| MEDIUM \| LOW (static-only or MANUAL evidence → MEDIUM/LOW).

## 17 check categories

### 1. Crashes

**Pass criteria:**
- No known crash paths in release scope
- Crash reporting configured (Firebase Crashlytics, Sentry, or project equivalent)
- No `TODO` crash handlers masking failures

**Fail criteria:**
- Uncaught exception paths in scope
- Missing `try/catch` on critical I/O without error mapping
- Debug-only error suppression in release paths

**Evidence sources:** stack traces, ProGuard mapping note, critical-path walkthrough, `FILES` in scope.

**Default fix agent:** `bug-fix`

---

### 2. Lint

**Pass criteria:**
- Release-variant lint/compile clean on changed modules
- No Error-level Android/Kotlin lint on ship paths
- `@Suppress` justified where present

**Fail criteria:**
- Lint errors on release path
- Missing `@Suppress` justification
- Deprecated API on release path without migration plan

**Evidence sources:** `./gradlew :<module>:lintRelease` or `lintDebug`; ReadLints on `FILES`; ESLint/tsc for non-Android.

**Default fix agent:** `android-dev` \| `general-dev` (by stack)

---

### 3. ANRs

**Pass criteria:**
- No main-thread blocking in startup/critical UI
- WorkManager/coroutines for long work
- No `runBlocking` on UI thread

**Fail criteria:**
- Sync I/O on main thread
- `runBlocking` on UI thread / composition
- Heavy work in `onCreate` / composition without deferral

**Evidence sources:** code walkthrough; ANR-prone patterns from [android-veteran-standards.md](android-veteran-standards.md).

**Default fix agent:** `bug-fix` (functional) \| `android-dev` (dispatcher refactor)

---

### 4. Startup

**Pass criteria:**
- Application/DI lean on cold start path
- Lazy init for non-critical SDKs
- No blocking network on splash/cold start

**Fail criteria:**
- Eager heavy init on critical path
- Content provider cost without justification
- Splash blocking network

**Evidence sources:** `Application`, Hilt modules, startup tracing notes, `build.gradle.kts` startup deps.

**Default fix agent:** `android-dev`

---

### 5. Memory

**Pass criteria:**
- No obvious leak patterns (static Activity refs, unbounded caches)
- Bitmap decode sized to display
- `onTrimMemory` / `onLowMemory` where applicable

**Fail criteria:**
- Retained contexts in long-lived singletons
- Unbounded in-memory lists on data screens
- Large bitmap loads without sampling

**Evidence sources:** ViewModel/repo/composable lifecycle review.

**Default fix agent:** `bug-fix` (leak) \| `android-dev` (architecture)

---

### 6. Accessibility

**Pass criteria:**
- Semantics/content descriptions on interactive controls
- Touch targets ≥48dp
- TalkBack labels on icons
- fontScale-safe layouts

**Fail criteria:**
- Clickable without label
- Custom views without semantics
- Fixed px-only text ignoring fontScale

**Evidence sources:** Compose semantics audit on `FILES`/screens in scope.

**Default fix agent:** `android-dev`

---

### 7. Localization

**Pass criteria:**
- User strings in resources (`strings.xml` / i18n files)
- No hardcoded UI copy in release paths
- `strings.xml` completeness for supported locales
- RTL supported if claimed

**Fail criteria:**
- Hardcoded strings in UI
- Missing translations for shipped locales
- Concatenated localized strings

**Evidence sources:** grep + `res/values*` / locale files.

**Default fix agent:** `android-dev`

---

### 8. Play policy

**Pass criteria:**
- Permissions minimal and justified
- Sensitive APIs declared
- Data collection aligned with privacy policy
- No policy-violating behavior (background location, deceptive UX)

**Fail criteria:**
- Unnecessary permissions
- Undisclosed data use
- Misleading store listing vs app behavior

**Evidence sources:** `AndroidManifest.xml`, permission use sites, Data safety alignment checklist.

**Default fix agent:** `android-dev` + `user` (store listing)

---

### 9. Play Console requirements

**Pass criteria:**
- `targetSdk` meets Play minimum
- AAB configured for store build
- Feature/module declarations match manifest
- Privacy policy URL if required
- Content rating inputs consistent

**Fail criteria:**
- Below minimum `targetSdk`
- Missing bundle config
- Undeclared hardware features

**Evidence sources:** `build.gradle.kts`, manifest, Play Console prep checklist in brief.

**Default fix agent:** `android-dev`

---

### 10. Signing

**Pass criteria:**
- Release build type uses release signing config
- No debug keystore in release
- v2+ signing enabled

**Fail criteria:**
- `signingConfig` missing or wrong
- Secrets in repo (reference keys only in brief — never paste passwords)
- `debuggable true` on release build type

**Evidence sources:** app module Gradle, `gradle.properties` patterns (no secrets in brief).

**Default fix agent:** `android-dev` + `user` (keystore)

---

### 11. Versioning

**Pass criteria:**
- `versionCode` monotonic increment
- `versionName` follows project convention
- ABI/version splits configured if multi-APK

**Fail criteria:**
- Same or lower `versionCode` than last ship
- Missing changelog alignment

**Evidence sources:** `build.gradle.kts` `defaultConfig`, `package.json` version for non-Android.

**Default fix agent:** `android-dev` \| `general-dev`

---

### 12. Backups

**Pass criteria:**
- `android:allowBackup` intentional
- `backup_rules.xml` / `data_extraction_rules` exclude sensitive data
- No plaintext secrets in backup scope

**Fail criteria:**
- Sensitive tokens/PII in auto-backup without exclusion

**Evidence sources:** manifest + `res/xml/backup_rules.xml`.

**Default fix agent:** `android-dev`

---

### 13. ProGuard/R8

**Pass criteria:**
- `minifyEnabled true` for release
- Keep rules for reflection/serialization/Hilt/Compose
- Mapping upload workflow documented

**Fail criteria:**
- Missing keeps causing release-only crashes
- Minify off for store build

**Evidence sources:** `proguard-rules.pro`, release build attempt.

**Default fix agent:** `android-dev`

---

### 14. Baseline profiles

**Pass criteria:**
- Baseline profile generated and packaged for release when project uses profiles
- Startup benefit documented or N/A with reason

**Fail criteria:**
- Profile missing when module expects one
- Profile stale vs main dex

**Evidence sources:** `baseline-prof.txt`, Gradle baseline profile plugin config.

**Default fix agent:** `android-dev`

---

### 15. Battery

**Pass criteria:**
- No orphan wake locks
- Background work via WorkManager / scheduled jobs
- Respects Doze/App Standby
- No polling loops without justification

**Fail criteria:**
- `AlarmManager` abuse
- Frequent GPS/network wakeups without justification

**Evidence sources:** workers, receivers, location usage, background task code.

**Default fix agent:** `android-dev` \| `bug-fix`

---

### 16. Offline behavior

**Pass criteria:**
- Network failures surface user-visible error/retry
- Cached reads where promised
- No silent data loss offline

**Fail criteria:**
- Blank screen on offline
- Unhandled `IOException`
- Optimistic UI without rollback

**Evidence sources:** repository error mapping, UI empty/error states.

**Default fix agent:** `android-dev` \| `bug-fix`

---

### 17. Edge cases

**Pass criteria:**
- Empty/loading/error states on data screens
- Permission denial handled
- Process death args preserved
- Rotation/config change safe
- Double-submit guarded

**Fail criteria:**
- Unhandled null/empty
- Crash on deny permission
- Lost nav args

**Evidence sources:** reviewer edge-case matrix applied audit-side on scope; [android-veteran-standards.md](android-veteran-standards.md).

**Default fix agent:** `bug-fix` \| `android-dev` (by symptom)

---

## N/A rule

Non-Android projects or out-of-scope modules → mark category `N/A` with reason in Evidence (e.g. "framework-only workspace", "iOS module not in SCOPE", "web project — Play categories N/A").

Android-specific categories (Play policy, Play Console, Signing, Backups, ProGuard, Baseline profiles) → `N/A` for non-Android with reason.

Generic categories (Lint, Versioning, Edge cases) apply to all stacks with stack-appropriate evidence.

## Fix-agent selection table (Coordinator primary hop)

| Top P0 category (first in Priority Order) | Primary `NEXT_AGENT` |
|-------------------------------------------|----------------------|
| Crashes | `bug-fix` |
| ANRs (functional blocking) | `bug-fix` |
| Edge cases (crash/null/permission) | `bug-fix` |
| Lint (Android) | `android-dev` |
| Lint (non-Android) | `general-dev` |
| Startup, Memory (architecture), A11y, L10n, Play*, Signing†, Versioning, Backups, ProGuard, Baseline, Battery, Offline | `android-dev` |
| Signing / Play store listing† | `android-dev` + user action |

† Agent implements code/config; user supplies keystore, Play Console inputs.

## Brief file schema

Path: `.ai/context/release-readiness/{TASK_ID}.md`

```markdown
# Release Readiness Brief — {TASK_ID}

## Release Target
<version / build / channel or unknown>

## Scope
<modules, screens, flows, file prefixes>

## Release Ready
YES | NO

## Analysis Summary
<2–4 sentences: overall assessment, top blockers>

## Category Results
| Category | Status | Evidence | Blocker | Finding | Fix direction | Fix agent | Confidence |
|----------|--------|----------|---------|---------|---------------|-----------|------------|
| Crashes | PASS/FAIL/N/A | ... | P0/P1/P2/— | ... | ... | bug-fix | HIGH/MEDIUM/LOW |
| Lint | ... | ... | ... | ... | ... | ... | ... |
| ... (all 17 rows) ... |

## Priority Order
1. <Category> — <one line rationale>
...

## Regression Notes
<daily-changelog TASK_ID links or N/A>

## Files Analyzed
- path/to/file

## Manual / User Actions Required
<Play Console, keystore, store listing — no secrets>

## Open Questions
- ...

## Re-audit Guidance
<what to re-run after fix; Gradle tasks per failed category>
```

Create `release-readiness/` directory if missing. Brief is durable for the workflow session; fix agents and reviewer read when present.

## `RELEASE_ONLY` semantics

| Aspect | Behavior |
|--------|----------|
| Handoff | `RELEASE_ONLY: true` |
| Specialist action | Full 17-category audit; write brief |
| `NEXT_AGENT` | `none` — Coordinator must not spawn fix/documenter/reviewer |
| User follow-up | User may start new workflow with fix agent referencing `RELEASE_BRIEF` path |
| Parity | Same as `ANALYZE_ONLY`, `TRACE_ONLY`, `RESEARCH_ONLY`, `UX_ONLY` |
| Lite budget | Counts as **1** subagent (S-tier) |

When `RELEASE_ONLY: false` (default) and failures exist, Coordinator **must** set `NEXT_AGENT` to primary fix agent — not `none`.

## Skip criteria

Coordinator may **skip Release Readiness**:

| Condition | Route |
|-----------|-------|
| Greenfield feature work (no ship intent) | never release-readiness as entry |
| User has not expressed ship/release/store intent | do not auto-run release gate |
| Trivial config/typo fix with no release context | dev or bug-fix only |
| User says "skip release check" | omit gate (document in handoff if risky) |

Coordinator **must run** Release Readiness when:

| Condition | Route |
|-----------|-------|
| User says release, ship, production readiness, store submission | release-readiness |
| `/mas release` or `/mas-lite S release check` | release-readiness |
| User confirms ship after feature approval | release-readiness (even if Reviewer approved) |

When in doubt for ship intent — **run Release Readiness**.

## Mutual exclusivity

Release Readiness, Imaginer, and Perf Optimizer are **mutually exclusive same-hop entry points**:

| Signal | Route |
|--------|-------|
| Ship / release / store submission | Release Readiness |
| Crash, wrong data, functional bug | Imaginer → Bug Fix |
| Jank, slow start, memory, battery | Perf Optimizer → Dev |
| Mixed "fix crash then release" | Bug chain first, then new release workflow |
| Reviewer `Approved: YES` on feature | Not auto-release — user may run `/mas release` |

Do not chain release-readiness with imaginer or perf-optimizer as the **first** specialist on the same hop.

## Re-audit after fix

After fix chain `Approved: YES`, user may request full re-audit ("re-check release"):

- **Same `TASK_ID`** — only when user explicitly says re-audit same task
- **Else** — new `REL-{NN}` or user-provided `TASK_ID`
- Reviewer-only re-check (no full 17-category sweep) — default loop on `Approved: NO`

## Regression lens

Release Readiness cites changelog at audit time — fix agents read changelog independently.

When `.ai/context/daily-changelog.md` has same-day entries:

- Match release scope, `FILES`, or module prefix to changelog `TASK_ID`s
- Cite at most 2–3 entries under Regression Notes
- If changelog missing or empty, write `N/A`

## Secrets safety

**Never paste** keystore passwords, API keys, or signing secrets in brief or chat. Reference config keys and file paths only.

## Android vs generic layer notes

### Android (Jetpack / Compose)

| Area | Typical evidence |
|------|------------------|
| Ship config | `build.gradle.kts`, manifest, ProGuard rules |
| Store | targetSdk, AAB, signing, versioning |
| Runtime | ANR patterns, startup, memory, battery |
| UX ship | a11y, l10n, offline, edge cases |

### Generic (React / Next / Node / Python)

| Area | Typical evidence |
|------|------------------|
| Ship config | `package.json`, env config, CI deploy |
| Lint | ESLint, tsc, typecheck |
| Runtime | error boundaries, offline handling |
| Versioning | semver, changelog alignment |

Mark Android-only categories N/A with reason for non-Android projects.

## Re-run after fix guidance (for brief)

Document per failed category which checks fix agents and reviewer should re-run:

| Category | Typical re-check |
|----------|------------------|
| Crashes | Repro steps + targeted tests |
| Lint | `./gradlew :<module>:lintRelease` or ReadLints |
| ANRs | Code review + startup trace |
| ProGuard/R8 | `./gradlew :app:assembleRelease` |
| Edge cases | Manual matrix on changed screens |
