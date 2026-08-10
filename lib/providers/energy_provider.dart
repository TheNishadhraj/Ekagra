import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/energy_log_model.dart';

class EnergyProvider extends ChangeNotifier {
  static const _key = 'ekagra_energy_logs';

  List<EnergyLog> _logs = [];
  bool _loaded = false;

  List<EnergyLog> get logs => List.unmodifiable(_logs);
  bool get loaded => _loaded;

  EnergyLevel get current =>
      _logs.isEmpty ? EnergyLevel.medium : _logs.last.level;

  EnergyLevel get currentLevel => current;

  EnergyLog? get latest => _logs.isEmpty ? null : _logs.last;

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
                    return EnergyLog.fromJson(e);
                  } catch (err) {
                    debugPrint('EnergyLog.fromJson error: $err');
                    return null;
                  }
                })
                .whereType<EnergyLog>()
                .toList();
          }
        } catch (e) {
          debugPrint('EnergyProvider load JSON error: $e');
        }
      }
    } catch (e) {
      debugPrint('EnergyProvider load error: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLevel(EnergyLevel level) async {
    await log(level);
  }

  Future<void> log(EnergyLevel level) async {
    _logs = [
      ..._logs,
      EnergyLog(level: level, timestamp: DateTime.now()),
    ];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(_logs.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('EnergyProvider log persist error: $e');
    }
    notifyListeners();
  }
}
