# ⚠️ EKAGRA — RISK REGISTER

This register tracks identified architectural, technical, product, and compliance risks, their potential severity, mitigation strategy, and designated owner.

---

## Active Risk Register

| Risk ID | Risk Description | Severity | Impact Area | Mitigation Strategy | Owner | Status |
|---|---|---|---|---|---|---|
| **RISK-01** | **Persistence Payload Corruption on Sudden Exit**<br>Rapid `_persist()` calls using `jsonEncode` with `SharedPreferences` can lose data or crash on load if corrupted. | **HIGH** | Data Integrity / Retention | Implemented defensive `try-catch` wrappers across all providers and crash-proof `TaskModel.fromJson` fallbacks. Verified via `test/resilience/task_provider_persistence_test.dart`. | Chief Architect | **RESOLVED** |
| **RISK-02** | **Timer Drift & Background Freeze on Mobile OS**<br>Dart isolate timers suspend when app is backgrounded or device locks, causing incorrect countdowns on resume. | **HIGH** | User Focus Experience | Refactor `FocusProvider` remaining time calculation to rely strictly on wall-clock time deltas (`DateTime.now()` vs `endsAt`). | QA / Engineering | **Mitigating** |
| **RISK-03** | **Rule-15 Compliance Regression in Copy/UI**<br>New screens or error messages may accidentally introduce shame words ("streak", "overdue", "failed") or harsh red UI colors. | **MEDIUM** | RSD Safety / UX | Integrated static source scanner (`test/rules/rule_15_copy_compliance_test.dart`) enforcing Rule 15 across all `lib/` string literals. | QA & UX Specialist | **RESOLVED** |
| **RISK-04** | **Unclear Paywall Boundaries for Simulated Features**<br>Gating simulated or partially built features behind a paywall violates Boundary 4 ("Do not bill for vapourware"). | **HIGH** | Product Strategy / Trust | Purged all vapourware claims from `EkagraPaywallSheet` and `PaywallScreen`. Advertised features strictly reflect shipped V1.0 capabilities. | Chief Architect / Growth | **RESOLVED** |
| **RISK-05** | **Lack of Test Coverage Leading to Silent Regressions**<br>Only 1 widget test existed in repo. Refactoring core engines could break offline AI scoring or variable reward distribution. | **HIGH** | System Quality | Created 7 automated test suites across `test/unit/`, `test/resilience/`, `test/rules/`, and `test/helpers/`. | QA Specialist | **RESOLVED** |

---

## Risk Severity Definitions
- **CRITICAL:** Causes total data loss, startup crashes, or illegal monetization/billing practices.
- **HIGH:** Degrades core user loop (timer, task persistence, RSD safety violation).
- **MEDIUM:** Secondary feature friction or minor visual inconsistency.
- **LOW:** Micro-interaction polish or cosmetic issue.
