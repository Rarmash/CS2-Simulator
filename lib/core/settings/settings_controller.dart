import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class SettingsController extends ChangeNotifier {
  static const String _xrayOpeningKey = 'xray_opening_enabled';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  AppSettings _settings = const AppSettings();
  bool _isLoaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  bool get xrayOpeningEnabled => _settings.xrayOpeningEnabled;

  Future<void> load() async {
    final enabled = await _prefs.getBool(_xrayOpeningKey) ?? false;
    _settings = _settings.copyWith(xrayOpeningEnabled: enabled);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setXrayOpeningEnabled(bool enabled) async {
    _settings = _settings.copyWith(xrayOpeningEnabled: enabled);
    notifyListeners();
    await _prefs.setBool(_xrayOpeningKey, enabled);
  }

  Future<void> toggleXrayOpening() async {
    await setXrayOpeningEnabled(!xrayOpeningEnabled);
  }
}