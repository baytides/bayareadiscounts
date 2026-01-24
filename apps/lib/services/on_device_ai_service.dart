import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// On-device AI service for Bay Navigator
/// Uses platform channels to access native AI capabilities:
/// - Android: Gemini Nano via ML Kit GenAI APIs
/// - iOS: Apple Intelligence Foundation Models (handled natively)
///
/// Falls back to cloud API when on-device AI is not available.
class OnDeviceAIService {
  static const _channel = MethodChannel('org.baytides.navigator/ai');

  static final OnDeviceAIService _instance = OnDeviceAIService._internal();
  factory OnDeviceAIService() => _instance;
  OnDeviceAIService._internal();

  /// Cache for availability check
  bool? _isAvailableCache;

  /// Check if on-device AI is available on this device
  Future<bool> get isAvailable async {
    if (_isAvailableCache != null) return _isAvailableCache!;

    try {
      if (kIsWeb) {
        _isAvailableCache = false;
        return false;
      }

      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>('isGeminiNanoAvailable');
        _isAvailableCache = result ?? false;
        return _isAvailableCache!;
      }

      if (Platform.isIOS) {
        // iOS uses native Apple Intelligence - check via platform channel
        final result = await _channel.invokeMethod<bool>('isAppleIntelligenceAvailable');
        _isAvailableCache = result ?? false;
        return _isAvailableCache!;
      }

      _isAvailableCache = false;
      return false;
    } on PlatformException catch (e) {
      debugPrint('[OnDeviceAI] Platform error checking availability: $e');
      _isAvailableCache = false;
      return false;
    }
  }

  /// Get information about available on-device AI capabilities
  Future<AICapabilities> getCapabilities() async {
    try {
      if (kIsWeb || !(await isAvailable)) {
        return AICapabilities.none();
      }

      final result = await _channel.invokeMethod<Map>('getAICapabilities');
      if (result == null) return AICapabilities.none();

      return AICapabilities(
        isAvailable: result['isAvailable'] as bool? ?? false,
        modelName: result['modelName'] as String?,
        supportsSummarization: result['supportsSummarization'] as bool? ?? false,
        supportsPromptAPI: result['supportsPromptAPI'] as bool? ?? false,
        supportsProofreading: result['supportsProofreading'] as bool? ?? false,
        maxInputTokens: result['maxInputTokens'] as int?,
        maxOutputTokens: result['maxOutputTokens'] as int?,
      );
    } on PlatformException catch (e) {
      debugPrint('[OnDeviceAI] Error getting capabilities: $e');
      return AICapabilities.none();
    }
  }

  /// Process a message using on-device AI
  /// Returns null if not available or processing fails
  Future<String?> processMessage({
    required String message,
    required String systemPrompt,
    List<Map<String, String>>? conversationHistory,
  }) async {
    if (!(await isAvailable)) return null;

    try {
      final result = await _channel.invokeMethod<String>('processMessage', {
        'message': message,
        'systemPrompt': systemPrompt,
        'conversationHistory': conversationHistory,
      });

      return result;
    } on PlatformException catch (e) {
      debugPrint('[OnDeviceAI] Error processing message: $e');
      return null;
    }
  }

  /// Summarize text using on-device AI
  /// Useful for long program descriptions
  Future<String?> summarize(String text, {int maxLength = 150}) async {
    if (!(await isAvailable)) return null;

    try {
      final result = await _channel.invokeMethod<String>('summarize', {
        'text': text,
        'maxLength': maxLength,
      });

      return result;
    } on PlatformException catch (e) {
      debugPrint('[OnDeviceAI] Error summarizing: $e');
      return null;
    }
  }

  /// Detect user intent for system actions (reminders, calls, etc.)
  Future<DetectedIntent> detectIntent(String message) async {
    if (!(await isAvailable)) {
      return _detectIntentLocally(message);
    }

    try {
      final result = await _channel.invokeMethod<Map>('detectIntent', {
        'message': message,
      });

      if (result == null) return _detectIntentLocally(message);

      return DetectedIntent(
        type: DetectedIntentType.values.firstWhere(
          (t) => t.name == result['type'],
          orElse: () => DetectedIntentType.none,
        ),
        parameters: Map<String, String>.from(result['parameters'] as Map? ?? {}),
        confidence: result['confidence'] as double? ?? 0.0,
      );
    } on PlatformException catch (e) {
      debugPrint('[OnDeviceAI] Error detecting intent: $e');
      return _detectIntentLocally(message);
    }
  }

  /// Local (non-AI) intent detection as fallback
  DetectedIntent _detectIntentLocally(String message) {
    final lowercased = message.toLowerCase();

    // Reminder detection
    if (lowercased.contains('remind') || lowercased.contains('reminder')) {
      return DetectedIntent(
        type: DetectedIntentType.setReminder,
        parameters: {'title': _extractReminderTitle(message)},
        confidence: 0.7,
      );
    }

    // Timer detection
    if (lowercased.contains('timer') || lowercased.contains('set a timer')) {
      final duration = _extractTimerDuration(message);
      if (duration != null) {
        return DetectedIntent(
          type: DetectedIntentType.setTimer,
          parameters: {'duration': duration.toString()},
          confidence: 0.8,
        );
      }
    }

    // Phone call detection
    if (lowercased.contains('call ')) {
      final number = _extractPhoneNumber(message);
      if (number != null) {
        return DetectedIntent(
          type: DetectedIntentType.makePhoneCall,
          parameters: {'number': number},
          confidence: 0.9,
        );
      }
    }

    // Directions detection
    if (lowercased.contains('directions to') ||
        lowercased.contains('how to get to') ||
        lowercased.contains('navigate to')) {
      return DetectedIntent(
        type: DetectedIntentType.openMaps,
        parameters: {'query': _extractLocationQuery(message)},
        confidence: 0.75,
      );
    }

    return DetectedIntent.none();
  }

  String _extractReminderTitle(String message) {
    final patterns = [
      'remind me to ',
      'reminder to ',
      'remind me about ',
      'set a reminder for ',
    ];

    var cleaned = message.toLowerCase();
    for (final pattern in patterns) {
      if (cleaned.contains(pattern)) {
        cleaned = cleaned.substring(cleaned.indexOf(pattern) + pattern.length);
        // Remove time-related suffixes
        final timePhrases = [' at ', ' on ', ' tomorrow', ' today'];
        for (final phrase in timePhrases) {
          final idx = cleaned.indexOf(phrase);
          if (idx != -1) {
            cleaned = cleaned.substring(0, idx);
            break;
          }
        }
        return cleaned.trim();
      }
    }

    return 'Bay Navigator reminder';
  }

  int? _extractTimerDuration(String message) {
    final patterns = [
      (RegExp(r'(\d+)\s*second'), 1),
      (RegExp(r'(\d+)\s*minute'), 60),
      (RegExp(r'(\d+)\s*hour'), 3600),
    ];

    final lowercased = message.toLowerCase();
    for (final (pattern, multiplier) in patterns) {
      final match = pattern.firstMatch(lowercased);
      if (match != null) {
        final value = int.tryParse(match.group(1) ?? '');
        if (value != null) return value * multiplier;
      }
    }

    return null;
  }

  String? _extractPhoneNumber(String message) {
    // Look for phone number patterns
    final pattern = RegExp(r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}');
    final match = pattern.firstMatch(message);
    if (match != null) return match.group(0);

    // Check for crisis numbers
    final crisisNumbers = {
      '911': ['911', 'emergency'],
      '988': ['988', 'suicide', 'crisis'],
      '211': ['211', 'community'],
    };

    final lowercased = message.toLowerCase();
    for (final entry in crisisNumbers.entries) {
      if (entry.value.any((keyword) => lowercased.contains(keyword))) {
        return entry.key;
      }
    }

    return null;
  }

  String _extractLocationQuery(String message) {
    final patterns = [
      'directions to ',
      'how to get to ',
      'navigate to ',
      'find on map ',
    ];

    var cleaned = message.toLowerCase();
    for (final pattern in patterns) {
      if (cleaned.contains(pattern)) {
        return cleaned
            .substring(cleaned.indexOf(pattern) + pattern.length)
            .trim();
      }
    }

    return message;
  }
}

/// AI capabilities info
class AICapabilities {
  final bool isAvailable;
  final String? modelName;
  final bool supportsSummarization;
  final bool supportsPromptAPI;
  final bool supportsProofreading;
  final int? maxInputTokens;
  final int? maxOutputTokens;

  AICapabilities({
    required this.isAvailable,
    this.modelName,
    this.supportsSummarization = false,
    this.supportsPromptAPI = false,
    this.supportsProofreading = false,
    this.maxInputTokens,
    this.maxOutputTokens,
  });

  factory AICapabilities.none() => AICapabilities(isAvailable: false);
}

/// Detected user intent
class DetectedIntent {
  final DetectedIntentType type;
  final Map<String, String> parameters;
  final double confidence;

  DetectedIntent({
    required this.type,
    this.parameters = const {},
    this.confidence = 0.0,
  });

  factory DetectedIntent.none() => DetectedIntent(
        type: DetectedIntentType.none,
        confidence: 1.0,
      );

  bool get hasIntent => type != DetectedIntentType.none;
}

/// Types of detected intents
enum DetectedIntentType {
  setReminder,
  setTimer,
  createCalendarEvent,
  makePhoneCall,
  sendMessage,
  openMaps,
  searchPrograms,
  none,
}
