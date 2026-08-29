# Home Screen Widgets — Build Spec (WI-5.2)

**Status:** spec only. `FeatureFlags.widgets = unbuilt` (already the
case). The `home_widget` package cannot be resolved or verified in this
sandbox (no pub access, no toolchain — RISK-15), and shipping an
API-guessed integration is how Tiimo's broken-widget churn driver gets
reproduced. This is the exact build spec for when a toolchain exists.

## The two-cue system (evidence)

- **Lock screen = urgency**: active focus countdown / "15 min left".
- **Home screen = the day**: One Thing first, next items after.

"If a reminder needs interpretation, it's probably too weak" —
**icon + ≤6 words**, always.

## Widget matrix

| Size | Content | Rule notes |
|---|---|---|
| Small | One Thing title + shrinking arc | icon + ≤6 words; NO counts (Rule 7) |
| Medium | One Thing + next 3 + day progress arc | progress = done-so-far energy, never "X left" shame framing |
| Lock (iOS) | Active focus countdown "15 min left" | wall-clock, no live tick needed |

## Data contract (already satisfiable today)

- Source: `TaskProvider.oneThing` (small/medium), `FocusProvider`
  session end-time (lock screen). All wall-clock derived — **stale
  state (app killed) stays correct** because the countdown is computed
  from timestamps, not ticks.
- Writes: `HomeWidget.saveWidgetData<String>('one_thing', ...)`,
  `saveWidgetData<int>('session_ends_at_ms', ...)` then
  `HomeWidget.updateWidget(...)`. Call on: One-Thing change, session
  start/end, app foreground.
- Reads (tap): deep-link `ekagra://focus` (existing route), never a
  bare app-open.

## Implementation steps (est. 2–3 days with toolchain)

1. `flutter pub add home_widget` (Android Glance + WidgetKit).
2. `lib/services/home_widget_bridge.dart` — thin wrapper so the
   package never leaks past one file (same seam pattern as the
   analytics sink).
3. Android: Glance `AppWidgetProvider` + `receiver_info.xml` layouts.
4. iOS: WidgetKit extension target (needs Xcode — cannot be done from
   CLI sandbox at all), `TimelineProvider` with wall-clock entries.
5. Tests: bridge writes expected keys; deep-link routes; **no task
   counts** string audit on widget layouts.
6. Flip `FeatureFlags.widgets` live per platform only when that
   platform renders from real data.

## Acceptance (from the work order)

Both platforms render from real data; widget tap deep-links; stale
state (app killed) still correct (wall-clock). No task counts anywhere.
