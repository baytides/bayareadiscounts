import 'package:flutter/foundation.dart';
import '../models/program.dart';
import '../services/api_service.dart';
import '../services/imessage_service.dart';

enum SortOption {
  recentlyVerified,
  nameAsc,
  nameDesc,
  categoryAsc,
}

class ProgramsProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Program> _programs = [];
  List<ProgramCategory> _categories = [];
  List<ProgramGroup> _groups = [];
  List<Area> _areas = [];
  APIMetadata? _metadata;
  List<String> _favorites = [];

  bool _isLoading = false;
  String? _error;

  FilterState _filterState = FilterState();
  SortOption _sortOption = SortOption.recentlyVerified;

  ProgramsProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Getters
  List<Program> get programs => _programs;
  List<ProgramCategory> get categories => _categories;
  List<ProgramGroup> get groups => _groups;
  List<Area> get areas => _areas;
  APIMetadata? get metadata => _metadata;
  List<String> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  FilterState get filterState => _filterState;
  SortOption get sortOption => _sortOption;

  // Helper to get area name from ID (programs store names, not IDs)
  String? _getAreaName(String areaId) {
    final area = _areas.where((a) => a.id == areaId).firstOrNull;
    return area?.name;
  }

  // Names for "Other" areas (what programs actually store)
  static const _otherAreaNames = ['Bay Area', 'Statewide', 'Nationwide'];

  List<Program> get filteredPrograms {
    var result = _programs;

    // Apply search query
    if (_filterState.searchQuery.isNotEmpty) {
      final query = _filterState.searchQuery.toLowerCase();
      result = result.where((p) =>
        p.name.toLowerCase().contains(query) ||
        p.description.toLowerCase().contains(query)
      ).toList();
    }

    // Apply category filter
    if (_filterState.categories.isNotEmpty) {
      result = result.where((p) =>
        _filterState.categories.contains(p.category)
      ).toList();
    }

    // Apply groups filter
    if (_filterState.groups.isNotEmpty) {
      result = result.where((p) =>
        _filterState.groups.any((g) => p.groups.contains(g))
      ).toList();
    }

    // Apply area filter
    if (_filterState.areas.isNotEmpty) {
      // Check if "Other" is selected (any of bay-area, statewide, nationwide)
      final hasOtherSelected = _filterState.areas.any((a) => otherAreaIds.contains(a));
      // Get selected county IDs and convert to names for comparison
      final selectedCountyIds = _filterState.areas.where((a) => !otherAreaIds.contains(a)).toList();
      final selectedCountyNames = selectedCountyIds.map((id) => _getAreaName(id)).whereType<String>().toList();

      result = result.where((p) {
        // Programs store area names like "Bay Area", "Statewide", "San Francisco"
        final isUniversal = p.areas.any((name) => _otherAreaNames.contains(name));
        final matchesCounty = selectedCountyNames.any((name) => p.areas.contains(name));

        if (hasOtherSelected && selectedCountyNames.isEmpty) {
          // Only "Other" selected: show only universal programs
          return isUniversal;
        } else if (hasOtherSelected && selectedCountyNames.isNotEmpty) {
          // Both "Other" and counties selected: show universal + matching counties
          return isUniversal || matchesCounty;
        } else {
          // Only counties selected: show matching counties + universal (they apply everywhere)
          return matchesCounty || isUniversal;
        }
      }).toList();
    }

    // Apply sorting
    result = List.from(result);
    switch (_sortOption) {
      case SortOption.recentlyVerified:
        result.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        break;
      case SortOption.nameAsc:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameDesc:
        result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortOption.categoryAsc:
        result.sort((a, b) {
          final categoryCompare = a.category.compareTo(b.category);
          if (categoryCompare != 0) return categoryCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
    }

    return result;
  }

  List<Program> get favoritePrograms {
    return _programs.where((p) => _favorites.contains(p.id)).toList();
  }

  // Get count of programs for a specific category within current filters
  int getCategoryCount(String categoryId) {
    return _getFilteredProgramsExcluding(excludeCategory: true)
        .where((p) => p.category == categoryId)
        .length;
  }

  // Get count of programs for a specific group within current filters
  int getGroupCount(String groupId) {
    return _getFilteredProgramsExcluding(excludeGroups: true)
        .where((p) => p.groups.contains(groupId))
        .length;
  }

  // Get count of programs for a specific area within current filters
  int getAreaCount(String areaId) {
    final areaName = _getAreaName(areaId);
    if (areaName == null) return 0;
    return _getFilteredProgramsExcluding(excludeArea: true)
        .where((p) => p.areas.contains(areaName))
        .length;
  }

  // Helper to get filtered programs excluding specific filter types
  List<Program> _getFilteredProgramsExcluding({
    bool excludeCategory = false,
    bool excludeGroups = false,
    bool excludeArea = false,
  }) {
    var result = _programs;

    // Apply search query
    if (_filterState.searchQuery.isNotEmpty) {
      final query = _filterState.searchQuery.toLowerCase();
      result = result.where((p) =>
        p.name.toLowerCase().contains(query) ||
        p.description.toLowerCase().contains(query)
      ).toList();
    }

    // Apply category filter (unless excluded)
    if (!excludeCategory && _filterState.categories.isNotEmpty) {
      result = result.where((p) =>
        _filterState.categories.contains(p.category)
      ).toList();
    }

    // Apply groups filter (unless excluded)
    if (!excludeGroups && _filterState.groups.isNotEmpty) {
      result = result.where((p) =>
        _filterState.groups.any((g) => p.groups.contains(g))
      ).toList();
    }

    // Apply area filter (unless excluded)
    if (!excludeArea && _filterState.areas.isNotEmpty) {
      // Check if "Other" is selected (any of bay-area, statewide, nationwide)
      final hasOtherSelected = _filterState.areas.any((a) => otherAreaIds.contains(a));
      // Get selected county IDs and convert to names for comparison
      final selectedCountyIds = _filterState.areas.where((a) => !otherAreaIds.contains(a)).toList();
      final selectedCountyNames = selectedCountyIds.map((id) => _getAreaName(id)).whereType<String>().toList();

      result = result.where((p) {
        // Programs store area names like "Bay Area", "Statewide", "San Francisco"
        final isUniversal = p.areas.any((name) => _otherAreaNames.contains(name));
        final matchesCounty = selectedCountyNames.any((name) => p.areas.contains(name));

        if (hasOtherSelected && selectedCountyNames.isEmpty) {
          // Only "Other" selected: show only universal programs
          return isUniversal;
        } else if (hasOtherSelected && selectedCountyNames.isNotEmpty) {
          // Both "Other" and counties selected: show universal + matching counties
          return isUniversal || matchesCounty;
        } else {
          // Only counties selected: show matching counties + universal (they apply everywhere)
          return matchesCounty || isUniversal;
        }
      }).toList();
    }

    return result;
  }

  // Load initial data
  Future<void> loadData({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getPrograms(forceRefresh: forceRefresh),
        _apiService.getCategories(forceRefresh: forceRefresh),
        _apiService.getGroups(forceRefresh: forceRefresh),
        _apiService.getAreas(forceRefresh: forceRefresh),
        _apiService.getMetadata(forceRefresh: forceRefresh),
        _apiService.getFavorites(),
      ]);

      _programs = results[0] as List<Program>;
      _categories = results[1] as List<ProgramCategory>;
      _groups = results[2] as List<ProgramGroup>;
      _areas = results[3] as List<Area>;
      _metadata = results[4] as APIMetadata;
      _favorites = results[5] as List<String>;

      _error = null;

      // Sync favorites to iMessage extension on initial load
      _syncToIMessage();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh metadata only
  Future<bool> refreshMetadata() async {
    try {
      final newMetadata = await _apiService.getMetadata(forceRefresh: true);
      final hasUpdate = _metadata != null &&
          DateTime.parse(newMetadata.generatedAt)
              .isAfter(DateTime.parse(_metadata!.generatedAt));

      if (hasUpdate) {
        _metadata = newMetadata;
        notifyListeners();
      }

      return hasUpdate;
    } catch (e) {
      return false;
    }
  }

  // Filter methods
  void setSearchQuery(String query) {
    _filterState = _filterState.copyWith(searchQuery: query);
    notifyListeners();
  }

  void toggleCategory(String categoryId) {
    final categories = List<String>.from(_filterState.categories);
    if (categories.contains(categoryId)) {
      categories.remove(categoryId);
    } else {
      categories.add(categoryId);
    }
    _filterState = _filterState.copyWith(categories: categories);
    notifyListeners();
  }

  void toggleGroup(String groupId) {
    final groups = List<String>.from(_filterState.groups);
    if (groups.contains(groupId)) {
      groups.remove(groupId);
    } else {
      groups.add(groupId);
    }
    _filterState = _filterState.copyWith(groups: groups);
    notifyListeners();
  }

  void toggleArea(String areaId) {
    final areas = List<String>.from(_filterState.areas);
    if (areas.contains(areaId)) {
      areas.remove(areaId);
    } else {
      areas.add(areaId);
    }
    _filterState = _filterState.copyWith(areas: areas);
    notifyListeners();
  }

  // IDs for "Other" area group (Bay Area, Statewide, Nationwide)
  static const otherAreaIds = ['bay-area', 'statewide', 'nationwide'];

  // Toggle "Other" areas (Bay Area, Statewide, Nationwide) as a group
  void toggleOtherAreas() {
    final areas = List<String>.from(_filterState.areas);
    final hasAnyOther = areas.any((id) => otherAreaIds.contains(id));

    if (hasAnyOther) {
      // Remove all other area IDs
      areas.removeWhere((id) => otherAreaIds.contains(id));
    } else {
      // Add all other area IDs
      for (final id in otherAreaIds) {
        if (!areas.contains(id)) {
          areas.add(id);
        }
      }
    }
    _filterState = _filterState.copyWith(areas: areas);
    notifyListeners();
  }

  // Get count of programs for "Other" areas (Bay Area, Statewide, Nationwide)
  int getOtherAreasCount() {
    return _getFilteredProgramsExcluding(excludeArea: true)
        .where((p) => p.areas.any((name) => _otherAreaNames.contains(name)))
        .length;
  }

  void clearFilters() {
    _filterState = FilterState();
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void applyFilterPreset(FilterPreset preset) {
    _filterState = preset.filters;
    notifyListeners();
  }

  // Favorites methods
  Future<void> toggleFavorite(String programId) async {
    if (_favorites.contains(programId)) {
      await _apiService.removeFavorite(programId);
      _favorites.remove(programId);
    } else {
      await _apiService.addFavorite(programId);
      _favorites.add(programId);
    }
    notifyListeners();
    // Sync to iMessage extension
    _syncToIMessage();
  }

  bool isFavorite(String programId) {
    return _favorites.contains(programId);
  }

  Future<void> clearAllFavorites() async {
    for (final programId in List.from(_favorites)) {
      await _apiService.removeFavorite(programId);
    }
    _favorites.clear();
    notifyListeners();
    // Sync to iMessage extension
    _syncToIMessage();
  }

  /// Sync current favorites to iMessage extension (iOS only)
  void _syncToIMessage() {
    final favoritePrograms = _programs.where((p) => _favorites.contains(p.id)).toList();
    IMessageService.syncFavorites(favoritePrograms);
  }

  // Cache methods
  Future<void> clearCache() async {
    await _apiService.clearCache();
  }

  Future<int> getCacheSize() async {
    return await _apiService.getCacheSize();
  }
}
