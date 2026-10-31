import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../widgets/app_button.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final BookingModel booking;
  const PaymentScreen({super.key, required this.bookingId, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.instance.post('/payments/create-order', data: {'bookingId': widget.bookingId});
      final orderId = res.data['data']['orderId'];

      await ApiClient.instance.post('/payments/verify', data: {
        'orderId': orderId,
        'paymentId': 'pay_${DateTime.now().millisecondsSinceEpoch}',
        'signature': 'demo_signature',
        'bookingId': widget.bookingId,
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: AppColors.success, size: 64),
              SizedBox(height: 16),
              Text('Payment is done!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              SizedBox(height: 8),
              Text('Your collector is on the way.', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context); // Close the success dialog
      context.pushReplacement('/tracking', extra: widget.bookingId);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Secure checkout via Razorpay', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Collector Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: Center(child: Text(widget.booking.collectorName?[0].toUpperCase() ?? 'C', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Your Collector', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                                Text(widget.booking.collectorName ?? 'Assigned', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text('⭐ ${widget.booking.collectorRating?.toStringAsFixed(1) ?? '5.0'} rating', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          if (widget.booking.collectorPhone != null)
                            GestureDetector(
                              onTap: () => launchUrl(Uri.parse('tel:${widget.booking.collectorPhone}')),
                              child: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary)),
                                child: const Icon(Icons.call, color: AppColors.primary, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Pickup Fee', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                              Text('₹49', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Waste Handling', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                              Text('₹${widget.booking.estimatedPrice - 49}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                              Text('₹${widget.booking.estimatedPrice}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                label: 'Pay ₹${widget.booking.estimatedPrice} →',
                onPressed: _handlePayment,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
