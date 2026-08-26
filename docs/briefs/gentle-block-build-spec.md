# Gentle Block — Build Spec (WI-5.1, platform-honest)

**Status:** spec + inert Dart components. `FeatureFlags.gentleBlock =
unbuilt`. Nothing here is reachable in the UI until the Android
detection layer is real and device-tested — a pause screen that never
pauses anything would be exactly the K18 pattern this repo bans.

## What it is

During an active focus session, opening a user-selected app (defaults:
Instagram, YouTube, TikTok) shows the **calm pause screen** instead of
a cold lock: *"You reached for {app}. Return to {task}, or take a
10-min break — your call."* A choice, never a wall (Rules 10/14), and
**no counts** of how many times they reached (Rule 7).

## Android V1 (the real build — needs native toolchain)

- Detection: Accessibility Service for foreground-app detection — the
  pattern the owner's sister app ("Ekagra: Screen Time & Focus")
  already ships and the Play listing documents. Reuse its service
  skeleton; permissions explained in-app in plain language (sister
  app's FAQ copy is the base).
- `GentleBlockConfig`: blocked package list + monk-mode toggle (off by
  default; when on: hard lock for the session duration, no override —
  the Roots "monk mode" demand tier).
- Service → MethodChannel → `GentleBlockGate.onAppOpened(package)` →
  if session active && package blocked → launch `CalmPauseScreen`.
- Never block Ekagra itself; never during a sanctioned break.

## iOS V1 (no Screen Time API yet)

- App creates a custom **"Deep Work" Focus mode (silences
  notifications) + "Guide me to Screen Time" step-by-step deep-link
  flow. Honest labels: iOS V1 does NOT detect or block other apps.
- FamilyControls/ManagedSettings/DeviceActivity (self-restriction,
  opaque tokens — a privacy plus to market) = V2 track, needs Apple
  API approval, 15-minute minimum unlock window. Tracked as RISK-14.

## Already built in this repo (inert until the flag flips)

- `lib/services/gentle_block_gate.dart` — pure decision logic
  (session-active, package-blocked, monk-mode hard lock), tested.
- `lib/screens/shared/calm_pause_screen.dart` — the choice screen
  (Return to task / 10-min break), Rule-15-safe copy, tested strings.
- No route, no MethodChannel wiring, no manifest entries yet.

## Acceptance (Android, from the work order)

Blocked app during a session → pause screen → return or break;
monk-mode variant locks; no crash paths; permissions flow honest.

## Effort estimate once a toolchain exists

1.5–2 days native (service + channel + device test matrix) + 0.5 day
Play listing copy. The Dart side above is done and tested.
