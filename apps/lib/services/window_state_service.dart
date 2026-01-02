import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting window state (size, position) on desktop
class WindowStateService {
  static const String _windowStateKey = 'bay_area_discounts:window_state';

  /// Check if we're on a desktop platform
  static bool get isDesktop {
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// Save window state
  static Future<void> saveWindowState({
    required double width,
    required double height,
    required double x,
    required double y,
    required bool isMaximized,
  }) async {
    if (!isDesktop) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final state = {
        'width': width,
        'height': height,
        'x': x,
        'y': y,
        'isMaximized': isMaximized,
        'savedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_windowStateKey, jsonEncode(state));
    } catch (e) {
      // Silently fail
    }
  }

  /// Load saved window state
  static Future<WindowState?> loadWindowState() async {
    if (!isDesktop) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_windowStateKey);
      if (stateJson == null) return null;

      final state = jsonDecode(stateJson) as Map<String, dynamic>;
      return WindowState(
        width: (state['width'] as num).toDouble(),
        height: (state['height'] as num).toDouble(),
        x: (state['x'] as num).toDouble(),
        y: (state['y'] as num).toDouble(),
        isMaximized: state['isMaximized'] as bool? ?? false,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear saved window state
  static Future<void> clearWindowState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_windowStateKey);
    } catch (e) {
      // Silently fail
    }
  }
}

/// Window state data class
class WindowState {
  final double width;
  final double height;
  final double x;
  final double y;
  final bool isMaximized;

  const WindowState({
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    this.isMaximized = false,
  });

  Size get size => Size(width, height);
  Offset get position => Offset(x, y);
}
