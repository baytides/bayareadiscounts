// Transit agency and alert models for Bay Navigator

/// Represents a Bay Area transit agency
class TransitAgency {
  final String id;
  final String name;
  final String type; // 'rail', 'ferry', 'bus'
  final String color;
  final int stations;

  TransitAgency({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.stations,
  });

  factory TransitAgency.fromJson(Map<String, dynamic> json) {
    return TransitAgency(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      color: json['color'] as String,
      stations: json['stations'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'color': color,
        'stations': stations,
      };

  /// Get the label for station count based on type
  String get stationLabel {
    switch (type) {
      case 'ferry':
        return 'terminals';
      case 'bus':
        return 'stops';
      default:
        return 'stations';
    }
  }

  /// Get agency website URL
  String get websiteUrl {
    switch (id) {
      case 'BA':
        return 'https://www.bart.gov';
      case 'CT':
        return 'https://www.caltrain.com';
      case 'SF':
        return 'https://www.sfmta.com';
      case 'AC':
        return 'https://www.actransit.org';
      case 'SC':
        return 'https://www.vta.org';
      case 'SM':
        return 'https://www.samtrans.com';
      case 'GG':
        return 'https://www.goldengate.org/bus';
      case 'SA':
        return 'https://www.sonomamarintrain.org';
      case 'GF':
        return 'https://www.goldengate.org/ferry';
      case 'SB':
        return 'https://sanfranciscobayferry.com';
      case 'CC':
        return 'https://countyconnection.com';
      case 'WH':
        return 'https://www.wheelsbus.com';
      case 'MA':
        return 'https://marintransit.org';
      case '3D':
        return 'https://trideltatransit.com';
      case 'WC':
        return 'https://www.westcat.org';
      case 'UC':
        return 'https://www.unioncity.org/transit';
      case 'CE':
        return 'https://acerail.com';
      case 'AM':
        return 'https://www.capitolcorridor.org';
      default:
        return 'https://511.org';
    }
  }

  /// Get alerts page URL
  String get alertsUrl {
    switch (id) {
      case 'BA':
        return 'https://www.bart.gov/schedules/advisories';
      case 'CT':
        return 'https://www.caltrain.com/alerts';
      case 'SF':
        return 'https://www.sfmta.com/getting-around/transit/routes-stops';
      case 'AC':
        return 'https://www.actransit.org/service-notices';
      case 'SC':
        return 'https://www.vta.org/go/alerts';
      case 'SM':
        return 'https://www.samtrans.com/alerts';
      case 'GG':
        return 'https://www.goldengate.org/alerts';
      case 'SA':
        return 'https://www.sonomamarintrain.org/alerts';
      case 'GF':
        return 'https://www.goldengate.org/alerts';
      case 'SB':
        return 'https://sanfranciscobayferry.com/service-alerts';
      default:
        return 'https://511.org/transit/alerts';
    }
  }
}

/// Represents a transit service alert
class TransitAlert {
  final String id;
  final String title;
  final List<String> agencies;
  final String? url;
  final String timeAgo;
  final int startTime;

  TransitAlert({
    required this.id,
    required this.title,
    required this.agencies,
    this.url,
    required this.timeAgo,
    required this.startTime,
  });

  factory TransitAlert.fromJson(Map<String, dynamic> json) {
    return TransitAlert(
      id: json['id'] as String,
      title: json['title'] as String,
      agencies: (json['agencies'] as List).cast<String>(),
      url: json['url'] as String?,
      timeAgo: json['timeAgo'] as String? ?? '',
      startTime: json['startTime'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'agencies': agencies,
        'url': url,
        'timeAgo': timeAgo,
        'startTime': startTime,
      };
}

/// Response from the transit alerts API
class TransitAlertsResponse {
  final List<TransitAlert> alerts;
  final int totalAlerts;
  final String fetchedAt;

  TransitAlertsResponse({
    required this.alerts,
    required this.totalAlerts,
    required this.fetchedAt,
  });

  factory TransitAlertsResponse.fromJson(Map<String, dynamic> json) {
    return TransitAlertsResponse(
      alerts: (json['alerts'] as List)
          .map((a) => TransitAlert.fromJson(a as Map<String, dynamic>))
          .toList(),
      totalAlerts: json['totalAlerts'] as int? ?? 0,
      fetchedAt: json['fetchedAt'] as String? ?? '',
    );
  }
}
