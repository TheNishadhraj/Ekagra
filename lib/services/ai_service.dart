import '../models/energy_log_model.dart';
import '../models/mood_log_model.dart';
import '../models/task_model.dart';

/// Spec F — Hybrid "Pick One Thing" engine with offline fallback.
class AiService {
  /// Rank tasks without network (Spec F5 fallback).
  TaskModel? pickOneThing({
    required List<TaskModel> tasks,
    EnergyLevel energy = EnergyLevel.medium,
    MoodLevel mood = MoodLevel.okay,
    Set<String> skipIds = const {},
  }) {
    final candidates = tasks
        .where((t) => t.isActive && !t.isCompleted && !skipIds.contains(t.id))
        .where((t) => t.scheduleType != TaskScheduleType.someday)
        .toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final scoreA = _score(a, energy, mood);
      final scoreB = _score(b, energy, mood);
      return scoreB.compareTo(scoreA);
    });

    final pick = candidates.first;
    return pick.copyWith(
      microCommitment: pick.microCommitment ?? generateMicroCommitment(pick),
      updatedAt: DateTime.now(),
    );
  }

  double _score(TaskModel task, EnergyLevel energy, MoodLevel mood) {
    double score = 50;

    // Prefer today
    if (task.scheduleType == TaskScheduleType.today) score += 30;
    if (task.scheduleType == TaskScheduleType.thisWeek) score += 10;

    // Prefer shorter when low energy / rough mood
    final minutes = task.estimatedMinutes ?? 20;
    final lowCapacity = energy == EnergyLevel.drained ||
        energy == EnergyLevel.low ||
        mood == MoodLevel.rough ||
        mood == MoodLevel.low;

    if (lowCapacity) {
      if (minutes <= 5) score += 40;
      if (minutes <= 15) score += 20;
      if (task.energyNeeded == EnergyNeeded.low) score += 25;
      if (task.energyNeeded == EnergyNeeded.high) score -= 30;
      // Prefer self-care-ish keywords
      final t = task.title.toLowerCase();
      if (t.contains('water') ||
          t.contains('walk') ||
          t.contains('rest') ||
          t.contains('med')) {
        score += 20;
      }
    } else if (energy == EnergyLevel.high || energy == EnergyLevel.superHigh) {
      if (task.energyNeeded == EnergyNeeded.high) score += 20;
      if (minutes >= 30) score += 10;
    }

    // Soft deadlines bump priority without shame language
    if (task.deadline != null) {
      final hours = task.deadline!.difference(DateTime.now()).inHours;
      if (hours < 24) score += 25;
      if (hours < 72) score += 10;
    }

    // Penalize frequently skipped
    score -= task.skipCount * 5;

    return score;
  }

  String generateMicroCommitment(TaskModel task) {
    final title = task.title.toLowerCase();
    if (title.contains('email') || title.contains('mail')) {
      return 'Just open the email and read the first line.';
    }
    if (title.contains('call')) {
      return 'Just open the contacts app and find the name.';
    }
    if (title.contains('write') || title.contains('doc')) {
      return 'Just open the doc and write one sentence.';
    }
    if (title.contains('clean') || title.contains('tidy')) {
      return 'Just pick up three things.';
    }
    if (title.contains('water')) {
      return 'Just fill a glass and take one sip.';
    }
    if (title.contains('grocery') || title.contains('shop')) {
      return 'Just open a notes app and list three items.';
    }
    final minutes = task.estimatedMinutes ?? 10;
    if (minutes <= 5) {
      return 'Just start — two minutes is enough.';
    }
    return 'Just start the first tiny step. That\'s the whole job for now.';
  }

  Future<List<String>> breakdownTask(String title) async {
    final t = title.toLowerCase();
    if (t.contains('clean') || t.contains('tidy')) {
      return [
        'Clear one small surface area (2 min)',
        'Put away 3 scattered items (2 min)',
        'Wipe down surface (1 min)',
      ];
    }
    if (t.contains('email') || t.contains('mail')) {
      return [
        'Open inbox and locate target thread (1 min)',
        'Draft a 1-sentence outline of reply (2 min)',
        'Refine & send (2 min)',
      ];
    }
    if (t.contains('report') || t.contains('doc') || t.contains('deck')) {
      return [
        'Open blank document/template (1 min)',
        'Write down 3 main sub-headings (3 min)',
        'Fill in 2 bullet points under first section (5 min)',
      ];
    }
    return [
      'Gather materials or open app (1 min)',
      'Do the initial 2-minute setup (2 min)',
      'Complete first actionable sub-step (5 min)',
    ];
  }

  String moodAwareMessage(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.rough:
      case MoodLevel.low:
        return 'Low days call for easy wins. Let\'s start with something small.';
      case MoodLevel.okay:
        return 'One thing at a time. That\'s enough.';
      case MoodLevel.good:
      case MoodLevel.great:
        return 'Nice headspace — pick something that moves the needle.';
    }
  }
}
