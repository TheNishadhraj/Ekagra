import '../config/theme.dart';

/// Countdown colour semantics (WI-2.2, Rule 3).
///
/// Evidence: a shrinking visual conveys remaining time "without any
/// cognitive processing"; colour transitions at 25% and 10% remaining give
/// the deadline a psychological reality. The terminal colour is **warm
/// coral** — never red. Red for negative states is Rule 3, enforced by CI
/// grep on top of this palette.
class CountdownPalette {
  CountdownPalette._();

  /// Colour for a countdown at [fraction] remaining (1.0 = full time left).
  static Color colorForRemainingFraction(double fraction) {
    if (fraction > 0.25) return EkagraColors.focusActive;
    if (fraction > 0.10) return EkagraColors.warning;
    return EkagraColors.error; // warm coral 0xFFFF8C6B — the only "alert"
  }

  /// The documented ADHD estimation correction (WI-2.2): offer a 50%
  /// buffer because planning brains under-estimate. Rounds up — a buffer
  /// that rounds down is not a buffer.
  static int bufferedMinutes(int baseMinutes) {
    if (baseMinutes <= 0) return 0;
    return (baseMinutes * 1.5).ceil();
  }
}
