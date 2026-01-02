import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences for personalized experience
class UserPrefs {
  final List<String> groups;
  final String? county;
  final int timestamp;

  const UserPrefs({
    required this.groups,
    this.county,
    required this.timestamp,
  });

  factory UserPrefs.fromJson(Map<String, dynamic> json) {
    return UserPrefs(
      groups: List<String>.from(json['groups'] ?? []),
      county: json['county'] as String?,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
    'groups': groups,
    'county': county,
    'timestamp': timestamp,
  };

  UserPrefs copyWith({
    List<String>? groups,
    String? county,
    int? timestamp,
  }) {
    return UserPrefs(
      groups: groups ?? this.groups,
      county: county ?? this.county,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get hasPreferences => groups.isNotEmpty || county != null;
}

/// Provider for managing user preferences and onboarding state
class UserPrefsProvider extends ChangeNotifier {
  static const String _prefsKey = 'bay_area_discounts:user_prefs';
  static const String _onboardingKey = 'bay_area_discounts:onboarding_complete';

  UserPrefs _prefs = const UserPrefs(groups: [], timestamp: 0);
  bool _onboardingComplete = false;
  bool _initialized = false;
  bool _isLoading = false;

  // Getters
  UserPrefs get prefs => _prefs;
  List<String> get selectedGroups => _prefs.groups;
  String? get selectedCounty => _prefs.county;
  bool get onboardingComplete => _onboardingComplete;
  bool get initialized => _initialized;
  bool get isLoading => _isLoading;
  bool get hasPreferences => _prefs.hasPreferences;

  /// Initialize provider from SharedPreferences
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load onboarding state
      _onboardingComplete = prefs.getBool(_onboardingKey) ?? false;

      // Load user preferences
      final prefsJson = prefs.getString(_prefsKey);
      if (prefsJson != null) {
        final data = jsonDecode(prefsJson) as Map<String, dynamic>;
        _prefs = UserPrefs.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
    }

    _initialized = true;
    notifyListeners();
  }

  /// Save user preferences after onboarding
  Future<void> savePreferences({
    required List<String> groups,
    String? county,
  }) async {
    _isLoading = true;
    notifyListeners();

    _prefs = UserPrefs(
      groups: groups,
      county: county,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_prefs.toJson()));
    } catch (e) {
      debugPrint('Error saving user preferences: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } catch (e) {
      debugPrint('Error saving onboarding state: $e');
    }
  }

  /// Reset onboarding to show wizard again
  Future<void> reopenOnboarding() async {
    _onboardingComplete = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, false);
    } catch (e) {
      debugPrint('Error resetting onboarding state: $e');
    }
  }

  /// Clear all preferences (for settings)
  Future<void> clearPreferences() async {
    _prefs = const UserPrefs(groups: [], timestamp: 0);
    _onboardingComplete = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      await prefs.remove(_onboardingKey);
    } catch (e) {
      debugPrint('Error clearing preferences: $e');
    }
  }

  /// Toggle a group selection (for onboarding)
  void toggleGroup(String groupId) {
    final groups = List<String>.from(_prefs.groups);
    if (groups.contains(groupId)) {
      groups.remove(groupId);
    } else {
      groups.add(groupId);
    }
    _prefs = _prefs.copyWith(groups: groups);
    notifyListeners();
  }

  /// Set county selection (for onboarding)
  void setCounty(String? county) {
    _prefs = _prefs.copyWith(county: county);
    notifyListeners();
  }

  /// Check if a group is selected
  bool isGroupSelected(String groupId) => _prefs.groups.contains(groupId);
}
