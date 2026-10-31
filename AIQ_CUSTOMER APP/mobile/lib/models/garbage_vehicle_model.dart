class GarbageVehicleModel {
  final String vehicleId;
  final String vehicleNumber;
  final double currentLatitude;
  final double currentLongitude;
  final String status; // Active, On Route, Collecting, Idle, Offline, Maintenance
  final int etaMinutes;
  final String assignedRoute;
  final DateTime lastUpdatedTimestamp;

  GarbageVehicleModel({
    required this.vehicleId,
    required this.vehicleNumber,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.status,
    required this.etaMinutes,
    required this.assignedRoute,
    required this.lastUpdatedTimestamp,
  });

  factory GarbageVehicleModel.fromJson(Map<String, dynamic> json) {
    return GarbageVehicleModel(
      vehicleId: json['vehicleId'] as String,
      vehicleNumber: json['vehicleNumber'] as String,
      currentLatitude: (json['currentLatitude'] as num).toDouble(),
      currentLongitude: (json['currentLongitude'] as num).toDouble(),
      status: json['status'] as String,
      etaMinutes: json['etaMinutes'] as int,
      assignedRoute: json['assignedRoute'] as String,
      lastUpdatedTimestamp: DateTime.parse(json['lastUpdatedTimestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'vehicleNumber': vehicleNumber,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'status': status,
      'etaMinutes': etaMinutes,
      'assignedRoute': assignedRoute,
      'lastUpdatedTimestamp': lastUpdatedTimestamp.toIso8601String(),
    };
  }
}
