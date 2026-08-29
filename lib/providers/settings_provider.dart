import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/dopamine_menu_model.dart';
import '../models/user_model.dart';
import '../utils/safe_store.dart';

class SettingsProvider extends ChangeNotifier {
  static const _userKey = 'ekagra_user';
  static const _menuKey = 'ekagra_dopamine_menu';
  static const _onboardingKey = 'ekagra_onboarding_complete';
  static const _welcomeBackShownKey = 'ekagra_welcome_back_last_shown';

  UserModel _user = UserModel.guest();
  DopamineMenu _menu = DopamineMenu.defaults;
  bool _loaded = false;
  bool _darkMode = false;
  DateTime? _welcomeBackShownAt;

  /// Active-at value from *before* this app open — the "gap" the
  /// welcome-back state is measured against.
  DateTime? _previousActiveAt;

  UserModel get user => _user;
  DopamineMenu get menu => _menu;
  bool get loaded => _loaded;
  bool get darkMode => _darkMode;
  bool get onboardingComplete => _user.onboardingComplete;
  DateTime? get welcomeBackShownAt => _welcomeBackShownAt;
  bool get notificationsEnabled => _user.notifications.permissionGranted;

  String get currentEncouragement {
    final day = DateTime.now().day;
    final index = day % EkagraConstants.encouragements.length;
    return EkagraConstants.encouragements[index];
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // A corrupt user record must not block startup. We fall back to the
    // guest profile but preserve the onboarding flag, so a returning user
    // is not dumped back into the welcome flow they already completed.
    final userMap = SafeStore.decodeObject(
      raw: prefs.getString(_userKey),
      key: _userKey,
    );
    final restored = userMap == null
        ? null
        : SafeStore.tryBuild(() => UserModel.fromJson(userMap), key: _userKey);

    if (restored != null) {
      _user = restored;
    } else {
      final complete = prefs.getBool(_onboardingKey) ?? false;
      _user = _user.copyWith(onboardingComplete: complete);
    }

    final menuMap = SafeStore.decodeObject(
      raw: prefs.getString(_menuKey),
      key: _menuKey,
    );
    final menu = menuMap == null
        ? null
        : SafeStore.tryBuild(() => DopamineMenu.fromJson(menuMap),
            key: _menuKey);
    if (menu != null) _menu = menu;

    _welcomeBackShownAt = _parseDay(prefs.getString(_welcomeBackShownKey));
    _previousActiveAt = _user.lastActiveAt;
    _darkMode = prefs.getBool('ekagra_dark_mode') ?? false;
    _loaded = true;
    notifyListeners();
  }

  static DateTime? _parseDay(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw);

  /// WI-1.3: once per ≥3-day gap, when there is content to return to.
  /// The previous-active marker (captured at load, before today's touch)
  /// is what makes the gap honest rather than always-zero.
  bool shouldShowWelcomeBack({required bool hasContent}) {
    if (!_user.onboardingComplete || !hasContent) return false;
    final previous = _previousActiveAt;
    if (previous == null) return false;
    if (DateTime.now().difference(previous).inDays < 3) return false;
    final shown = _welcomeBackShownAt;
    if (shown != null && shown.isAfter(previous)) return false;
    return true;
  }

  Future<void> markWelcomeBackShown() async {
    _welcomeBackShownAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _welcomeBackShownKey,
      _welcomeBackShownAt!.toIso8601String(),
    );
    notifyListeners();
  }

  /// Called once per app open (main). Keeps lastActiveAt fresh so the next
  /// gap is measured from real activity, not from onboarding day.
  Future<void> touchLastActiveAt() async {
    final now = DateTime.now();
    final last = _user.lastActiveAt;
    if (last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day) {
      return;
    }
    _user = _user.copyWith(lastActiveAt: now);
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(_user.toJson()));
    await prefs.setString(_menuKey, jsonEncode(_menu.toJson()));
    await prefs.setBool(_onboardingKey, _user.onboardingComplete);
    await prefs.setBool('ekagra_dark_mode', _darkMode);
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
    // Record the trial start time on first upgrade so the legacy `isPro`
    // path can surface "X days left" and detect expiry. Leaving it null
    // preserves the old behaviour for paid installs that pre-date this field.
    final trialStart = _user.trialStartedAt ?? DateTime.now();
    _user = _user.copyWith(isPro: true, trialStartedAt: trialStart);
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
