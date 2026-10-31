import 'package:latlong2/latlong.dart';

class Ward {
  final String id;
  final String name;
  final String zone;
  final String? supervisorName;
  final String? supervisorPhone;
  final DateTime createdAt;
  final List<LatLng> boundary;

  Ward({
    required this.id,
    required this.name,
    required this.zone,
    this.supervisorName,
    this.supervisorPhone,
    required this.createdAt,
    this.boundary = const [],
  });

  factory Ward.fromJson(String id, Map<String, dynamic> json) {
    DateTime created = DateTime.now();
    if (json['createdAt'] != null) {
      try {
        created = DateTime.parse(json['createdAt'].toString());
      } catch (_) {}
    }

    final List<LatLng> boundaryList = [];
    if (json['boundary'] is List) {
      for (var item in (json['boundary'] as List)) {
        if (item is Map && item['lat'] != null && item['lng'] != null) {
          boundaryList.add(LatLng(
            (item['lat'] as num).toDouble(),
            (item['lng'] as num).toDouble(),
          ));
        }
      }
    }

    return Ward(
      id: id,
      name: json['name'] ?? id,
      zone: json['zone'] ?? 'Central Zone',
      supervisorName: json['supervisorName'],
      supervisorPhone: json['supervisorPhone'],
      createdAt: created,
      boundary: boundaryList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'zone': zone,
      'supervisorName': supervisorName,
      'supervisorPhone': supervisorPhone,
      'createdAt': createdAt.toIso8601String(),
      'boundary': boundary.map((pt) => {'lat': pt.latitude, 'lng': pt.longitude}).toList(),
    };
  }
}
