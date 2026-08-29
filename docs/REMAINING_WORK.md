# Remaining Work — needs a real toolchain or owner action

**Generated:** 2026-08-26, at the close of the Gap Solutions
implementation. Everything below is work that could NOT be honestly
completed from this sandbox (no Flutter SDK, no pub.dev egress, no
devices) or needs the owner's hand. Everything else is done — see
`docs/audits/gap-solutions-closure-audit.md`.

## Owner actions (minutes, no code)

1. **Activate CI** — token lacks `workflows` scope; 30-second manual
   step documented in `ci/README.md`. First green run retires the
   `docs/Engineering_Assessment.md` §6 "never executed" caveat and is
   the real gate for every statically-verified change in this phase.
2. **PostHog project + key** — free tier; paste key into
   `lib/config/observability_config.dart` (`observabilityConfig`
   section). Empty key = fully offline build, by design.
3. **CI red-word/print/format gates** will surface anything the static
   pass couldn't type-check; fix-forward expected on first run (member
   signatures were paper-traced, not compiled).
4. **Pilot launch** — recruit per `docs/pilot-protocol.md` (pre-registered).

## Needs a Flutter toolchain (owner or next agent with CI/dev machine)

5. **First `flutter test` execution** of the full suite, especially:
   `decomposition_test.dart`, `retention_test.dart`,
   `gentle_block_test.dart`, `observability_test.dart`,
   `voice_dump_parser_test.dart` (all written, none ever executed).
6. **`dart format .` + `flutter analyze --fatal-infos`** pass — python
   splices were indentation-checked by eye; formatter is the arbiter.
7. **Assets check**: `pubspec.yaml` now declares `assets/templates/`
   — verify the bundle actually includes it on first build.
8. **whisper voice dump (WI-2.1 V2)** — `voice_dump_parser.dart` core
   is done; the speech-to-text path (whisper_ggml first-run download)
   is specced in `docs/briefs/voice-yap-mode-brief.md`, est. 3–5 days.

## Needs native/device work (specs are written)

9. **Gentle Block Android** — accessibility service + MethodChannel
   onto the built `GentleBlockGate`/`CalmPauseScreen`;
   `docs/briefs/gentle-block-build-spec.md`, est. 1.5–2 days + device
   matrix. Then flip `FeatureFlags.gentleBlock`.
10. **Widgets (WI-5.2)** — `home_widget` bridge per
    `docs/briefs/widgets-build-spec.md`, est. 2–3 days (iOS needs
    Xcode widget extension). Then flip `FeatureFlags.widgets`.

## Needs owner decisions (briefs are written)

11. **Pricing** — confirm $5.99/mo–$49/yr + 7-day trial per
    `docs/briefs/pricing-decision-brief.md`, then RevenueCat wiring
    (3–4 days, only startTrial/purchase seams).
12. **Focus Caves** — if ever built, follow the ADR-006 rebuild
    checklist (moderation spec FIRST); dormant risks RISK-12/13.

## Deferred by design

13. Native crash symbolication (Sentry recommended —
    `docs/briefs/observability-vendor-brief.md`, RISK-10).
14. iOS Screen Time API track (RISK-14; Gentle Block iOS V1 = Focus
    mode + guide flow only).
15. Pilot results doc `docs/audits/pilot-results.md` — written only
    after the 4-week run.
