# Risk Register

Active risks, their severity, mitigation status, and owner. Severity is **P0** (ship-blocking / data loss / legal exposure), **P1** (major, fix this sprint), **P2** (moderate, fix next sprint), **P3** (minor, backlog).

---

## RISK-01 — Persistence corruption blocks startup

**Severity:** P0 → **RESOLVED**
**Owner:** Tech Lead
**Mitigation:** `SafeStore` per-record decoding + quarantine (ADR-001).

One malformed record during `load()` used to prevent the app from starting. Now the app boots with whatever it can parse and quarantines the rest. Covered by `test/resilience_test.dart`.

---

## RISK-02 — Focus minutes lost on process kill (supersedes the original "timer drift" entry)

**Severity:** P1 → **RESOLVED** (2026-08-26, WI-1.2 / ADR-005)
**Owner:** Tech Lead

*2026-08-26 hygiene note:* the original entry claimed timer drift was
unmitigated. That was stale: `FocusSession.remaining()` in
`focus_session_model.dart` has always computed remaining time from the wall
clock (`endsAt - now`), so display drift after backgrounding cannot occur by
construction. The real gap (registered as K20 in the Gap Solutions research)
was that the in-flight session and `_todayFocusMinutes` lived only in
memory: an OS kill silently discarded the session, the day's minutes, and
the reward. That is now RISK-09, fixed by session reconciliation on boot.

---

## RISK-03 — Billing for vapourware

**Severity:** P0 → **RESOLVED**

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

---

## RISK-09 — Focus session lost on process kill (K20)

**Severity:** P1 → **RESOLVED** (2026-08-26, WI-1.2 / ADR-005)
**Owner:** Tech Lead

`FocusProvider` kept the in-flight `FocusSession` and the day's focus
minutes in memory only. ADHD usage patterns (force-quits, OS memory
pressure, battery death) made silent loss a routine event, not an edge
case.

**Mitigation (landed):** session + minutes persisted on every state
transition; on boot `FocusProvider.reconcile()` either resumes the session
against the wall clock or retro-completes it exactly once (idempotent
reward). Covered by `test/resilience/focus_session_persistence_test.dart`.

---

## RISK-10 — No crash reporting (K-ref RISK-05 twin)

**Severity:** P1 → **MITIGATED** (2026-08-26, WI-2.3)
**Owner:** Tech Lead

**Mitigation:** `CrashReporter` routes `FlutterError`, `PlatformDispatcher`
errors and zoned exceptions into `AnalyticsService` (`Ev.errorOccurred`),
which respects the in-app opt-out and feeds the remote sink when configured.
Open residue: no vendor SDK with native crash capture (symbolication,
out-of-heap crashes) until the owner picks a provider — see
`docs/briefs/observability-vendor-brief.md`.

---

## RISK-11 — No analytics sink (was RISK-08)

**Severity:** P2 → **MITIGATED** (2026-08-26, WI-2.3)
**Owner:** Growth Lead

**Mitigation:** `RemoteAnalyticsSink` (dependency-free HTTP, PostHog
capture-compatible) attaches to the existing `AnalyticsService.addSink()`
seam; inert until an endpoint+key are configured in
`lib/config/observability_config.dart`; PII-scrubbed and opt-out-honouring
by test. Residue: owner must create the (free) project and fill the key.

---

## RISK-12 — Focus Caves moderation & abuse surface (pre-registered)

**Severity:** P2 (P1 the day rooms go live)
**Owner:** Product Owner

Registered with the Phase-4 cut (ADR-006). If/when real body-doubling
rooms are built, the moderation spec must land **before** code: ToS,
in-room report flow to a human review queue, avatar mode, join rate
limits, and no DMs in V1. Until then this risk is dormant by construction
— there is no social surface at all.

---

## RISK-13 — Focus Caves presence/infra cost (pre-registered)

**Severity:** P3 (dormant)
**Owner:** Product Owner

LiveKit self-host (~$60–200/mo at ~200 concurrent) or Cloud (~$50/mo)
plus moderation labour. Dormant after the Phase-4 cut; re-open with
ADR-006's rebuild checklist before any build commit.

---

## RISK-14 — iOS Screen Time API approval for Gentle Block

**Severity:** P2
**Owner:** Product Owner

iOS self-blocking (FamilyControls/ManagedSettings/DeviceActivity) requires
Apple's Screen Time API approval with no guaranteed timeline. V1 ships the
honest subset (custom Focus mode + a "Guide me to Screen Time" deep-link
flow, honestly labelled). If approval never lands, iOS stays on that
subset and the Android Accessibility-Service path carries the feature.
Build spec: `docs/briefs/gentle-block-build-spec.md`.

---

## RISK-15 — Gap-solutions code statically verified, not suite-executed

**Severity:** P1 (temporary)
**Owner:** Tech Lead

The 2026-08-26 implementation environment had no Dart toolchain and no
pub.dev egress, so every WI landing that day was verified statically
(`tools/static_verify.py` + review), not with `flutter analyze/test`.
First CI run (blocked on the one manual workflow move — `ci/README.md`)
must be treated as the real gate; fix forward, never weaken the gates.

---

## RISK-16 — Local notifications degrade without exact alarms / boot

**Severity:** P3
**Owner:** Tech Lead

The nudge engine (WI-1.4) schedules inexact alarms by design (gentle, no
precision promise) and does not reschedule after device reboot in V0.
Impact: nudges may drift minutes late and disappear after a reboot until
the next app open. Documented rather than fixed — exact alarms need
`SCHEDULE_EXACT_ALARM` user grants (a permission wall), and a boot
receiver adds manifest surface; revisit with on-device evidence.

---

## RISK-17 — Decomposition template drift & reward double-fire (ADR-007)

**Severity:** P3
**Owner:** Product Owner

`task_breakdown_templates.json` is owner-tunable data; a hand-edit could
break spiciness bounds (3–5/6–10/11–20) or introduce shame-language
steps. Both are machine-enforced by tests, which only run in CI —
until the owner activates CI, edits should be followed by a local
`flutter test`. Reward double-fire from the new step path is guarded by
an idempotent `completeTask` (asserted exactly-once in
`decomposition_test`); the residual is a same-second double-tap racing
two `updateTask` writes — acceptable at single-device scale.

---

## RISK-18 — Milestone double-celebration / growth-key drift (ADR-010)

**Severity:** P3
**Owner:** Product Owner

`celebratedMilestones` is additive to the growth JSON; a hand-edited or
partially-written blob could theoretically re-celebrate a milestone
(decode falls back to `[]`). Impact is one extra kind sheet — no data
loss, no charge. Fire-once-per-milestone and legacy decode are
test-enforced (`retention_test.dart`). The clock-dependent arming test
seeds a fixed past date, so it is stable on any CI runner date.
