import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'bay_area_discounts:theme_mode';

  AppThemeMode _mode = AppThemeMode.system;
  bool _initialized = false;

  AppThemeMode get mode => _mode;
  bool get initialized => _initialized;

  bool isDark(BuildContext context) {
    switch (_mode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_themeKey);
      if (modeString != null) {
        _mode = AppThemeMode.values.firstWhere(
          (m) => m.name == modeString,
          orElse: () => AppThemeMode.system,
        );
      }
    } catch (e) {
      // Use default
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (e) {
      // Continue without persistence
    }
  }

  String get modeLabel {
    switch (_mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  /// Toggle between light and dark themes (for keyboard shortcut)
  void toggleTheme() {
    switch (_mode) {
      case AppThemeMode.light:
        setMode(AppThemeMode.dark);
        break;
      case AppThemeMode.dark:
        setMode(AppThemeMode.light);
        break;
      case AppThemeMode.system:
        // When in system mode, switch to opposite of current system theme
        setMode(AppThemeMode.dark);
        break;
    }
  }
}
