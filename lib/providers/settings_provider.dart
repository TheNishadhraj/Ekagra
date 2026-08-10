import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/dopamine_menu_model.dart';
import '../models/user_model.dart';

class SettingsProvider extends ChangeNotifier {
  static const _userKey = 'ekagra_user';
  static const _menuKey = 'ekagra_dopamine_menu';
  static const _onboardingKey = 'ekagra_onboarding_complete';

  UserModel _user = UserModel.guest();
  DopamineMenu _menu = DopamineMenu.defaults;
  bool _loaded = false;
  bool _darkMode = false;

  UserModel get user => _user;
  DopamineMenu get menu => _menu;
  bool get loaded => _loaded;
  bool get darkMode => _darkMode;
  bool get onboardingComplete => _user.onboardingComplete;
  bool get notificationsEnabled => _user.notifications.permissionGranted;

  String get currentEncouragement {
    final day = DateTime.now().day;
    final index = day % EkagraConstants.encouragements.length;
    return EkagraConstants.encouragements[index];
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        try {
          final map = jsonDecode(userJson);
          if (map is Map<String, dynamic>) {
            _user = UserModel.fromJson(map);
          }
        } catch (e) {
          debugPrint('SettingsProvider user JSON parse error: $e');
        }
      } else {
        final complete = prefs.getBool(_onboardingKey) ?? false;
        _user = _user.copyWith(onboardingComplete: complete);
      }

      final menuJson = prefs.getString(_menuKey);
      if (menuJson != null) {
        try {
          final map = jsonDecode(menuJson);
          if (map is Map<String, dynamic>) {
            _menu = DopamineMenu.fromJson(map);
          }
        } catch (e) {
          debugPrint('SettingsProvider menu JSON parse error: $e');
        }
      }

      _darkMode = prefs.getBool('ekagra_dark_mode') ?? false;
    } catch (e) {
      debugPrint('SettingsProvider load error: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_user.toJson()));
      await prefs.setString(_menuKey, jsonEncode(_menu.toJson()));
      await prefs.setBool(_onboardingKey, _user.onboardingComplete);
      await prefs.setBool('ekagra_dark_mode', _darkMode);
    } catch (e) {
      debugPrint('SettingsProvider _persist error: $e');
    }
  }

  Future<void> setAdhdTraits(List<AdhdTrait> traits) async {
    _user = _user.copyWith(
      adhdTraits: traits.isEmpty ? [AdhdTrait.taskParalysis] : traits,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> setMenu(DopamineMenu menu) async {
    _menu = menu;
    await _persist();
    notifyListeners();
  }

  Future<void> setDisplayName(String name) async {
    _user = _user.copyWith(displayName: name.trim().isEmpty ? null : name);
    await _persist();
    notifyListeners();
  }

  Future<void> enableNotifications() async {
    _user = _user.copyWith(
      notifications: _user.notifications.copyWith(permissionGranted: true),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> disableNotifications() async {
    _user = _user.copyWith(
      notifications: _user.notifications.copyWith(permissionGranted: false),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> completeOnboarding({bool paywallSeen = false}) async {
    final now = DateTime.now();
    _user = _user.copyWith(
      onboardingComplete: true,
      paywallSeen: paywallSeen || _user.paywallSeen,
      lastActiveAt: now,
      totalActiveDays: _user.totalActiveDays == 0 ? 1 : _user.totalActiveDays,
      currentConsecutiveDays: 1,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    _user = _user.copyWith(onboardingComplete: false);
    await _persist();
    notifyListeners();
  }

  Future<void> enablePro() async {
    _user = _user.copyWith(
      isPro: true,
      trialStartedAt: _user.trialStartedAt ?? DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> disablePro() async {
    _user = _user.copyWith(isPro: false);
    await _persist();
    notifyListeners();
  }

  Future<void> setDarkMode(bool val) async {
    _darkMode = val;
    await _persist();
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    await _persist();
    notifyListeners();
  }
}
