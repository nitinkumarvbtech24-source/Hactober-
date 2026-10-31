import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

class GarbageFlag {
  final String id;
  final String filename;
  final String imageUrl;
  final String className;
  final String displayClass;
  final double confidence;
  final String timestamp;
  final double lat;
  final double lng;
  final String vehicleNumber;
  final String ward;
  final String zone;
  final String status;
  final dynamic modelVersion;
  final int trashCount;
  final bool isTrash;

  GarbageFlag({
    required this.id,
    required this.filename,
    required this.imageUrl,
    required this.className,
    required this.displayClass,
    required this.confidence,
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.vehicleNumber,
    required this.ward,
    this.zone = 'Unknown',
    required this.status,
    this.modelVersion = 7,
    this.trashCount = 1,
    this.isTrash = true,
  });

  static bool isTrashDetectedSpot({
    String? roadStatus,
    String? displayClass,
    String? className,
    int? trashCount,
  }) {
    final rs = (roadStatus ?? '').toLowerCase().trim();
    final dc = (displayClass ?? '').toLowerCase().trim();
    final cn = (className ?? '').toLowerCase().trim();

    if (rs.contains('no trash') || rs.contains('no_trash') || rs.contains('clean') || rs.contains('not a road') || rs.contains('no road') ||
        dc.contains('no trash') || dc.contains('no_trash') || dc.contains('clean') || dc.contains('not a road') || dc.contains('no road') ||
        cn.contains('no trash') || cn.contains('no_trash') || cn.contains('clean') || cn.contains('not a road') || cn.contains('no road')) {
      return false;
    }

    if (trashCount != null && trashCount <= 0 && !rs.contains('dirty') && !dc.contains('dirty') && !cn.contains('dirty')) {
      return false;
    }

    final hasTrashStatus = rs == 'trash detected' || rs.contains('trash detected') || rs == 'trash' || rs.contains('dirty');
    final hasDisplayTrash = dc == 'trash detected' || dc.contains('trash detected') || dc == 'trash' || dc.contains('dirty');
    final hasClassTrash = cn == 'trash_detected' || cn == 'trash' || cn.contains('dirty');

    return hasTrashStatus || hasDisplayTrash || hasClassTrash || (trashCount != null && trashCount > 0);
  }

  bool get isNoRoad =>
      displayClass.toLowerCase().contains('no road') ||
      className.toLowerCase().contains('no_road') ||
      status.toLowerCase().contains('no road');

  bool get isTrashReport => !isNoRoad && isTrash;

  bool get isTrashDetected {
    final s = status.toLowerCase();
    if (s == 'resolved' || s == 'deflagged' || s == 'cleaned' || s == 'no trash' || s.contains('no road')) return false;
    return isTrashReport;
  }

  bool get isCleanRoad => !isTrash && !isNoRoad;
  bool get isNoTrash => isCleanRoad;
  bool get isResolved => status.toLowerCase() == 'resolved' || status.toLowerCase() == 'cleaned';

  factory GarbageFlag.fromJson(Map<String, dynamic> json, [String? docId]) {
    String rawUrl = json['image_url']?.toString() ?? '';
    String resolvedUrl = '';
    
    if (rawUrl.isNotEmpty) {
      if (rawUrl.startsWith('/')) {
        resolvedUrl = '$activeGarbageAiUrl$rawUrl';
      } else if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        try {
          Uri parsed = Uri.parse(rawUrl);
          if (parsed.path.startsWith('/images/') || parsed.path.startsWith('/snapshots/')) {
            resolvedUrl = '$activeGarbageAiUrl${parsed.path}';
          } else {
            resolvedUrl = rawUrl;
          }
        } catch (_) {
          resolvedUrl = rawUrl;
        }
      }
    }

    final rawDisplayClass = (json['display_class'] ?? json['road_status']?.toString().replaceAll(' Road', '') ?? 'Unknown').toString();
    final rawClass = (json['class'] ?? json['road_status']?.toString().replaceAll(' Road', '').replaceAll(' ', '_') ?? 'Unknown').toString();
    final tCount = (json['trash_count'] as num?)?.toInt() ?? 1;

    final explicitIsTrash = json['is_trash'] as bool?;
    final bool calculatedIsTrash = explicitIsTrash ?? isTrashDetectedSpot(
      roadStatus: json['road_status']?.toString() ?? rawDisplayClass,
      displayClass: rawDisplayClass,
      className: rawClass,
      trashCount: tCount,
    );

    return GarbageFlag(
      id: docId ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      filename: json['filename'] ?? 'snapshot',
      imageUrl: resolvedUrl,
      className: rawClass,
      displayClass: rawDisplayClass,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] is Timestamp 
          ? (json['timestamp'] as Timestamp).toDate().toIso8601String() 
          : (json['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      vehicleNumber: json['vehicle_number'] ?? 'Unknown Vehicle',
      ward: json['ward'] ?? 'Unknown Ward',
      zone: json['zone'] ?? 'Unknown Zone',
      status: json['status'] ?? (calculatedIsTrash ? 'Flagged' : 'No Trash'),
      modelVersion: json['model_version'] ?? 8,
      trashCount: tCount,
      isTrash: calculatedIsTrash,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'image_url': imageUrl,
      'class': className,
      'display_class': displayClass,
      'confidence': confidence,
      'timestamp': timestamp,
      'lat': lat,
      'lng': lng,
      'vehicle_number': vehicleNumber,
      'ward': ward,
      'zone': zone,
      'status': status,
      'model_version': modelVersion,
      'trash_count': trashCount,
    };
  }
}
