# Decision brief — Voice "yap mode" (WI-2.1)

**Status:** owner decision pending · **Prepared:** 2026-08-26 · **Blocking:** nothing (parser already shipped)

## What landed now (no decision needed)

- `lib/services/voice_dump_parser.dart` — the full brain of voice capture,
  shipped as **Smart split** on the Brain Dump screen: fragment splitting,
  filler stripping, date detection (today/tonight/tomorrow/this week/next
  week/"by Friday"/weekday names/someday), quick-add template matching,
  garbage filtering. 100% on-device. Tests: `test/voice_dump_parser_test.dart`.
- The **fake voice simulation was removed** (the mic button that
  "listened" for 2 seconds and inserted a hardcoded task). It was the same
  class of honesty bug as K18.
- `FeatureFlags.voiceDump = unbuilt` — nothing in the UI claims voice.

## The decision (owner)

How to ship the microphone: **on-device whisper.cpp** via `whisper_ggml`.

| Option | Cost | Benefit | Risk |
|---|---|---|---|
| **A. First-run model download** (recommended default) | ~0 app-size; needs network once | Small download flow, model swappable | First voice use needs Wi-Fi — mildly off-brand for "offline forever" |
| **B. Bundle model in assets** | +~140 MB app size | Fully offline from first launch, maximal brand coherence | Store-size friction; users pay the size cost who never use voice |

Research default: **A**, with honest copy at download time ("one-time
download, then your words never leave this phone").

## Build steps once decided (est. 3–5 days with device testing)

1. Add `whisper_ggml`; model download with progress + integrity check.
2. Brain Dump: mic button → streaming transcript into the input → release
   runs the existing parser → same confirmable cards (UI is already built).
3. Copy in onboarding + Settings: "Your words never leave this phone."
4. Flip `voiceDump` → `live` only after both platforms pass the
   acceptance: 60-second dump → ≥N correct cards in <15s on a mid-range
   Android, fully offline after model download.

## Why not done in this batch

No pub.dev egress and no devices in the implementation sandbox; a native
STT binding cannot be honestly verified statically.
