import 'payment_model.dart';
import 'rating_model.dart';

enum BookingType { immediate, scheduled }
enum BookingStatus { pending, assigned, inProgress, completed, cancelled }

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending: return 'Pending';
      case BookingStatus.assigned: return 'Assigned';
      case BookingStatus.inProgress: return 'In Progress';
      case BookingStatus.completed: return 'Completed';
      case BookingStatus.cancelled: return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case BookingStatus.pending: return '⏳';
      case BookingStatus.assigned: return '👷';
      case BookingStatus.inProgress: return '🚚';
      case BookingStatus.completed: return '✅';
      case BookingStatus.cancelled: return '❌';
    }
  }
}

class BookingModel {
  final String id;
  final String userId;
  final BookingType type;
  final BookingStatus status;
  final String addressLine;
  final String? landmark;
  final double latitude;
  final double longitude;
  final String wasteType;
  final String quantity;
  final String? notes;
  final DateTime? scheduledAt;
  final String? collectorId;
  final String? collectorName;
  final String? collectorPhone;
  final String? collectorAvatar;
  final double? collectorRating;
  final double estimatedPrice;
  final double? finalPrice;
  final PaymentModel? payment;
  final RatingModel? rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.addressLine,
    this.landmark,
    required this.latitude,
    required this.longitude,
    required this.wasteType,
    required this.quantity,
    this.notes,
    this.scheduledAt,
    this.collectorId,
    this.collectorName,
    this.collectorPhone,
    this.collectorAvatar,
    this.collectorRating,
    required this.estimatedPrice,
    this.finalPrice,
    this.payment,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    BookingType parseType(String t) =>
        t == 'IMMEDIATE' ? BookingType.immediate : BookingType.scheduled;

    BookingStatus parseStatus(String s) {
      switch (s) {
        case 'ASSIGNED': return BookingStatus.assigned;
        case 'IN_PROGRESS': return BookingStatus.inProgress;
        case 'COMPLETED': return BookingStatus.completed;
        case 'CANCELLED': return BookingStatus.cancelled;
        default: return BookingStatus.pending;
      }
    }

    return BookingModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: parseType(json['type'] as String),
      status: parseStatus(json['status'] as String),
      addressLine: json['addressLine'] as String,
      landmark: json['landmark'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      wasteType: json['wasteType'] as String,
      quantity: json['quantity'] as String,
      notes: json['notes'] as String?,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : null,
      collectorId: json['collectorId'] as String?,
      collectorName: json['collectorName'] as String?,
      collectorPhone: json['collectorPhone'] as String?,
      collectorAvatar: json['collectorAvatar'] as String?,
      collectorRating: json['collectorRating'] != null
          ? (json['collectorRating'] as num).toDouble()
          : null,
      estimatedPrice: (json['estimatedPrice'] as num).toDouble(),
      finalPrice: json['finalPrice'] != null
          ? (json['finalPrice'] as num).toDouble()
          : null,
      payment: json['payment'] != null
          ? PaymentModel.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
      rating: json['rating'] != null
          ? RatingModel.fromJson(json['rating'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  BookingModel copyWith({BookingStatus? status}) {
    return BookingModel(
      id: id,
      userId: userId,
      type: type,
      status: status ?? this.status,
      addressLine: addressLine,
      landmark: landmark,
      latitude: latitude,
      longitude: longitude,
      wasteType: wasteType,
      quantity: quantity,
      notes: notes,
      scheduledAt: scheduledAt,
      collectorId: collectorId,
      collectorName: collectorName,
      collectorPhone: collectorPhone,
      collectorAvatar: collectorAvatar,
      collectorRating: collectorRating,
      estimatedPrice: estimatedPrice,
      finalPrice: finalPrice,
      payment: payment,
      rating: rating,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
