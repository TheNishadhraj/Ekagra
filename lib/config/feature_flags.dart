/// Runtime feature maturity gates.
///
/// WHY THIS FILE EXISTS
/// --------------------
/// Ekagra ships UI for features whose backends do not exist yet. That is a
/// normal and healthy way to build — you validate the interaction before you
/// pay for the infrastructure. It becomes a serious problem in exactly one
/// situation: **when you charge money for it.**
///
/// Selling a subscription whose advertised benefit is a hardcoded number is
/// not a rough edge, it is a misrepresentation. In the EU it engages the
/// Unfair Commercial Practices Directive; in the US, FTC Act §5; and both
/// Apple (App Review 3.1.2) and Google (Subscriptions policy) will pull a
/// paid app over it. The financial downside is not a refund queue, it is
/// removal from the stores.
///
/// So maturity is encoded here, in one auditable place, and the paywall
/// reads from it. A feature cannot be monetised until it is [live].
library;

/// How real a feature actually is right now.
enum FeatureMaturity {
  /// Fully implemented against a real backend. Safe to charge for.
  live,

  /// UI works, data is simulated or local-only. Usable, honestly labelled,
  /// and **never** billable.
  simulated,

  /// Not built. Should not be reachable in the UI at all.
  unbuilt,
}

/// Single source of truth for what is actually finished.
///
/// Keep this brutally honest. The entire value of the file is that it does
/// not flatter the roadmap — an optimistic entry here converts directly into
/// a store takedown or a chargeback.
class FeatureFlags {
  FeatureFlags._();

  /// Body doubling ("Focus Caves"): NOT BUILT — cut by ADR-006 with the
  /// Phase-4 decision gate. There is no room, no backend, no presence
  /// data, and the simulated screen was removed rather than left to
  /// imply otherwise. Rebuild checklist (moderation spec first, LiveKit
  /// self-host vs Cloud decision, avatar-first presence, room caps, no
  /// DMs in V1) lives in ADR-006 + RISK-12/13. Stays `unbuilt` — and
  /// therefore non-billable — until a real room works end-to-end.
  static const bodyDoubling = FeatureMaturity.unbuilt;

  /// "AI" task selection is a deterministic local scoring function in
  /// `AiService._score`. It is genuinely useful and it is genuinely not AI.
  /// The spec calls for GPT-4o-mini; there is no HTTP client in pubspec.
  static const aiTaskSelection = FeatureMaturity.simulated;

  /// LIVE since WI-3.1: the Pro-gated "Task breakdown" is now the real
  /// local decomposer (see taskDecomposition). The flag keeps its
  /// historical name so the paywall matrix is unchanged; the honest
  /// label ("smart, on-device") stays.
  static const aiTaskBreakdown = FeatureMaturity.live;

  /// Not implemented on either platform.
  static const widgets = FeatureMaturity.unbuilt;

  /// LIVE since the K18 fix (2026-08-26): "Export My Data" serializes
  /// tasks, rewards, energy/mood logs and profile to a real JSON file in
  /// the app documents directory (plus a tasks CSV) and hands it to the OS
  /// share sheet. Still local-only: no cloud sync, no cross-device
  /// continuity — and none claimed. Round-trip coverage lives in
  /// test/export_test.dart.
  static const dataExport = FeatureMaturity.live;

  /// LIVE since WI-3.1 (2026-08-26): local task decomposition + one-step
  /// execution mode. 32 template families x 3 spiciness levels as data
  /// (assets/templates/task_breakdown_templates.json), generic 2-minute-
  /// rule fallback, quick-tier micro-ticks per step. No network, no
  /// model, honestly labelled ("built from patterns, runs on your phone").
  static const taskDecomposition = FeatureMaturity.live;

  /// WI-5.3 anti-novelty-decay program: active-days milestones (7/30/100),
  /// hyperfocus celebrations, monthly dopamine-menu refresh suggestions,
  /// weekly nudge-copy rotation (shipped with WI-1.4). All local, all real
  /// — `live`. Every celebration string is Rule-15 tested.
  static const retentionProgram = FeatureMaturity.live;

  /// Voice "yap mode": NOT BUILT, and no UI implies otherwise. The old
  /// Brain Dump mic button used to *simulate* listening for 2 seconds and
  /// insert a hardcoded item — removed 2026-08-26 as a K18-class honesty
  /// bug. What IS real today: the on-device transcript parser
  /// (`VoiceDumpParser`, "Smart split") which turns any typed or pasted
  /// dump into dated task cards. The whisper.cpp binding (first-run model
  /// download) is deferred — docs/briefs/voice-yap-mode-brief.md.
  static const voiceDump = FeatureMaturity.unbuilt;

  /// LIVE since WI-1.4 (2026-08-26): real local notifications via
  /// flutter_local_notifications — per-task gentle nudge sequence (max 3,
  /// then stops silently), one optional daily brief, one welcome-back
  /// nudge after a 3-day gap, and a 15-min-left focus transition alert.
  /// Local scheduling only; no push service, no backend, opt-out stops all.
  static const nudges = FeatureMaturity.live;

  /// These are real, local-first, and work exactly as advertised.
  static const unlimitedTasks = FeatureMaturity.live;
  static const allFocusDurations = FeatureMaturity.live;
  static const unlimitedDopamineMenu = FeatureMaturity.live;
  static const allAmbientSounds = FeatureMaturity.live;
  static const energyMoodInsights = FeatureMaturity.live;
  static const customThemes = FeatureMaturity.live;
  static const detailedStats = FeatureMaturity.live;

  /// Honest, non-apologetic label for a simulated feature. Shown in the UI
  /// so the user knows what they are looking at before they rely on it.
  static const simulatedNotice =
      'Preview — this is a solo simulation for now. '
      'Real shared rooms are coming, and you will never be charged for the preview.';

  static const aiNotice =
      'Runs entirely on your device — no cloud, no data leaves your phone.';
}
