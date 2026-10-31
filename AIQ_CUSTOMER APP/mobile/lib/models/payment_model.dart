enum PaymentStatus { pending, success, failed, refunded }

class PaymentModel {
  final String id;
  final String bookingId;
  final String orderId;
  final String? paymentId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.orderId,
    this.paymentId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    PaymentStatus parseStatus(String s) {
      switch (s) {
        case 'SUCCESS': return PaymentStatus.success;
        case 'FAILED': return PaymentStatus.failed;
        case 'REFUNDED': return PaymentStatus.refunded;
        default: return PaymentStatus.pending;
      }
    }

    return PaymentModel(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      orderId: json['orderId'] as String,
      paymentId: json['paymentId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      status: parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
