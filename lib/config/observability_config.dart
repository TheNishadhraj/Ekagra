/// Remote observability configuration (WI-2.3).
///
/// The design constraint: the analytics bus (`AnalyticsService`) is
/// deliberately dependency-free — vendors attach as sinks. This config is
/// the ONLY place a remote destination is named, and an **empty key means
/// the remote sink is inert**: nothing leaves the device, everything still
/// lands in the local buffer. That keeps the default build fully offline.
///
/// Owner setup (free tier, ~2 minutes — see
/// docs/briefs/observability-vendor-brief.md for the vendor comparison):
/// 1. Create a PostHog project (or point [endpoint] at any capture-API
///    compatible service).
/// 2. Paste the project API key into [apiKey].
/// 3. Nothing else — the sink attaches in `main()` when the key is set.
class ObservabilityConfig {
  ObservabilityConfig._();

  /// PostHog batch capture endpoint. EU projects should use
  /// https://eu.i.posthog.com/batch/
  static const String endpoint = 'https://us.i.posthog.com/batch/';

  /// Empty = remote sink inert (fully offline build). Fill from your
  /// project settings once the vendor decision is made.
  static const String apiKey = '';

  /// Crash reporting routes through the same analytics bus
  /// (`Ev.errorOccurred`), so it honours the same in-app opt-out and the
  /// same PII scrubbing. With no remote key, crashes are still recorded in
  /// the local buffer for diagnostics-on-next-open.
  static const bool crashReportingEnabled = true;
}
