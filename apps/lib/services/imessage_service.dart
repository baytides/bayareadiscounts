import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/program.dart';

/// Service for syncing saved programs to the iMessage extension via App Groups
class IMessageService {
  static const _channel = MethodChannel('org.baytides.baynavigator/imessage');

  /// Sync favorite programs to the iMessage extension
  /// Only works on iOS, no-op on other platforms
  static Future<void> syncFavorites(List<Program> favorites) async {
    // Only sync on iOS
    if (!Platform.isIOS) return;

    try {
      final programsData = favorites.map((program) => {
        'id': program.id,
        'name': program.name,
        'category': program.category,
        'description': program.displayDescription,
        'website': program.website,
      }).toList();

      await _channel.invokeMethod('syncFavorites', programsData);
    } on PlatformException {
      // Silently fail - iMessage extension is optional
    } catch (e) {
      debugPrint('Error syncing to iMessage: $e');
    }
  }
}
