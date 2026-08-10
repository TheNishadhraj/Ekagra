import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/mood_log_model.dart';

class MoodProvider extends ChangeNotifier {
  static const _key = 'ekagra_mood_logs';

  List<MoodLog> _logs = [];
  bool _loaded = false;

  List<MoodLog> get logs => List.unmodifiable(_logs);
  bool get loaded => _loaded;

  MoodLevel get current => _logs.isEmpty ? MoodLevel.okay : _logs.last.mood;

  MoodLevel get currentLevel => current;

  MoodLog? get latest => _logs.isEmpty ? null : _logs.last;

  bool get needsCheckIn {
    if (_logs.isEmpty) return true;
    final last = _logs.last.timestamp;
    final hours = DateTime.now().difference(last).inHours;
    return hours >= EkagraConstants.energyRecheckHours;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        try {
          final list = jsonDecode(raw);
          if (list is List) {
            _logs = list
                .whereType<Map<String, dynamic>>()
                .map((e) {
                  try {
                    return MoodLog.fromJson(e);
                  } catch (err) {
                    debugPrint('MoodLog.fromJson error: $err');
                    return null;
                  }
                })
                .whereType<MoodLog>()
                .toList();
          }
        } catch (e) {
          debugPrint('MoodProvider load JSON error: $e');
        }
      }
    } catch (e) {
      debugPrint('MoodProvider load error: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLevel(MoodLevel mood) async {
    await log(mood);
  }

  Future<void> log(MoodLevel mood) async {
    _logs = [
      ..._logs,
      MoodLog(mood: mood, timestamp: DateTime.now()),
    ];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(_logs.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('MoodProvider log persist error: $e');
    }
    notifyListeners();
  }
}
