# Risk Register

Active risks, their severity, mitigation status, and owner. Severity is **P0** (ship-blocking / data loss / legal exposure), **P1** (major, fix this sprint), **P2** (moderate, fix next sprint), **P3** (minor, backlog).

---

## RISK-01 — Persistence corruption blocks startup

**Severity:** P0 → **RESOLVED**
**Owner:** Tech Lead
**Mitigation:** `SafeStore` per-record decoding + quarantine (ADR-001).

One malformed record during `load()` used to prevent the app from starting. Now the app boots with whatever it can parse and quarantines the rest. Covered by `test/resilience_test.dart`.

---

## RISK-02 — Timer drift on app resume

**Severity:** P1
**Owner:** Tech Lead
**Mitigation:** Not yet implemented.

`FocusProvider` relies on an active `Timer.periodic`. On mobile OS, backgrounding or screen lock suspends isolates. Upon resume, the timer display drifts unless wall-clock deltas (`DateTime.now()` vs `endsAt`) are enforced.

**Recommended fix:** On app resume, recompute remaining time from `endsAt - DateTime.now()` rather than trusting accumulated tick counts.

---

## RISK-03 — Billing for vapourware

**Severity:** P0 → **RESOLVED**
**Owner:** Chief Architect
**Mitigation:** `FeatureFlags` maturity system + `isBillable` gate (ADR-002).

Paywall previously advertised features that did not exist. Now non-billable features are free for everyone, and the paywall sheet advertises only `live` features.

---

## RISK-04 — Unclear paywall boundaries

**Severity:** P0 → **RESOLVED**
**Owner:** Chief Architect
**Mitigation:** Honest monetization governance (ADR-004).

All vapourware purged from paywall copy. Soft task cap wired. Trial tracking added.

---

## RISK-05 — No crash reporting

**Severity:** P1
**Owner:** Tech Lead
**Mitigation:** Not yet implemented.

No sink is attached in release, so nothing reaches a dashboard. Without it, RISK-01 recurrences will be invisible in the field.

**Recommended fix:** Attach a crash-reporting sink (Sentry/Crashlytics) via `AnalyticsService.addSink()`. The seam exists.

---

## RISK-06 — HomeScreen choice overload

**Severity:** P0 → **MITIGATED**
**Owner:** Design Lead
**Mitigation:** Design audit identified 24 visible action choices on HomeScreen (Rule 1: max 3). Streamlining in progress.

The single biggest threat to the product working as designed: an audience whose core pathology is decision paralysis is being presented with 24 choices.

---

## RISK-07 — Naive Rule-15 validator

**Severity:** P1
**Owner:** QA Lead
**Mitigation:** Documented exceptions in `test/design_rules_test.dart`.

`RsdSafeCopy.isSafe()` uses substring matching, which flags negation contexts ("You're not lazy") and technical phrases ("broken down"). The validator needs word-boundary + negation-aware matching to stop producing false positives.

---

## RISK-08 — No real analytics sink

**Severity:** P2
**Owner:** Growth Lead
**Mitigation:** Not yet implemented.

All instrumentation is local-only. No funnel data reaches a dashboard until a sink is wired. The `AnalyticsService.addSink()` seam exists and accepts any vendor SDK.
