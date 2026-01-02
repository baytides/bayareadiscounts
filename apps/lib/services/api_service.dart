import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/program.dart';

/// API Service for Bay Navigator
/// Fetches data from static JSON API endpoints
/// Implements caching and offline support
class ApiService {
  static const String _apiBaseUrl = 'https://baynavigator.org/api';
  static const Duration _cacheDuration = Duration(hours: 24);

  static const String _programsCacheKey = 'bay_area_discounts:programs';
  static const String _categoriesCacheKey = 'bay_area_discounts:categories';
  static const String _groupsCacheKey = 'bay_area_discounts:groups';
  static const String _areasCacheKey = 'bay_area_discounts:areas';
  static const String _metadataCacheKey = 'bay_area_discounts:metadata';
  static const String _favoritesCacheKey = 'bay_area_discounts:favorites';
  static const String _recentSearchesCacheKey = 'bay_area_discounts:recent_searches';
  static const String _filterPresetsCacheKey = 'bay_area_discounts:filter_presets';

  static const int _maxRecentSearches = 5;
  static const int _maxPresets = 10;

  final http.Client _client;
  SharedPreferences? _prefs;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============================================
  // CACHING
  // ============================================

  Future<T?> _getFromCache<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    bool allowStale = false,
  }) async {
    try {
      final prefs = await _preferences;
      final cached = prefs.getString(key);
      if (cached == null) return null;

      final data = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = data['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (!allowStale && age > _cacheDuration.inMilliseconds) {
        return null;
      }

      return fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<T>?> _getListFromCache<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    bool allowStale = false,
  }) async {
    try {
      final prefs = await _preferences;
      final cached = prefs.getString(key);
      if (cached == null) return null;

      final data = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = data['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (!allowStale && age > _cacheDuration.inMilliseconds) {
        return null;
      }

      final list = data['data'] as List;
      return list.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveToCache(String key, dynamic data) async {
    try {
      final prefs = await _preferences;
      final cached = jsonEncode({
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await prefs.setString(key, cached);
    } catch (e) {
      // Cache write failed, continue silently
    }
  }

  // ============================================
  // API CALLS
  // ============================================

  Future<List<Program>> getPrograms({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _getListFromCache<Program>(
        _programsCacheKey,
        Program.fromJson,
      );
      if (cached != null) return cached;
    }

    try {
      final response = await _client
          .get(Uri.parse('$_apiBaseUrl/programs.json'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final programs = (data['programs'] as List)
          .map((p) => Program.fromJson(p as Map<String, dynamic>))
          .toList();

      await _saveToCache(_programsCacheKey, data['programs']);
      return programs;
    } catch (e) {
      // Try stale cache on error
      final cached = await _getListFromCache<Program>(
        _programsCacheKey,
        Program.fromJson,
        allowStale: true,
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Program> getProgram(String id) async {
    final response = await _client
        .get(Uri.parse('$_apiBaseUrl/programs/$id.json'))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Program not found: $id');
    }

    return Program.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<ProgramCategory>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _getListFromCache<ProgramCategory>(
        _categoriesCacheKey,
        ProgramCategory.fromJson,
      );
      if (cached != null) return cached;
    }

    try {
      final response = await _client
          .get(Uri.parse('$_apiBaseUrl/categories.json'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final categories = (data['categories'] as List)
          .map((c) => ProgramCategory.fromJson(c as Map<String, dynamic>))
          .toList();

      await _saveToCache(_categoriesCacheKey, data['categories']);
      return categories;
    } catch (e) {
      final cached = await _getListFromCache<ProgramCategory>(
        _categoriesCacheKey,
        ProgramCategory.fromJson,
        allowStale: true,
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<ProgramGroup>> getGroups({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _getListFromCache<ProgramGroup>(
        _groupsCacheKey,
        ProgramGroup.fromJson,
      );
      if (cached != null) return cached;
    }

    try {
      final response = await _client
          .get(Uri.parse('$_apiBaseUrl/groups.json'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final groups = (data['groups'] as List)
          .map((g) => ProgramGroup.fromJson(g as Map<String, dynamic>))
          .toList();

      await _saveToCache(_groupsCacheKey, data['groups']);
      return groups;
    } catch (e) {
      final cached = await _getListFromCache<ProgramGroup>(
        _groupsCacheKey,
        ProgramGroup.fromJson,
        allowStale: true,
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<Area>> getAreas({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _getListFromCache<Area>(
        _areasCacheKey,
        Area.fromJson,
      );
      if (cached != null) return cached;
    }

    try {
      final response = await _client
          .get(Uri.parse('$_apiBaseUrl/areas.json'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final areas = (data['areas'] as List)
          .map((a) => Area.fromJson(a as Map<String, dynamic>))
          .toList();

      await _saveToCache(_areasCacheKey, data['areas']);
      return areas;
    } catch (e) {
      final cached = await _getListFromCache<Area>(
        _areasCacheKey,
        Area.fromJson,
        allowStale: true,
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<APIMetadata> getMetadata({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _getFromCache<APIMetadata>(
        _metadataCacheKey,
        APIMetadata.fromJson,
      );
      if (cached != null) return cached;
    }

    try {
      final response = await _client
          .get(Uri.parse('$_apiBaseUrl/metadata.json'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _saveToCache(_metadataCacheKey, data);
      return APIMetadata.fromJson(data);
    } catch (e) {
      final cached = await _getFromCache<APIMetadata>(
        _metadataCacheKey,
        APIMetadata.fromJson,
        allowStale: true,
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  // ============================================
  // SEARCH & FILTER
  // ============================================

  Future<List<Program>> searchPrograms(String query) async {
    final programs = await getPrograms();
    final lowerQuery = query.toLowerCase();

    return programs.where((program) =>
      program.name.toLowerCase().contains(lowerQuery) ||
      program.description.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  Future<List<Program>> filterPrograms({
    List<String> categories = const [],
    List<String> groups = const [],
    List<String> areas = const [],
    String searchQuery = '',
  }) async {
    var programs = await getPrograms();

    // Apply search query
    if (searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      programs = programs.where((p) =>
        p.name.toLowerCase().contains(lowerQuery) ||
        p.description.toLowerCase().contains(lowerQuery)
      ).toList();
    }

    // Apply category filter
    if (categories.isNotEmpty) {
      programs = programs.where((p) => categories.contains(p.category)).toList();
    }

    // Apply groups filter (formerly eligibility)
    if (groups.isNotEmpty) {
      programs = programs.where((p) =>
        groups.any((g) => p.groups.contains(g))
      ).toList();
    }

    // Apply area filter
    if (areas.isNotEmpty) {
      programs = programs.where((p) =>
        areas.any((a) => p.areas.contains(a))
      ).toList();
    }

    return programs;
  }

  // ============================================
  // FAVORITES
  // ============================================

  Future<List<String>> getFavorites() async {
    try {
      final prefs = await _preferences;
      final favorites = prefs.getString(_favoritesCacheKey);
      if (favorites == null) return [];
      return List<String>.from(jsonDecode(favorites) as List);
    } catch (e) {
      return [];
    }
  }

  Future<void> addFavorite(String programId) async {
    final favorites = await getFavorites();
    if (!favorites.contains(programId)) {
      favorites.add(programId);
      final prefs = await _preferences;
      await prefs.setString(_favoritesCacheKey, jsonEncode(favorites));
    }
  }

  Future<void> removeFavorite(String programId) async {
    final favorites = await getFavorites();
    favorites.remove(programId);
    final prefs = await _preferences;
    await prefs.setString(_favoritesCacheKey, jsonEncode(favorites));
  }

  Future<bool> isFavorite(String programId) async {
    final favorites = await getFavorites();
    return favorites.contains(programId);
  }

  // ============================================
  // RECENT SEARCHES
  // ============================================

  Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await _preferences;
      final searches = prefs.getString(_recentSearchesCacheKey);
      if (searches == null) return [];
      return List<String>.from(jsonDecode(searches) as List);
    } catch (e) {
      return [];
    }
  }

  Future<void> addRecentSearch(String query) async {
    if (query.length < 2) return;

    var searches = await getRecentSearches();
    searches.removeWhere((s) => s.toLowerCase() == query.toLowerCase());
    searches.insert(0, query);
    if (searches.length > _maxRecentSearches) {
      searches = searches.sublist(0, _maxRecentSearches);
    }

    final prefs = await _preferences;
    await prefs.setString(_recentSearchesCacheKey, jsonEncode(searches));
  }

  Future<void> clearRecentSearches() async {
    final prefs = await _preferences;
    await prefs.remove(_recentSearchesCacheKey);
  }

  // ============================================
  // FILTER PRESETS
  // ============================================

  Future<List<FilterPreset>> getFilterPresets() async {
    try {
      final prefs = await _preferences;
      final presets = prefs.getString(_filterPresetsCacheKey);
      if (presets == null) return [];
      final list = jsonDecode(presets) as List;
      return list.map((p) => FilterPreset.fromJson(p as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<FilterPreset?> saveFilterPreset(String name, FilterState filters) async {
    if (name.trim().isEmpty) return null;

    final presets = await getFilterPresets();
    if (presets.length >= _maxPresets) return null;

    final preset = FilterPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      filters: filters,
      createdAt: DateTime.now().toIso8601String(),
    );

    presets.insert(0, preset);
    final prefs = await _preferences;
    await prefs.setString(
      _filterPresetsCacheKey,
      jsonEncode(presets.map((p) => p.toJson()).toList()),
    );
    return preset;
  }

  Future<void> deleteFilterPreset(String id) async {
    final presets = await getFilterPresets();
    presets.removeWhere((p) => p.id == id);
    final prefs = await _preferences;
    await prefs.setString(
      _filterPresetsCacheKey,
      jsonEncode(presets.map((p) => p.toJson()).toList()),
    );
  }

  // ============================================
  // CACHE MANAGEMENT
  // ============================================

  Future<void> clearCache() async {
    final prefs = await _preferences;
    final keys = [
      _programsCacheKey,
      _categoriesCacheKey,
      _groupsCacheKey,
      _areasCacheKey,
      _metadataCacheKey,
      // Don't clear favorites
    ];
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<int> getCacheSize() async {
    try {
      final prefs = await _preferences;
      final keys = prefs.getKeys().where((k) => k.startsWith('bay_area_discounts:'));
      int totalSize = 0;
      for (final key in keys) {
        final value = prefs.getString(key);
        if (value != null) {
          totalSize += value.length;
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
}
