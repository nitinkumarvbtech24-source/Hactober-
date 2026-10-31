class ReportModel {
  final String id;
  final String imageUrl;
  final String category; // pothole, garbage, others
  final double latitude;
  final double longitude;
  final String address;
  final String comment;
  final DateTime timestamp;
  final String userId;
  final String status; // Submitted, Under Review, Assigned, In Progress, Resolved

  ReportModel({
    required this.id,
    required this.imageUrl,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.comment,
    required this.timestamp,
    required this.userId,
    required this.status,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      comment: json['comment'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'status': status,
    };
  }
}
