import 'dart:convert';
import 'dart:io';

import 'package:ekagra/models/dopamine_menu_model.dart';
import 'package:ekagra/models/dopamine_reward_model.dart';
import 'package:ekagra/models/energy_log_model.dart';
import 'package:ekagra/models/mood_log_model.dart';
import 'package:ekagra/models/task_model.dart';
import 'package:ekagra/models/user_model.dart';
import 'package:ekagra/services/export_service.dart';
import 'package:ekagra/utils/safe_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// WI-1.1 — the export that used to be fake (K18).
///
/// The acceptance bar: write → read back → field parity, and tolerance of
/// corrupted records through the same SafeStore helpers production uses.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tasks = [
    TaskModel.create(title: 'Reply to the landlord, with feelings'),
    TaskModel.create(title: 'Drink water'),
  ];
  final rewards = <DopamineReward>[
    DopamineReward.fromItem(
      DopamineMenu.defaults.quick.first,
      relatedTaskId: tasks.first.id,
    ),
  ];
  final energyLogs = <EnergyLog>[
    EnergyLog(level: EnergyLevel.high, timestamp: DateTime(2026, 8, 26, 9)),
  ];
  final moodLogs = <MoodLog>[
    MoodLog(mood: MoodLevel.good, timestamp: DateTime(2026, 8, 26, 9, 5)),
  ];

  test('payload round-trips with field parity', () {
    final user = UserModel.guest();
    final menu = DopamineMenu.defaults;
    final payload = ExportService.buildExportPayload(
      tasks: tasks,
      rewards: rewards,
      energyLogs: energyLogs,
      moodLogs: moodLogs,
      user: user,
      menu: menu,
      todayFocusMinutes: 42,
    );

    // Encode → decode, exactly like a user opening the file later.
    final encoded = ExportService.encodePayload(payload);
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;

    expect(decoded['format'], 'ekagra.export.v1');
    expect(decoded['todayFocusMinutes'], 42);

    final decodedTasks = (decoded['tasks'] as List)
        .map((t) => TaskModel.fromJson(Map<String, dynamic>.from(t as Map)))
        .toList();
    expect(decodedTasks.length, tasks.length);
    for (var i = 0; i < tasks.length; i++) {
      expect(decodedTasks[i].id, tasks[i].id);
      expect(decodedTasks[i].title, tasks[i].title);
      expect(decodedTasks[i].status, tasks[i].status);
    }

    final decodedRewards = (decoded['rewards'] as List)
        .map((r) => DopamineReward.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
    expect(decodedRewards.length, 1);
    expect(decodedRewards.first.relatedTaskId, tasks.first.id);
    expect(decodedRewards.first.item.text, rewards.first.item.text);

    final decodedEnergy = (decoded['energyLogs'] as List)
        .map((e) => EnergyLog.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    expect(decodedEnergy.first.level, EnergyLevel.high);

    final decodedMood = (decoded['moodLogs'] as List)
        .map((m) => MoodLog.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
    expect(decodedMood.first.mood, MoodLevel.good);

    final decodedUser = UserModel.fromJson(
      Map<String, dynamic>.from(decoded['user'] as Map),
    );
    expect(decodedUser.id, user.id);
    expect(decodedUser.adhdTraits, user.adhdTraits);
  });

  test('CSV escapes commas, quotes and newlines (RFC 4180)', () {
    final tricky = TaskModel.create(title: 'Buy milk, "organic",\nand eggs');
    final csv = ExportService.tasksToCsv([tricky]);
    final lines = csv.split('\n');
    // Header + the quoted title keeps the record on one CSV row *after*
    // unescaping; the raw string may contain the newline inside quotes.
    expect(lines.first, startsWith('id,title'));
    final fields = _parseCsvRow(lines.sublist(1).join('\n')).last;
    expect(fields[1], 'Buy milk, "organic",\nand eggs');
  });

  test('writeExport writes real files that read back identically', () async {
    final tmp = await Directory.systemTemp.createTemp('ekagra_export_test');
    final service = ExportService(
      documentsDirectory: () async => tmp,
    );
    final payload = ExportService.buildExportPayload(
      tasks: tasks,
      rewards: rewards,
      energyLogs: energyLogs,
      moodLogs: moodLogs,
      user: UserModel.guest(),
      menu: DopamineMenu.defaults,
      todayFocusMinutes: 7,
    );
    final file = await service.writeExport(
      payload: payload,
      now: DateTime(2026, 8, 26, 14, 30, 5),
    );

    expect(file.existsSync(), isTrue);
    expect(file.path, contains('ekagra-export-20260826-143005.json'));

    final reread = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(reread['format'], 'ekagra.export.v1');
    expect((reread['tasks'] as List).length, tasks.length);

    final csv = File('${file.path.replaceAll('.json', '')}.csv');
    expect(csv.existsSync(), isTrue);
    expect(csv.readAsStringSync(), contains('Reply to the landlord'));

    await tmp.delete(recursive: true);
  });

  test('corrupted records are tolerated via the SafeStore path', () {
    // One mangled task among good ones must not cost the good ones — the
    // same guarantee the production load path gives (ADR-001).
    final good = TaskModel.create(title: 'Survivor').toJson();
    final raw = jsonEncode([
      {'id': 1, 'garbage': true}, // not a valid task
      good,
    ]);
    final recovered = SafeStore.decodeList<TaskModel>(
      raw: raw,
      key: 'ekagra_tasks_test',
      fromJson: TaskModel.fromJson,
    );
    expect(recovered.length, 1);
    expect(recovered.first.title, 'Survivor');
  });
}

/// Minimal RFC 4180 row splitter for asserting the CSV content.
List<List<String>> _parseCsvRow(String csv) {
  final rows = <List<String>>[];
  var field = StringBuffer();
  var row = <String>[];
  var inQuotes = false;
  for (var i = 0; i < csv.length; i++) {
    final ch = csv[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < csv.length && csv[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(ch);
      }
    } else if (ch == '"') {
      inQuotes = true;
    } else if (ch == ',') {
      row.add(field.toString());
      field = StringBuffer();
    } else if (ch == '\n') {
      row.add(field.toString());
      rows.add(row);
      row = <String>[];
      field = StringBuffer();
    } else {
      field.write(ch);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}
