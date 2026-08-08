import '../config/constants.dart';
import '../models/user_model.dart';

class DateHelpers {
  DateHelpers._();

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Still up? 🌙';
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    if (hour < 21) return 'Good evening 🌅';
    return 'Night owl mode 🦉';
  }

  static String getEncouragement({int? seed}) {
    final day = seed ?? DateTime.now().day;
    final index = day % EkagraConstants.encouragements.length;
    return EkagraConstants.encouragements[index];
  }

  /// Day progress between wake and sleep (Spec C3).
  static double getDayProgress(UserModel user) {
    final now = DateTime.now();
    final wakeMinutes = user.wakeHour * 60 + user.wakeMinute;
    final sleepMinutes = user.sleepHour * 60 + user.sleepMinute;
    final nowMinutes = now.hour * 60 + now.minute;
    final total = sleepMinutes - wakeMinutes;
    if (total <= 0) return 0.5;
    final elapsed = nowMinutes - wakeMinutes;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }

  static String relativeDayLabel(DateTime date) {
    if (isToday(date)) return 'Today';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (isSameDay(date, yesterday)) return 'Yesterday';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}
