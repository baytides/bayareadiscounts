import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keyboard shortcut intents
class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class OpenFiltersIntent extends Intent {
  const OpenFiltersIntent();
}

class GoToHomeIntent extends Intent {
  const GoToHomeIntent();
}

class GoToSavedIntent extends Intent {
  const GoToSavedIntent();
}

class ToggleThemeIntent extends Intent {
  const ToggleThemeIntent();
}

class ExportIntent extends Intent {
  const ExportIntent();
}

class PrintIntent extends Intent {
  const PrintIntent();
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class EscapeIntent extends Intent {
  const EscapeIntent();
}

/// Global keyboard shortcuts for desktop
class KeyboardShortcutsService {
  static final Map<ShortcutActivator, Intent> shortcuts = {
    // Navigation
    const SingleActivator(LogicalKeyboardKey.keyF, meta: true): const FocusSearchIntent(),
    const SingleActivator(LogicalKeyboardKey.keyF, control: true): const FocusSearchIntent(),
    const SingleActivator(LogicalKeyboardKey.comma, meta: true): const OpenSettingsIntent(),
    const SingleActivator(LogicalKeyboardKey.comma, control: true): const OpenSettingsIntent(),
    const SingleActivator(LogicalKeyboardKey.keyL, meta: true): const OpenFiltersIntent(),
    const SingleActivator(LogicalKeyboardKey.keyL, control: true): const OpenFiltersIntent(),

    // Tab navigation
    const SingleActivator(LogicalKeyboardKey.digit1, meta: true): const GoToHomeIntent(),
    const SingleActivator(LogicalKeyboardKey.digit1, control: true): const GoToHomeIntent(),
    const SingleActivator(LogicalKeyboardKey.digit2, meta: true): const GoToSavedIntent(),
    const SingleActivator(LogicalKeyboardKey.digit2, control: true): const GoToSavedIntent(),
    const SingleActivator(LogicalKeyboardKey.digit3, meta: true): const OpenSettingsIntent(),
    const SingleActivator(LogicalKeyboardKey.digit3, control: true): const OpenSettingsIntent(),

    // Actions
    const SingleActivator(LogicalKeyboardKey.keyR, meta: true): const RefreshIntent(),
    const SingleActivator(LogicalKeyboardKey.keyR, control: true): const RefreshIntent(),
    const SingleActivator(LogicalKeyboardKey.keyE, meta: true, shift: true): const ExportIntent(),
    const SingleActivator(LogicalKeyboardKey.keyE, control: true, shift: true): const ExportIntent(),
    const SingleActivator(LogicalKeyboardKey.keyP, meta: true): const PrintIntent(),
    const SingleActivator(LogicalKeyboardKey.keyP, control: true): const PrintIntent(),

    // Theme
    const SingleActivator(LogicalKeyboardKey.keyD, meta: true, shift: true): const ToggleThemeIntent(),
    const SingleActivator(LogicalKeyboardKey.keyD, control: true, shift: true): const ToggleThemeIntent(),

    // Escape
    const SingleActivator(LogicalKeyboardKey.escape): const EscapeIntent(),
  };

  /// Get shortcut hint text for display (platform-aware)
  static String getShortcutHint(String action) {
    final isMac = Platform.isMacOS;
    final cmd = isMac ? '\u2318' : 'Ctrl+';
    final shift = isMac ? '\u21E7' : 'Shift+';

    switch (action) {
      case 'search':
        return '${cmd}F';
      case 'settings':
        return '$cmd,';
      case 'filters':
        return '${cmd}L';
      case 'refresh':
        return '${cmd}R';
      case 'export':
        return '$cmd${shift}E';
      case 'print':
        return '${cmd}P';
      case 'theme':
        return '$cmd${shift}D';
      case 'home':
        return '${cmd}1';
      case 'saved':
        return '${cmd}2';
      default:
        return '';
    }
  }
}
