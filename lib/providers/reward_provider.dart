import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dopamine_menu_model.dart';
import '../models/dopamine_reward_model.dart';
import '../services/reward_engine.dart';
import '../utils/safe_store.dart';

class RewardProvider extends ChangeNotifier {
  static const _key = 'ekagra_rewards';

  final RewardEngine _engine = RewardEngine();
  DopamineMenu _menu = DopamineMenu.defaults;
  List<DopamineReward> _history = [];
  DopamineReward? _latest;
  bool _loaded = false;

  List<DopamineReward> get history => List.unmodifiable(_history);
  DopamineReward? get latest => _latest;
  bool get loaded => _loaded;

  List<DopamineItem> get quickRewards => _menu.quick;
  List<DopamineItem> get mediumRewards => _menu.medium;
  List<DopamineItem> get bigRewards => _menu.big;

  int get earnedToday {
    final now = DateTime.now();
    return _history.where((r) {
      final e = r.earnedAt;
      return e.year == now.year && e.month == now.month && e.day == now.day;
    }).length;
  }

  int get todayClaimedCount => earnedToday;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _history = SafeStore.decodeList<DopamineReward>(
      raw: prefs.getString(_key),
      key: _key,
      fromJson: DopamineReward.fromJson,
    );
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_history.map((e) => e.toJson()).toList()),
    );
  }

  DopamineReward generateRandomReward() {
    return _engine.roll(
      menu: _menu,
    );
  }

  Future<void> claimReward(String id) async {
    notifyListeners();
  }

  Future<void> recordTaskCompletion(String taskId) async {
    // Variable ratio reinforcement (1 to 4 tasks)
    final reward = _engine.roll(
      menu: _menu,
      relatedTaskId: taskId,
    );
    _latest = reward;
    _history = [reward, ..._history];
    await _persist();
    notifyListeners();
  }

  Future<void> saveCustomMenu({
    required List<String> quick,
    required List<String> medium,
    required List<String> big,
  }) async {
    final newQuick = quick.map((q) => DopamineItem.create(
      emoji: _extractEmoji(q) ?? '🍫',
      text: _removeEmoji(q),
      tier: RewardTier.quick,
      durationMinutes: 2,
      isCustom: true,
    )).toList();

    final newMedium = medium.map((m) => DopamineItem.create(
      emoji: _extractEmoji(m) ?? '☕',
      text: _removeEmoji(m),
      tier: RewardTier.medium,
      durationMinutes: 15,
      isCustom: true,
    )).toList();

    final newBig = big.map((b) => DopamineItem.create(
      emoji: _extractEmoji(b) ?? '📺',
      text: _removeEmoji(b),
      tier: RewardTier.big,
      durationMinutes: 30,
      isCustom: true,
    )).toList();

    _menu = DopamineMenu(
      quick: newQuick,
      medium: newMedium,
      big: newBig,
    );
    notifyListeners();
  }

  String? _extractEmoji(String str) {
    if (str.isEmpty) return null;
    final firstCodePoint = str.runes.first;
    if (firstCodePoint > 127) {
      return String.fromCharCode(firstCodePoint);
    }
    return null;
  }

  String _removeEmoji(String str) {
    final emoji = _extractEmoji(str);
    if (emoji != null && str.startsWith(emoji)) {
      return str.substring(emoji.length).trim();
    }
    return str;
  }
}
