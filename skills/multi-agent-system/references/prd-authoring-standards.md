# Product Requirements Document (PRD) Authoring Standards

Reference standards for [mas-pm](../../mas-pm/SKILL.md), [mas-brainstorm](../../mas-brainstorm/SKILL.md), [mas-planner](../../mas-planner/SKILL.md), [mas-architect](../../mas-architect/SKILL.md), and [mas-reviewer](../../mas-reviewer/SKILL.md) (Step 0m).

---

## 1. Mission & Role Invariants

The Product Requirements Document (PRD) emitted by `mas-pm` is the single source of truth for downstream planning, architecture, implementation, and review verification.
- **Ambiguity Reduction**: The PM specialist translates ambiguous user goals into concrete, verifiable product capabilities.
- **Strict Scope Boundaries**: Explicitly separates MVP P0 must-haves from deferred P1/P2 features. Downstream agents are strictly locked to MVP P0 scope.
- **Verification Traceability**: Every functional requirement is stated as a Gherkin scenario that can be directly mapped to automated unit/integration tests and Reviewer audit step 0m.

---

## 2. Document Structure & Required Headings

PRDs are authored at `.ai/context/prds/{TASK_ID}.md` and must contain the following six mandatory markdown sections per [brief-schemas.md](../protocol/brief-schemas.md):

1. `## Problem Statement & Value Proposition`
2. `## Target Personas & User Journeys`
3. `## Functional Requirements & User Stories`
4. `## Non-Functional Requirements`
5. `## Scope & Out-of-Scope Boundaries`
6. `## Success Metrics & KPIs`

---

## 3. Persona Definition & Journey Mapping

### Persona Profile Template
Every PRD must identify at least one Primary Persona and optionally a Secondary Persona:
- **Role & Background**: Technical proficiency, primary devices/platforms, frequency of usage.
- **Core Friction**: Unmet need or bottleneck in the current workflow.
- **Desired Outcome**: Measurable objective the user seeks to accomplish.

### User Journey Map
Map the end-to-end user interaction across four explicit phases:
1. **Discovery & Onboarding**: Initial entry point, permission requests, empty state presentation.
2. **Core Workflow (Happy Path)**: The primary sequence of actions to achieve the user goal.
3. **Edge Cases & Error States**: Network disconnection, validation errors, quota limits, cancellation.
4. **Recovery & Continuity**: Offline queue sync, state restoration, re-authentication.

---

## 4. Gherkin User Story Standards

Functional requirements must be written as discrete User Stories accompanied by acceptance criteria in standard Gherkin syntax (`Scenario:`, `Given`, `When`, `Then`, `And`).

### Format Contract

```gherkin
Feature: <Feature Name>
  As a <persona>
  I want to <action/capability>
  So that <benefit/value>

  Scenario: <Scenario Title — Happy Path>
    Given the user is authenticated and has an active internet connection
    And their account balance is greater than $50
    When the user submits a transfer request of $25 to recipient "alice@example.com"
    Then the system debits $25 from the user's account
    And records an immutable ledger transaction with status "COMPLETED"
    And displays a confirmation receipt with transaction ID within 500ms

  Scenario: <Scenario Title — Edge Case / Insufficient Funds>
    Given the user is authenticated
    And their account balance is $10
    When the user attempts to transfer $25
    Then the system halts the transaction
    And displays an inline error "Insufficient funds: balance is $10.00"
    And emits an analytics event "transfer_failed_insufficient_funds"
```

### Story Splitting Rules
- Each user story must represent an independently testable slice of user value.
- Scenarios must test observable system behavior, not internal implementation details (e.g. test "displays error message", not "calls ViewModel.onError()").

---

## 5. Non-Functional Requirements (NFRs)

Every PRD must define explicit, measurable performance, availability, accessibility, and security budgets:

| Dimension | Standard Ceiling / Threshold | Verification Method |
|-----------|------------------------------|---------------------|
| **Response Latency** | p95 $\le 200\text{ ms}$ for local DB reads; p95 $\le 1000\text{ ms}$ for network API calls | Benchmark / Profiler |
| **App Cold Start** | Android cold start to interactive $\le 1500\text{ ms}$ | Macrobenchmark |
| **Frame Rate** | 60 fps (no dropped frames $> 16\text{ ms}$) on lists and animations | Frame timing metrics |
| **Offline Resilience** | Full read access to cached data; mutations queued locally in Room/SQLite | Disconnect network test |
| **Accessibility** | Full WCAG 2.1 AA compliance; min touch target $48\times 48\text{ dp}$; dynamic font scaling | TalkBack / Accessibility Scanner |
| **Data Privacy** | Zero PII or API tokens in logcat, bug reports, or client analytics | Device log inspection |

---

## 6. Scope & Boundary Enforcement

To prevent scope creep across multi-agent workflows, the PRD must draw an unambiguous boundary:

### In-Scope (MVP P0)
- Explicit bulleted list of mandatory features required to solve the core problem statement.
- Only items listed in MVP P0 may be planned by `mas-planner` or coded by dev specialists.

### Out-of-Scope (Deferred P1/P2)
- Explicit list of features, platforms, or enhancements deliberately excluded from the current task.
- Example: "Third-party payment gateways (Stripe/PayPal) are deferred to Phase 2; MVP supports internal balance only."

---

## 7. Success Metrics & Telemetry Events

Define quantifiable KPIs and analytics telemetry:
- **Primary KPI**: The single metric proving value delivery (e.g. "Task completion rate increases from 65% to $\ge 88\%$").
- **Guardrail Metric**: The metric that must not regress (e.g. "Crash-free sessions remain $\ge 99.9\%$").
- **Telemetry Event Contract**: Table of event names, triggers, and payload parameters required for telemetry instrumentation.
