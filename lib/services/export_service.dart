import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/dopamine_menu_model.dart';
import '../models/dopamine_reward_model.dart';
import '../models/energy_log_model.dart';
import '../models/mood_log_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

/// Real, local, offline data export — the K18 fix.
///
/// WHY THIS EXISTS
/// ---------------
/// The Settings tile used to say "File saved locally" while writing nothing
/// at all. For an app whose entire promise is "never lose the thought", a
/// fake export button is a brand violation in the same class as a security
/// bug. This service makes the promise real: everything Ekagra knows about
/// the user is serialized to one human-readable JSON file in the app's
/// documents directory (plus an optional CSV of tasks), which the caller
/// then hands to the OS share sheet. No network is involved at any point.
class ExportService {
  ExportService({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectory;

  /// Everything the app persists about the user, in one JSON document.
  ///
  /// Deliberately versioned: if the shape ever evolves, consumers (including
  /// the user, in a text editor two years from now) can tell what they are
  /// looking at without guessing.
  static Map<String, dynamic> buildExportPayload({
    required List<TaskModel> tasks,
    required List<DopamineReward> rewards,
    required List<EnergyLog> energyLogs,
    required List<MoodLog> moodLogs,
    required UserModel user,
    required DopamineMenu menu,
    required int todayFocusMinutes,
    DateTime? exportedAt,
  }) {
    final now = exportedAt ?? DateTime.now();
    return {
      'app': 'Ekagra',
      'format': 'ekagra.export.v1',
      'exportedAt': now.toIso8601String(),
      'user': user.toJson(),
      'dopamineMenu': menu.toJson(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'rewards': rewards.map((r) => r.toJson()).toList(),
      'energyLogs': energyLogs.map((e) => e.toJson()).toList(),
      'moodLogs': moodLogs.map((m) => m.toJson()).toList(),
      'todayFocusMinutes': todayFocusMinutes,
    };
  }

  /// Human-readable serialization of [buildExportPayload]'s output.
  static String encodePayload(Map<String, dynamic> payload) {
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Tasks-only CSV. RFC 4180 quoting so a title containing a comma, quote
  /// or newline cannot smuggle fields.
  static String tasksToCsv(List<TaskModel> tasks) {
    const header = [
      'id',
      'title',
      'status',
      'schedule_type',
      'deadline',
      'estimated_minutes',
      'created_at',
      'completed_at',
    ];
    final rows = <String>[header.join(',')];
    for (final t in tasks) {
      rows.add(
        [
          t.id,
          t.title,
          t.status.name,
          t.scheduleType.name,
          t.deadline?.toIso8601String() ?? '',
          t.estimatedMinutes?.toString() ?? '',
          t.createdAt.toIso8601String(),
          t.completedAt?.toIso8601String() ?? '',
        ]
            .map(_csvEscape)
            .join(','),
      );
    }
    return rows.join('\n');
  }

  static String _csvEscape(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Writes the JSON export (and the tasks CSV alongside it) and returns the
  /// JSON file. Throws [FileSystemException] on IO failure — the caller is
  /// expected to surface an honest error, never a fake success.
  Future<File> writeExport({
    required Map<String, dynamic> payload,
    bool includeCsv = true,
    DateTime? now,
  }) async {
    final stamp = (now ?? DateTime.now());
    final dir = await _documentsDirectory();
    final jsonFile = File(
      '${dir.path}/ekagra-export-'
      '${stamp.year}${_two(stamp.month)}${_two(stamp.day)}-'
      '${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}.json',
    );
    await jsonFile.writeAsString(encodePayload(payload), flush: true);

    if (includeCsv) {
      final tasks = (payload['tasks'] as List)
          .map(
            (t) => TaskModel.fromJson(Map<String, dynamic>.from(t as Map)),
          )
          .toList();
      final csvFile = File('${jsonFile.path.replaceAll('.json', '')}.csv');
      await csvFile.writeAsString(tasksToCsv(tasks), flush: true);
    }
    return jsonFile;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
