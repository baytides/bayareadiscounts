import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transit.dart';

/// Service for fetching transit agency info and alerts
class TransitService {
  static const String _alertsApiUrl =
      'https://baytides-integrity.azurewebsites.net/api/transit-alerts';
  static const String _alertsCacheKey = 'bay_navigator:transit_alerts';
  static const Duration _cacheDuration = Duration(minutes: 5);

  final http.Client _client;
  SharedPreferences? _prefs;

  TransitService({http.Client? client}) : _client = client ?? http.Client();

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get the list of Bay Area transit agencies
  /// This is static data that doesn't change frequently
  List<TransitAgency> getAgencies() {
    return [
      // Rail services
      TransitAgency(
        id: 'BA',
        name: 'BART',
        type: 'rail',
        color: '#009bda',
        stations: 50,
      ),
      TransitAgency(
        id: 'CT',
        name: 'Caltrain',
        type: 'rail',
        color: '#e31837',
        stations: 30,
      ),
      TransitAgency(
        id: 'SA',
        name: 'SMART',
        type: 'rail',
        color: '#0072bc',
        stations: 14,
      ),
      TransitAgency(
        id: 'CE',
        name: 'ACE Rail',
        type: 'rail',
        color: '#8b4513',
        stations: 10,
      ),
      TransitAgency(
        id: 'AM',
        name: 'Capitol Corridor',
        type: 'rail',
        color: '#00467f',
        stations: 20,
      ),
      // Ferry services
      TransitAgency(
        id: 'GF',
        name: 'Golden Gate Ferry',
        type: 'ferry',
        color: '#c41230',
        stations: 6,
      ),
      TransitAgency(
        id: 'SB',
        name: 'SF Bay Ferry',
        type: 'ferry',
        color: '#1e3a5f',
        stations: 11,
      ),
      // Bus services
      TransitAgency(
        id: 'SF',
        name: 'SF Muni',
        type: 'bus',
        color: '#bc2026',
        stations: 3243,
      ),
      TransitAgency(
        id: 'AC',
        name: 'AC Transit',
        type: 'bus',
        color: '#00a94f',
        stations: 4717,
      ),
      TransitAgency(
        id: 'SC',
        name: 'VTA',
        type: 'bus',
        color: '#0065b8',
        stations: 3134,
      ),
      TransitAgency(
        id: 'SM',
        name: 'SamTrans',
        type: 'bus',
        color: '#e31837',
        stations: 1882,
      ),
      TransitAgency(
        id: 'GG',
        name: 'Golden Gate Transit',
        type: 'bus',
        color: '#c41230',
        stations: 275,
      ),
      TransitAgency(
        id: 'CC',
        name: 'County Connection',
        type: 'bus',
        color: '#0072bb',
        stations: 1182,
      ),
      TransitAgency(
        id: 'WH',
        name: 'Wheels (Livermore)',
        type: 'bus',
        color: '#00a859',
        stations: 666,
      ),
      TransitAgency(
        id: 'MA',
        name: 'Marin Transit',
        type: 'bus',
        color: '#00529b',
        stations: 545,
      ),
      TransitAgency(
        id: '3D',
        name: 'Tri Delta Transit',
        type: 'bus',
        color: '#e21f26',
        stations: 440,
      ),
      TransitAgency(
        id: 'WC',
        name: 'WestCAT',
        type: 'bus',
        color: '#ed1c24',
        stations: 211,
      ),
      TransitAgency(
        id: 'UC',
        name: 'Union City Transit',
        type: 'bus',
        color: '#0072bc',
        stations: 159,
      ),
    ];
  }

  /// Get agencies by type
  List<TransitAgency> getAgenciesByType(String type) {
    return getAgencies().where((a) => a.type == type).toList();
  }

  /// Fetch live transit alerts from the API
  Future<TransitAlertsResponse> fetchAlerts({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh) {
      final cached = await _getCachedAlerts();
      if (cached != null) {
        return cached;
      }
    }

    try {
      final response = await _client
          .get(Uri.parse(_alertsApiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final alertsResponse = TransitAlertsResponse.fromJson(data);

        // Cache the response
        await _cacheAlerts(data);

        return alertsResponse;
      } else {
        throw Exception('Failed to fetch alerts: ${response.statusCode}');
      }
    } catch (e) {
      // Try to return stale cache on error
      final cached = await _getCachedAlerts(allowStale: true);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  /// Get alerts for a specific agency
  Future<List<TransitAlert>> getAlertsForAgency(String agencyId) async {
    final response = await fetchAlerts();
    return response.alerts
        .where((alert) => alert.agencies.contains(agencyId))
        .toList();
  }

  /// Get count of alerts for a specific agency
  Future<int> getAlertCountForAgency(String agencyId) async {
    final alerts = await getAlertsForAgency(agencyId);
    return alerts.length;
  }

  Future<TransitAlertsResponse?> _getCachedAlerts({
    bool allowStale = false,
  }) async {
    try {
      final prefs = await _preferences;
      final cached = prefs.getString(_alertsCacheKey);
      if (cached == null) return null;

      final data = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = data['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (!allowStale && age > _cacheDuration.inMilliseconds) {
        return null;
      }

      return TransitAlertsResponse.fromJson(
          data['data'] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheAlerts(Map<String, dynamic> data) async {
    try {
      final prefs = await _preferences;
      final cached = jsonEncode({
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await prefs.setString(_alertsCacheKey, cached);
    } catch (e) {
      // Silently fail caching
    }
  }

  /// Clear the alerts cache
  Future<void> clearCache() async {
    final prefs = await _preferences;
    await prefs.remove(_alertsCacheKey);
  }
}
