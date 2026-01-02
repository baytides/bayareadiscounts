import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _crashReportingKey = 'bay_area_discounts:crash_reporting';

  bool _crashReportingEnabled = true;
  bool _initialized = false;

  bool get crashReportingEnabled => _crashReportingEnabled;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _crashReportingEnabled = prefs.getBool(_crashReportingKey) ?? true;
    } catch (e) {
      // Use default
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> setCrashReportingEnabled(bool enabled) async {
    _crashReportingEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_crashReportingKey, enabled);
    } catch (e) {
      // Continue without persistence
    }
  }
}
