# Decision brief — Observability vendor (WI-2.3)

**Status:** owner decision pending · **Prepared:** 2026-08-26
**What already works without the decision:** dependency-free `RemoteAnalyticsSink`
(PostHog capture-compatible batch API) + `CrashReporter` on the existing
`AnalyticsService` seam — opt-out honoured, PII scrubbed, offline by default.

## The choice

| Need | PostHog (recommended) | Plausible Mobile |
|---|---|---|
| Event analytics + funnels/retention | First-class (the pilot's D1/D7/D30 dashboards are 10 minutes of work) | Lightweight; funnels thinner |
| Flutter SDK | Available — **not used** (HTTP sink instead) | Available |
| Free tier | 1M events/mo | 10k pageviews/mo (event fit weaker) |
| Self-host option | Yes (posts to your own instance later without app changes) | Yes |

**Crash reporting residue (RISK-10):** today's capture is framework-level
(`FlutterError` + `PlatformDispatcher` + zones → `Ev.errorOccurred`). For
native crashes + symbolication, add **Sentry** (free 5k errors/mo,
first-party Dart SDK, self-host option) or **Crashlytics** (free, but
Firebase-shaped and no self-host). Both slot in beside the existing bus.

## Owner actions (2 minutes each, both free)

1. **Analytics:** create the PostHog project → paste the key into
   `lib/config/observability_config.dart` (`apiKey`), pick `endpoint`
   (us/eu/self-host). Done — the sink attaches at next boot.
2. **Crash:** decide Sentry vs Crashlytics (brief above recommends Sentry
   for its self-host path); wiring is a one-file PR plus `main()` init.

## Guardrails already enforced by test (`test/observability_test.dart`)

- Zero remote events after opt-out; local buffer cleared.
- No PII-shaped property key in any shipped payload.
- Sink inert while unconfigured → default build stays fully offline.
- Framework and zone errors reach `Ev.errorOccurred`.
