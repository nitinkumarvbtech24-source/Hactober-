class RatingModel {
  final String id;
  final String bookingId;
  final String userId;
  final int stars;
  final String? comment;
  final DateTime createdAt;

  const RatingModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.stars,
    this.comment,
    required this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      userId: json['userId'] as String,
      stars: json['stars'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
