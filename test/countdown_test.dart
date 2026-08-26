import 'package:ekagra/config/theme.dart';
import 'package:ekagra/models/task_model.dart';
import 'package:ekagra/providers/focus_provider.dart';
import 'package:ekagra/utils/countdown_palette.dart';
import 'package:flutter_test/flutter_test.dart';

/// WI-2.2 — per-task countdown semantics.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CountdownPalette', () {
    test('colour transitions land at 25% and 10% remaining', () {
      // Plenty of time → primary purple.
      expect(
        CountdownPalette.colorForRemainingFraction(0.9),
        EkagraColors.focusActive,
      );
      expect(
        CountdownPalette.colorForRemainingFraction(0.26),
        EkagraColors.focusActive,
      );
      // At 25% remaining: warm amber.
      expect(
        CountdownPalette.colorForRemainingFraction(0.25),
        EkagraColors.warning,
      );
      expect(
        CountdownPalette.colorForRemainingFraction(0.11),
        EkagraColors.warning,
      );
      // At 10%: warm coral — NEVER red (Rule 3).
      expect(
        CountdownPalette.colorForRemainingFraction(0.10),
        EkagraColors.error,
      );
      expect(
        CountdownPalette.colorForRemainingFraction(0.0),
        EkagraColors.error,
      );
      // And the terminal colour is genuinely the warm coral, not pure red.
      expect(EkagraColors.error, const Color(0xFFFF8C6B));
    });
  });

  group('50% time buffer', () {
    test('rounds up — a buffer that rounds down is not a buffer', () {
      expect(CountdownPalette.bufferedMinutes(20), 30);
      expect(CountdownPalette.bufferedMinutes(25), 38);
      expect(CountdownPalette.bufferedMinutes(33), 50);
      expect(CountdownPalette.bufferedMinutes(5), 8);
      expect(CountdownPalette.bufferedMinutes(0), 0);
    });
  });

  group('one active task at a time', () {
    test('setting a new task replaces the previous active one', () {
      final focus = FocusProvider();
      final a = TaskModel.create(title: 'First thing');
      final b = TaskModel.create(title: 'Second thing');

      focus.setTask(a);
      expect(focus.currentTask?.id, a.id);
      expect(focus.session?.plannedMinutes, a.estimatedMinutes);

      focus.setTask(b);
      expect(focus.currentTask?.id, b.id,
          reason: 'anti-overwhelm rule: exactly one active task');
      expect(focus.currentTask?.id == a.id, isFalse);
      focus.reset();
    });

    test('estimate sheet math: duration overrides the task estimate', () {
      final focus = FocusProvider();
      final task = TaskModel.create(title: 'Deep clean');
      focus.setTask(task);
      focus.setDuration(CountdownPalette.bufferedMinutes(20));
      expect(focus.session?.plannedMinutes, 30);
      focus.reset();
    });
  });
}
