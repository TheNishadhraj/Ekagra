import 'package:ekagra/models/energy_log_model.dart';
import 'package:ekagra/models/mood_log_model.dart';
import 'package:ekagra/models/task_model.dart';
import 'package:ekagra/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/task_builder.dart';

void main() {
  final ai = AiService();

  group('pickOneThing', () {
    test('returns null for empty task list', () {
      expect(ai.pickOneThing(tasks: []), isNull);
    });

    test('returns null when all tasks are scheduleType.someday', () {
      final tasks = [
        makeTask(id: 'a', title: 'someday task', scheduleType: TaskScheduleType.someday),
        makeTask(id: 'b', title: 'later task', scheduleType: TaskScheduleType.someday),
      ];
      expect(ai.pickOneThing(tasks: tasks), isNull);
    });

    test('returns null when all candidates are in skipIds', () {
      final tasks = [makeTask(id: 'a', title: 'Task A')];
      expect(ai.pickOneThing(tasks: tasks, skipIds: {'a'}), isNull);
    });

    test('ignores completed, archived, and deleted tasks', () {
      final tasks = [
        makeTask(id: 'done', title: 'done', status: TaskStatus.completed),
        makeTask(id: 'arch', title: 'archived', status: TaskStatus.archived),
        makeTask(id: 'del', title: 'deleted', isDeleted: true),
        makeTask(id: 'ok', title: 'viable candidate'),
      ];
      final pick = ai.pickOneThing(tasks: tasks);
      expect(pick, isNotNull);
      expect(pick!.id, 'ok');
    });

    test('returns single candidate and sets microCommitment if missing', () {
      final pick = ai.pickOneThing(
        tasks: [makeTask(id: 'only', title: 'Reply to email')],
      );
      expect(pick!.id, 'only');
      expect(pick.microCommitment, isNotNull);
      expect(pick.microCommitment, 'Just open the email and read the first line.');
    });

    test('preserves existing microCommitment if present', () {
      final pick = ai.pickOneThing(
        tasks: [
          makeTask(
            id: 'x',
            title: 'Reply to email',
            microCommitment: 'Open inbox only.',
          )
        ],
      );
      expect(pick!.microCommitment, 'Open inbox only.');
    });

    test('prefers an easier task on a low-energy / rough-mood day', () {
      final tasks = [
        makeTask(
          id: 'hard',
          title: 'File taxes',
          energyNeeded: EnergyNeeded.high,
          estimatedMinutes: 60,
        ),
        makeTask(
          id: 'easy',
          title: 'Drink water',
          energyNeeded: EnergyNeeded.low,
          estimatedMinutes: 5,
        ),
      ];
      final pick = ai.pickOneThing(
        tasks: tasks,
        energy: EnergyLevel.low,
        mood: MoodLevel.low,
      );
      expect(pick!.id, 'easy');
    });

    test('prefers today scheduleType over anytime', () {
      final tasks = [
        makeTask(id: 'later', title: 'later', scheduleType: TaskScheduleType.anytime),
        makeTask(id: 'today', title: 'today', scheduleType: TaskScheduleType.today),
      ];
      final pick = ai.pickOneThing(tasks: tasks);
      expect(pick!.id, 'today');
    });

    test('penalizes frequently skipped tasks', () {
      final tasks = [
        makeTask(id: 'skipped', title: 'same title', skipCount: 5),
        makeTask(id: 'fresh', title: 'same title'),
      ];
      final pick = ai.pickOneThing(tasks: tasks);
      expect(pick!.id, 'fresh');
    });

    test('skips candidate specified in skipIds', () {
      final tasks = [
        makeTask(id: 'a', title: 'Task A'),
        makeTask(id: 'b', title: 'Task B'),
      ];
      final pick = ai.pickOneThing(tasks: tasks, skipIds: {'a'});
      expect(pick!.id, 'b');
    });
  });

  group('generateMicroCommitment', () {
    test('detects email keyword', () {
      final t = makeTask(title: 'Reply to email from manager');
      expect(ai.generateMicroCommitment(t), contains('email'));
    });

    test('detects call keyword', () {
      final t = makeTask(title: 'Call doctor');
      expect(ai.generateMicroCommitment(t), contains('contacts app'));
    });

    test('detects write keyword', () {
      final t = makeTask(title: 'Write project doc');
      expect(ai.generateMicroCommitment(t), contains('one sentence'));
    });

    test('detects clean keyword', () {
      final t = makeTask(title: 'Clean kitchen counter');
      expect(ai.generateMicroCommitment(t), contains('three things'));
    });

    test('detects water keyword', () {
      final t = makeTask(title: 'Drink water');
      expect(ai.generateMicroCommitment(t), contains('one sip'));
    });

    test('detects grocery keyword', () {
      final t = makeTask(title: 'Buy grocery items');
      expect(ai.generateMicroCommitment(t), contains('three items'));
    });

    test('handles 5-minute generic task', () {
      final t = makeTask(title: 'Sort papers', estimatedMinutes: 5);
      expect(ai.generateMicroCommitment(t), contains('two minutes'));
    });

    test('handles long generic task', () {
      final t = makeTask(title: 'Reorganize closet', estimatedMinutes: 45);
      expect(ai.generateMicroCommitment(t), contains('first tiny step'));
    });
  });

  group('breakdownTask', () {
    test('breaks down cleaning tasks', () async {
      final steps = await ai.breakdownTask('Clean garage');
      expect(steps.length, 3);
      expect(steps.first, contains('surface area'));
    });

    test('breaks down email tasks', () async {
      final steps = await ai.breakdownTask('Reply to email');
      expect(steps.length, 3);
      expect(steps.first, contains('inbox'));
    });

    test('breaks down report/deck tasks', () async {
      final steps = await ai.breakdownTask('Prepare quarterly report');
      expect(steps.length, 3);
      expect(steps.first, contains('document'));
    });

    test('breaks down generic tasks', () async {
      final steps = await ai.breakdownTask('Unpack boxes');
      expect(steps.length, 3);
      expect(steps.first, contains('Gather materials'));
    });
  });

  group('moodAwareMessage', () {
    test('returns low-capacity message for rough mood', () {
      expect(ai.moodAwareMessage(MoodLevel.rough), contains('easy wins'));
    });

    test('returns low-capacity message for low mood', () {
      expect(ai.moodAwareMessage(MoodLevel.low), contains('easy wins'));
    });

    test('returns steady message for okay mood', () {
      expect(ai.moodAwareMessage(MoodLevel.okay), contains('One thing at a time'));
    });

    test('returns encouraging message for good/great mood', () {
      expect(ai.moodAwareMessage(MoodLevel.good), contains('moves the needle'));
      expect(ai.moodAwareMessage(MoodLevel.great), contains('moves the needle'));
    });
  });
}
