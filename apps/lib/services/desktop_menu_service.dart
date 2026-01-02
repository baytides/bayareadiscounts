import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Desktop menu bar service for macOS, Windows, and Linux
class DesktopMenuService {
  /// Check if we're on a desktop platform
  static bool get isDesktop {
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// Helper to create platform-appropriate shortcut
  static SingleActivator _shortcut(LogicalKeyboardKey key, {bool shift = false}) {
    if (Platform.isMacOS) {
      return SingleActivator(key, meta: true, shift: shift);
    } else {
      return SingleActivator(key, control: true, shift: shift);
    }
  }

  /// Build the platform menu bar
  static List<PlatformMenuItem> buildMenuBar({
    required VoidCallback onSearch,
    required VoidCallback onSettings,
    required VoidCallback onFilters,
    required VoidCallback onRefresh,
    required VoidCallback onExport,
    required VoidCallback onPrint,
    required VoidCallback onToggleTheme,
    required VoidCallback onGoHome,
    required VoidCallback onGoSaved,
    required VoidCallback onQuit,
    required VoidCallback onAbout,
  }) {
    return [
      // App Menu (macOS only - contains About and Quit)
      if (Platform.isMacOS)
        PlatformMenu(
          label: 'Bay Navigator',
          menus: [
            PlatformMenuItem(
              label: 'About Bay Navigator',
              onSelected: onAbout,
            ),
            PlatformMenuItem(
              label: 'Quit Bay Navigator',
              shortcut: _shortcut(LogicalKeyboardKey.keyQ),
              onSelected: onQuit,
            ),
          ],
        ),

      // File Menu
      PlatformMenu(
        label: 'File',
        menus: [
          PlatformMenuItem(
            label: 'Export Saved Programs...',
            shortcut: _shortcut(LogicalKeyboardKey.keyE, shift: true),
            onSelected: onExport,
          ),
          PlatformMenuItem(
            label: 'Print Saved Programs...',
            shortcut: _shortcut(LogicalKeyboardKey.keyP),
            onSelected: onPrint,
          ),
          if (!Platform.isMacOS)
            PlatformMenuItem(
              label: 'Exit',
              shortcut: _shortcut(LogicalKeyboardKey.keyQ),
              onSelected: onQuit,
            ),
        ],
      ),

      // Edit Menu
      PlatformMenu(
        label: 'Edit',
        menus: [
          PlatformMenuItem(
            label: 'Search Programs',
            shortcut: _shortcut(LogicalKeyboardKey.keyF),
            onSelected: onSearch,
          ),
          PlatformMenuItem(
            label: 'Filter Programs',
            shortcut: _shortcut(LogicalKeyboardKey.keyL),
            onSelected: onFilters,
          ),
        ],
      ),

      // View Menu
      PlatformMenu(
        label: 'View',
        menus: [
          PlatformMenuItem(
            label: 'Refresh',
            shortcut: _shortcut(LogicalKeyboardKey.keyR),
            onSelected: onRefresh,
          ),
          PlatformMenuItem(
            label: 'Toggle Dark Mode',
            shortcut: _shortcut(LogicalKeyboardKey.keyD, shift: true),
            onSelected: onToggleTheme,
          ),
        ],
      ),

      // Go Menu
      PlatformMenu(
        label: 'Go',
        menus: [
          PlatformMenuItem(
            label: 'Home',
            shortcut: _shortcut(LogicalKeyboardKey.digit1),
            onSelected: onGoHome,
          ),
          PlatformMenuItem(
            label: 'Saved Programs',
            shortcut: _shortcut(LogicalKeyboardKey.digit2),
            onSelected: onGoSaved,
          ),
          PlatformMenuItem(
            label: 'Settings',
            shortcut: _shortcut(LogicalKeyboardKey.comma),
            onSelected: onSettings,
          ),
        ],
      ),

      // Help Menu (About is here for Windows/Linux, in App menu for macOS)
      PlatformMenu(
        label: 'Help',
        menus: [
          if (!Platform.isMacOS)
            PlatformMenuItem(
              label: 'About Bay Navigator',
              onSelected: onAbout,
            ),
        ],
      ),
    ];
  }
}
