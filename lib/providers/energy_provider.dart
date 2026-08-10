import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/energy_log_model.dart';
import '../services/analytics_service.dart';
import '../services/growth_service.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _logs = list
          .map((e) => EnergyLog.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLevel(EnergyLevel level) async {
    await log(level);
  }

  Future<void> log(EnergyLevel level) async {
    track(Ev.energyCheckin, {'level': level.name});
    await GrowthService.instance
        .completeStep(ActivationStep.firstEnergyCheckin);
    _logs = [
      ..._logs,
      EnergyLog(level: level, timestamp: DateTime.now()),
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_logs.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }
}
