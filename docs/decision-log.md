# 📜 EKAGRA — ARCHITECTURAL DECISION LOG

This document serves as the single source of truth for architectural decisions, technical trade-offs, system invariants, and product boundary choices for **Ekagra**.

---

## Decision Log Structure
Entries follow an immutable sequential log format:
- **ID & Title**
- **Date & Status** (Proposed / Approved / Deprecated)
- **Reversibility** (Reversible [Two-Way Door] / Irreversible [One-Way Door])
- **Context & Problem Statement**
- **Options Considered & Trade-offs**
- **Decision & Rationale**
- **Consequences & System Impacts**

---

## [ADR-001] System Onboarding, Architectural Assessment & Master Strategic Roadmap

- **Status:** Approved
- **Date:** 2026-08-10
- **Author:** Chief Architect
- **Reversibility:** Irreversible (Sets foundational engineering priority and execution boundaries)

### Context & Problem Statement
The human product owner requested a comprehensive initial system assessment of Ekagra following the consolidation of the **Ekagra Unified Final Specification** and the current baseline codebase. The goal is to establish system health, identify hidden technical risks, formalize system invariants, and define an actionable roadmap.

---

## [ADR-002] Defensive Persistence Hardening, Test Suite Integration & Rule-15 Automated Enforcement

- **Status:** Approved
- **Date:** 2026-08-10
- **Author:** Chief Architect
- **Reversibility:** Reversible (Internal persistence and testing architecture)

### Context & Problem Statement
The QA & Resilience Specialist completed a quality audit and identified a critical vulnerability: `TaskProvider.load()` and other providers deserialized JSON without `try-catch` blocks or defensive deserialization fallbacks in `TaskModel.fromJson`. Corrupted storage strings, torn writes, or missing fields caused uncaught startup exceptions, bricking launch. Furthermore, zero unit tests covered `AiService`, `RewardEngine`, or Rule-15 copy compliance.

### Decision & Rationale
1. **Defensive Deserialization Hardening:** Refactored `TaskModel.fromJson` to defensively parse dates, enums, numbers, and strings with safe fallbacks. Wrapped `load()` and `_persist()` in all providers in `try-catch` blocks.
2. **Comprehensive Automated Testing:** Created 7 automated test suites across `test/unit/`, `test/resilience/`, `test/rules/`, and `test/helpers/`.

---

## [ADR-003] Rule-15 Choice Architecture Streamlining & Paywall Trust Copy Remediation

- **Status:** Approved
- **Date:** 2026-08-10
- **Author:** Chief Architect
- **Reversibility:** Reversible (UI choice architecture and copy alignment)

### Context & Problem Statement
The Design & UX Specialist completed an interaction and Rule-15 audit, flagging choice overload on `HomeScreen` (24+ choices) and `BrainDumpScreen` (19 template chips), as well as an inaccurate cancellation claim on `EkagraPaywallSheet` (*"Cancel anytime in Settings with 1 tap"*).

### Decision & Rationale
1. **HomeScreen Choice Streamlining (Rule 1 Compliance):** Structured `HomeScreen` into 3 primary choice paths: (1) Your One Thing Card, (2) Brain Dump Floating Action, and (3) Collapsible Check-in Bar.
2. **BrainDump Template Limitation (Rule 1 Compliance):** Limited empty-state prompt chips to 3 featured primary templates with an expandable toggle.
3. **Paywall Cancellation Copy Truthfulness:** Updated cancellation copy across `EkagraPaywallSheet` and `PaywallScreen` to truthful, RSD-safe language (*"Cancel anytime in device Settings > Subscriptions"*).

---

## [ADR-004] Honest Monetization Governance, Soft Task Cap Enforcement, and Vapourware Elimination

- **Status:** Approved
- **Date:** 2026-08-10
- **Author:** Chief Architect
- **Reversibility:** Irreversible (Enforces Chief Architect Boundary 4 & Rule 14)

### Context & Problem Statement
The Growth & Monetization Specialist audited paywall claims and conversion loops, revealing that non-existent features ("Widgets & Dyslexia fonts", "127 live co-working room users") were advertised on `EkagraPaywallSheet`, violating **Chief Architect Boundary 4** ("Do not bill for vapourware"). Furthermore, `TaskProvider.atFreeTaskLimit` was unenforced in UI flows and Pro trial start timestamps were untracked.

### Decision & Rationale
1. **Vapourware Elimination (Boundary 4 & Rule 14 Compliance):** Purged all non-existent feature claims from `EkagraPaywallSheet` and `PaywallScreen`. Paywall copy now advertises ONLY features that exist in V1.0 (Unlimited tasks, offline AI task selection, dopamine menu customization, ambient sounds).
2. **Soft Task Cap Governor Wiring:** Enforced `TaskProvider.atFreeTaskLimit` as a soft, RSD-safe prompt on task #11 addition in `BrainDumpScreen`, displaying `EkagraPaywallSheet.show(context)` without brickwalling or locking data.
3. **Honest Local Trial Tracking:** Added `trialStartedAt`, `isTrialActive`, and `trialDaysRemaining` getters to `UserModel` and `SettingsProvider` for local trial calculation.
