import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'window_state_service.dart';

/// Platform abstraction service to handle platform-specific functionality
/// without crashing on web where dart:io is not available.
class PlatformService {
  PlatformService._();

  /// Check if running on a desktop platform (not web)
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// Check if running on iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// Check if running on Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// Check if running on macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// Check if running on Windows
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// Check if running on Linux
  static bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  /// Check if running on mobile (iOS or Android)
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Initialize desktop window settings
  static Future<void> initializeDesktopWindow() async {
    if (!isDesktop) return;

    await windowManager.ensureInitialized();

    // Load saved window state
    final savedState = await WindowStateService.loadWindowState();

    WindowOptions windowOptions = WindowOptions(
      size: savedState?.size ?? const Size(1200, 800),
      minimumSize: const Size(400, 600),
      center: savedState == null,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Bay Navigator',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (savedState != null && !savedState.isMaximized) {
        await windowManager.setPosition(savedState.position);
      }
      if (savedState?.isMaximized ?? false) {
        await windowManager.maximize();
      }
      await windowManager.show();
      await windowManager.focus();
    });
  }

  /// Add window listener for desktop
  static void addWindowListener(dynamic listener) {
    if (!isDesktop) return;
    if (listener is WindowListener) {
      windowManager.addListener(listener);
    }
  }

  /// Remove window listener for desktop
  static void removeWindowListener(dynamic listener) {
    if (!isDesktop) return;
    if (listener is WindowListener) {
      windowManager.removeListener(listener);
    }
  }

  /// Start window drag operation
  static void startWindowDrag() {
    if (!isDesktop) return;
    windowManager.startDragging();
  }

  /// Toggle window maximize state
  static Future<void> toggleMaximize() async {
    if (!isDesktop) return;
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  /// Save current window state
  static Future<void> saveWindowState({bool? isMaximized}) async {
    if (!isDesktop) return;
    final bounds = await windowManager.getBounds();
    final maximized = isMaximized ?? await windowManager.isMaximized();
    await WindowStateService.saveWindowState(
      width: bounds.width,
      height: bounds.height,
      x: bounds.left,
      y: bounds.top,
      isMaximized: maximized,
    );
  }
}
