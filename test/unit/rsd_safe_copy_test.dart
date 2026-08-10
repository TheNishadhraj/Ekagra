import 'package:ekagra/utils/rsd_safe_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isSafe', () {
    final forbidden = <String>[
      'streak',
      'overdue',
      'failed',
      'missed',
      'lazy',
      'failure',
      'broken',
      'behind',
      "should have",
      "why didn't you",
      'you broke',
      'start over',
      'incomplete',
      'pending',
    ];

    for (final word in forbidden) {
      test('rejects "$word"', () {
        expect(RsdSafeCopy.isSafe('You are a $word example.'), isFalse);
      });
    }

    test('is case-insensitive', () {
      expect(RsdSafeCopy.isSafe('Your STREAK is intact'), isFalse);
      expect(RsdSafeCopy.isSafe('You Missed it'), isFalse);
    });

    test('accepts shame-free copy', () {
      expect(RsdSafeCopy.isSafe('Great job! Take a break.'), isTrue);
      expect(RsdSafeCopy.isSafe('Welcome back!'), isTrue);
      expect(RsdSafeCopy.isSafe('Active days'), isTrue);
      expect(RsdSafeCopy.isSafe('One thing at a time.'), isTrue);
    });
  });

  group('activeDaysDisplay', () {
    test('shows active days when active today', () {
      expect(
        RsdSafeCopy.activeDaysDisplay(
          isActiveToday: true,
          currentConsecutive: 3,
          daysSinceLastActive: 0,
          totalActiveDays: 10,
        ),
        '💛 3 days active',
      );
    });

    test('shows welcome back when one day away', () {
      expect(
        RsdSafeCopy.activeDaysDisplay(
          isActiveToday: false,
          currentConsecutive: 0,
          daysSinceLastActive: 1,
          totalActiveDays: 10,
        ),
        '💛 Welcome back!',
      );
    });

    test('shows welcome back with total active days when multiple days away', () {
      expect(
        RsdSafeCopy.activeDaysDisplay(
          isActiveToday: false,
          currentConsecutive: 0,
          daysSinceLastActive: 5,
          totalActiveDays: 23,
        ),
        '💛 Welcome back! 23 days active total.',
      );
    });
  });

  group('message constants', () {
    test('every shipped message constant is RSD-safe', () {
      final messages = [
        RsdSafeCopy.networkError,
        RsdSafeCopy.aiTimeout,
        RsdSafeCopy.taskLimit,
        RsdSafeCopy.subscriptionExpired,
        RsdSafeCopy.paymentFailed,
        RsdSafeCopy.syncError,
        RsdSafeCopy.crashRecovery,
        RsdSafeCopy.rateLimit,
        RsdSafeCopy.unknownError,
      ];
      for (final m in messages) {
        expect(RsdSafeCopy.isSafe(m), isTrue, reason: 'message not RSD-safe: $m');
      }
    });
  });
}
