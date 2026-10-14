# Compliance Brief — MAS-04-B-FIX-ALL

**Framework:** GDPR (Regulation (EU) 2016/679)  
**Scope:** UI feature with user data handling — settings remove action (`IconOnlyActionButton` deletes list items in a Task Manager surface).  
**Tier:** none (Phase B dogfood spawn validation)  
**Advisory v1** — evidence gaps route to dev/legal HITL; reviewer remains sole `Approved:` gate. **Never auto-approve.**

## Audit scope

| Item | Value |
|------|-------|
| TASK_ID | MAS-04-B-FIX-ALL |
| COMPLIANCE_FRAMEWORK | GDPR |
| Data subject context | End-user task list items (may contain personal data if task titles/notes include names, emails, or identifiers) |
| EU relevance | `de` locale declared in strings stub — EU user base assumed possible |
| Files reviewed | `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md`, `.ai/fixtures/MAS-04-B-FIX-ALL/strings-stub.json` |
| Excluded | Backend retention jobs, DPA/SCC contracts, DPIA final sign-off, production logging infrastructure |

## Framework map

| Clause / control | Requirement (summary) | Applicability to fixture | Evidence status | Gap |
|------------------|----------------------|--------------------------|-----------------|-----|
| **Art. 5(1)(a)** — Lawfulness, fairness, transparency | Process personal data lawfully and transparently | Remove action deletes user task data; transparency depends on clear labeling and confirmation | partial | Icon-only button lacks accessible name; delete consequence copy exists in strings but is not wired to UI |
| **Art. 5(1)(c)** — Data minimization | Collect/process only data adequate and relevant | Task list scope is narrow; fixture does not define what fields a task stores | partial | No field inventory or minimization policy referenced in fixture |
| **Art. 5(1)(d)** — Accuracy | Keep personal data accurate and up to date | Remove action supports accuracy by letting users delete stale items | present | UI affordance for deletion exists in stub |
| **Art. 5(1)(e)** — Storage limitation | Retain data no longer than necessary | Deletion UI implies erasure intent; retention schedule not evidenced | missing | No retention period, soft-delete vs hard-delete policy, or backend purge evidence in scope |
| **Art. 5(1)(f)** — Integrity and confidentiality | Appropriate security for personal data | Client-side remove handler only; no security controls documented | missing | No authz check, CSRF/token, or transport-security evidence in stub |
| **Art. 5(2)** — Accountability | Controller demonstrates compliance | Engineering evidence audit only; no RoPA or policy artifacts | missing | No records of processing or controller/processor mapping |
| **Art. 6** — Lawful basis | Identify lawful basis before processing | Task data processing basis not documented in fixture | missing | No lawful-basis statement (contract, legitimate interest, consent, etc.) |
| **Art. 7** — Conditions for consent | If consent is basis: clear, withdrawable, demonstrable | Fixture does not assert consent basis; N/A unless product uses consent for tasks | n/a | Confirm lawful basis before implementing consent UX |
| **Art. 12** — Transparent communication | Concise, intelligible, easily accessible information | Delete action should be understandable to all users including AT users | partial | `button.remove` / confirm strings exist; UI stub has no visible label and no wired confirmation |
| **Art. 13** — Information at collection | Provide privacy information when collecting personal data | Task Manager title implies data collection; no privacy notice stub | missing | No link to privacy policy, purpose, or retention in fixture |
| **Art. 17** — Right to erasure | Erase personal data without undue delay when grounds apply | Remove button is the primary erasure affordance for list items | partial | Client-side `handleRemove` only; no evidence of server-side erasure, propagation to backups, or erasure confirmation to user |
| **Art. 25** — Data protection by design and by default | Embed privacy into design; default to least invasive | Confirmation-before-delete is a by-design control; strings prepared but not integrated | partial | `confirm.delete.*` strings present; UI stub deletes on single click with no confirm step |
| **Art. 30** — Records of processing activities | Maintain RoPA for processing operations | Deletion of tasks is a processing activity | missing | No RoPA entry or processing-purpose documentation in fixture |
| **Art. 32** — Security of processing | Appropriate technical and organizational measures | Deletion of personal data requires secure implementation | missing | No evidence of authenticated session, audit log, or secure API contract for delete |
| **Art. 33/34** — Breach notification | Notify authority/data subjects of breaches | Out of UI stub scope unless delete failure leaks data | n/a | Not assessable from fixture; flag for prod incident runbooks |
| **Recital 78 / Art. 35** — DPIA | DPIA where high risk to rights and freedoms | Task titles alone are typically low risk; risk rises if tasks store sensitive categories | partial | No DPIA artifact; recommend HITL DPIA if tasks may hold special-category data |

## Gaps

| # | Control | Gap | Severity | Remediation owner |
|---|---------|-----|----------|-------------------|
| 1 | Art. 17 / Art. 25 | Remove action fires on single click with no confirmation; `confirm.delete.title` / `confirm.delete.body` strings exist but are not wired to `IconOnlyActionButton` | P0 | dev |
| 2 | Art. 12 / Art. 25 | Icon-only delete control has no accessible name; users relying on assistive tech cannot understand the erasure action (transparency failure) | P0 | dev |
| 3 | Art. 17 | No evidence that deletion propagates to server, backups, caches, or third-party processors — stub is client-only | P1 | dev / legal |
| 4 | Art. 5(1)(e) | No documented retention or erasure schedule for deleted task items (soft-delete window, backup TTL) | P1 | legal / dev |
| 5 | Art. 6 | No lawful basis documented for task-list processing in fixture or companion architecture brief | P1 | legal |
| 6 | Art. 13 | No privacy notice, purpose statement, or link to policy at collection point | P1 | legal / dev |
| 7 | Art. 32 | No authz, audit logging, or secure-delete API evidence for remove handler | P1 | dev |
| 8 | Art. 30 | No RoPA entry for task storage and deletion lifecycle | P2 | legal |
| 9 | Art. 5(1)(c) | No data-field inventory defining what personal data a task item may contain | P2 | dev / legal |
| 10 | i18n × Art. 12 | `button.remove` ("Remove") is shorter than context-complete accessible name; German `de` locale supported but erasure UX not fully localized in UI stub | P2 | dev |

## Evidence

| Artifact | Location | Finding |
|----------|----------|---------|
| UI widget stub | `.ai/fixtures/MAS-04-B-FIX-ALL/ui-widget-stub.md` | `IconOnlyActionButton` renders trash icon; `onClick={handleRemove}` removes item with no confirmation gate |
| Markup gap (intentional seed) | same | No `aria-label`; icon `aria-hidden="true"` — opaque to screen readers |
| Strings stub | `.ai/fixtures/MAS-04-B-FIX-ALL/strings-stub.json` | `confirm.delete.title` / `confirm.delete.body` provide informed-delete copy (`"This action cannot be undone."` / DE equivalent) — **not referenced by UI stub** |
| Locale declaration | strings-stub `meta` | `supportedLocales: ["en", "de"]` — EU market plausible; GDPR applies to EU data subjects |
| Remove label strings | `button.remove` | Present `en`/`de`; suitable for button text or `aria-label` once wired |
| A11y cross-brief | `.ai/context/a11y-reviews/MAS-04-B-FIX-ALL.md` | P0 finding: missing accessible name — overlaps Art. 12 transparency gap |
| i18n cross-brief | `.ai/context/i18n-reviews/MAS-04-B-FIX-ALL.md` | Confirm strings extracted but unwired; `button.remove` not context-complete for a11y |
| Architecture / RoPA / privacy policy | not in fixture scope | No production policy artifacts reviewed |
| Backend delete API / audit logs | not in fixture scope | No server-side erasure evidence |

## Remediation

| # | Gap | Action | Priority | HITL required |
|---|-----|--------|----------|---------------|
| 1 | Unconfirmed delete (Art. 17, 25) | Wire `confirm.delete.title` / `confirm.delete.body` into a confirmation modal or dialog before `handleRemove` executes; require explicit user affirmation | P0 | no (dev) |
| 2 | Opaque delete control (Art. 12) | Add `aria-label` using localized string (e.g. `button.remove` with item context or dedicated `button.remove.item` key); align with a11y brief | P0 | no (dev) |
| 3 | Erasure completeness (Art. 17) | Implement server-side delete endpoint; document cascade to replicas/backups; return success/failure to UI | P1 | yes (legal review erasure scope) |
| 4 | Retention (Art. 5(1)(e)) | Define and document retention period for tasks and deleted-item grace period; publish in privacy notice | P1 | yes (legal) |
| 5 | Lawful basis (Art. 6) | Document lawful basis for task processing (e.g. contract Art. 6(1)(b) for SaaS task manager); do not assume consent | P1 | yes (legal) |
| 6 | Transparency at collection (Art. 13) | Surface privacy notice link and purpose at onboarding or settings; include deletion rights summary | P1 | yes (legal) |
| 7 | Secure processing (Art. 32) | Require authenticated session for delete; log deletion events (user ID, item ID, timestamp) without logging item content; use HTTPS | P1 | no (dev) / yes (legal for log retention) |
| 8 | RoPA (Art. 30) | Add processing activity for task storage/deletion to RoPA | P2 | yes (legal) |
| 9 | Data inventory (Art. 5(1)(c)) | Enumerate task fields; flag any special-category data and trigger DPIA if needed | P2 | yes (legal) |
| 10 | Localized erasure UX | Ensure confirmation dialog and accessible name use same locale pipeline as `strings-stub.json` | P2 | no (dev) |

### Recommended implementation sequence (engineering)

1. **P0 — Confirm before erase:** Modal with `confirm.delete.title` + `confirm.delete.body`; destructive action only on explicit confirm.
2. **P0 — Name the control:** `aria-label={t('button.remove.item', { name: itemTitle })}` or equivalent.
3. **P1 — Server-side erasure:** DELETE API with authz; document backup purge SLA.
4. **P1 — Legal artifacts:** Lawful basis, privacy notice, retention policy — legal HITL before prod.

## Compliance posture

| Dimension | Status |
|-----------|--------|
| Overall readiness | **NOT READY** — P0 gaps in delete confirmation and transparency |
| Auto-approve | **NO** — advisory only; human legal review required |
| Certification | **NONE** — this brief is not regulatory sign-off |
| Reviewer gate | Findings feed reviewer step 0i; sole `Approved:` authority remains reviewer |

## Not legal advice

This brief is an **engineering evidence audit only** — not legal counsel, certification, regulatory sign-off, or a determination that the described UI complies with GDPR. Clause mapping is illustrative and based on fixture artifacts within scope; it does not replace a formal legal review, Data Protection Impact Assessment, or consultation with qualified privacy counsel. Legal and production remediation (lawful basis, privacy notices, RoPA, DPA terms, breach procedures, cross-border transfers) require **human review (HITL)** before any compliance claim. The compliance agent does not auto-approve, certify readiness, or issue an independent `Approved:` verdict.

## Brief Path

`.ai/context/compliance/MAS-04-B-FIX-ALL.md`

## Usage Report

Model: inherit (default)  
Class: thinking  
Tokens: unknown
