import 'package:ekagra/models/task_model.dart';
import 'package:ekagra/services/voice_dump_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// WI-2.1 — the "yap mode" parser, shipped as Smart split.
///
/// No network, no permissions, no platform channels: pure functions of the
/// transcript, which is why this can ship before the microphone does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final parser = VoiceDumpParser();
  final now = DateTime(2026, 8, 26, 14, 0); // a Wednesday

  test('splits a stream of thoughts on natural connectors', () {
    final out = parser.parse(
      'reply to the landlord and then um call the dentist also water the plants',
      now: now,
    );
    expect(out.length, 3);
    expect(out[0].title, 'Reply to the landlord');
    expect(out[1].title, 'Call the dentist');
    expect(out[2].title, 'Water the plants');
  });

  test('fillers and garbage never become tasks', () {
    final out = parser.parse('um uh hmm  a  , er', now: now);
    expect(out, isEmpty);

    final single = parser.parse('ok', now: now);
    expect(single, isEmpty, reason: 'a lone "ok" is not a thought');
  });

  test('date detection: tomorrow / tonight / this week / by Friday / someday',
      () {
    final t = parser.parse('pay the bill tomorrow', now: now);
    expect(t.single.schedule, TaskScheduleType.today);
    expect(t.single.deadline!.day, 27);

    final tonight = parser.parse('tidy the desk tonight', now: now);
    expect(tonight.single.schedule, TaskScheduleType.today);
    expect(tonight.single.title, 'Tidy the desk');

    final week = parser.parse('book the dentist this week', now: now);
    expect(week.single.schedule, TaskScheduleType.thisWeek);

    // Wednesday -> Friday is 2 days ahead.
    final byFriday = parser.parse('send the form by friday', now: now);
    expect(byFriday.single.deadline!.day, 28);
    expect(byFriday.single.title, 'Send the form');

    final someday = parser.parse('learn pottery someday', now: now);
    expect(someday.single.schedule, TaskScheduleType.someday);
    expect(someday.single.title, 'Learn pottery');
  });

  test('template matching recognizes the quick-add canon', () {
    final out = parser.parse(
      'emails, meds, water, walk, tidy, groceries, pay the rent, call mom',
      now: now,
    );
    final templates = out.map((f) => f.matchedTemplate).toSet();
    expect(templates, contains('Reply to emails'));
    expect(templates, contains('Take medication'));
    expect(templates, contains('Drink water'));
    expect(templates, contains('Move body'));
    expect(templates, contains('Groceries'));
    expect(templates, contains('Pay a bill'));
    expect(templates, contains('Call someone'));
  });

  test('titles come out tidy: no double spaces, leading caps', () {
    final out = parser.parse('   water   the  plants  ,  ', now: now);
    expect(out.single.title, 'Water the plants');
  });

  test('empty input is empty output, never an exception', () {
    expect(parser.parse('', now: now), isEmpty);
    expect(parser.parse('   \n  ', now: now), isEmpty);
    expect(parser.parse('!!! ???', now: now), isEmpty);
  });
}
