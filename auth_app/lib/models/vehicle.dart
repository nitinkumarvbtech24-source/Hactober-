import 'package:latlong2/latlong.dart';

class Vehicle {
  final String id;
  final String vehicleNumber;
  final String driverName;
  final String? phoneNumber;
  String assignedWard;
  LatLng? currentLocation;
  bool isActive;
  DateTime? lastHeartbeat;

  bool get isRunning {
    if (lastHeartbeat == null) return false;
    final diff = DateTime.now().difference(lastHeartbeat!);
    return diff.inMinutes < 3;
  }

  String get statusText {
    if (isRunning) {
      return isActive ? 'Active' : 'Idle';
    }
    return 'Offline';
  }

  Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.driverName,
    required this.assignedWard,
    this.phoneNumber,
    this.currentLocation,
    this.isActive = false,
    this.lastHeartbeat,
  });

  factory Vehicle.fromJson(String id, Map<String, dynamic> json) {
    LatLng? currLoc;
    if (json['lat'] != null && json['lng'] != null) {
      currLoc = LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());
    } else if (json['currentLocation'] != null) {
      currLoc = LatLng(
        (json['currentLocation']['lat'] as num).toDouble(),
        (json['currentLocation']['lng'] as num).toDouble(),
      );
    }

    DateTime? heartbeat;
    if (json['lastHeartbeat'] != null) {
      try {
        heartbeat = DateTime.parse(json['lastHeartbeat'].toString());
      } catch (_) {}
    }

    return Vehicle(
      id: id,
      vehicleNumber: json['vehicleNumber'] ?? id,
      driverName: json['driverName'] ?? 'Unassigned Driver',
      assignedWard: json['assignedWard'] ?? 'Ward 01',
      phoneNumber: json['phoneNumber'],
      currentLocation: currLoc,
      isActive: json['isActive'] ?? false,
      lastHeartbeat: heartbeat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleNumber': vehicleNumber,
      'driverName': driverName,
      'assignedWard': assignedWard,
      'phoneNumber': phoneNumber,
      'lat': currentLocation?.latitude,
      'lng': currentLocation?.longitude,
      'isActive': isActive,
      'lastHeartbeat': lastHeartbeat?.toIso8601String(),
    };
  }
}

