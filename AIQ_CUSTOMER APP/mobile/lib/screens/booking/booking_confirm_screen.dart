import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/app_button.dart';

class BookingConfirmScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const BookingConfirmScreen({super.key, required this.params});

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  bool _agreed = false;

  void _handleConfirm() async {
    if (!_agreed) return;

    final provider = context.read<BookingProvider>();
    try {
      final booking = await provider.createBooking(
        type: widget.params['type'] == 'IMMEDIATE' ? BookingType.immediate : BookingType.scheduled,
        addressLine: widget.params['address'],
        landmark: widget.params['landmark'],
        latitude: widget.params['latitude'],
        longitude: widget.params['longitude'],
        wasteType: widget.params['wasteType'],
        quantity: widget.params['quantity'],
        notes: widget.params['notes'],
        scheduledAt: widget.params['scheduledAt'] != null 
            ? DateTime.parse(widget.params['scheduledAt']) 
            : null,
      );

      if (mounted) {
        context.pushReplacement('/assigning', extra: booking.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to book')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImmediate = widget.params['type'] == 'IMMEDIATE';
    final estimatedPrice = widget.params['estimatedPrice'] as double;
    final wasteLabel = (widget.params['wasteType'] as String).replaceFirst(RegExp(r'^[a-z]'), (widget.params['wasteType'] as String)[0].toUpperCase());
    final quantityLabel = (widget.params['quantity'] as String).replaceFirst(RegExp(r'^[a-z]'), (widget.params['quantity'] as String)[0].toUpperCase());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Almost there!', style: TextStyle(fontSize: 12, color: AppColors.primary)),
            Text('Confirm Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Text(isImmediate ? '⚡ Immediate Pickup' : '📅 Scheduled Pickup',
                          style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 16),

                    // Details Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pickup Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          _InfoRow(label: '📍 Address', value: widget.params['address']),
                          if (widget.params['landmark'] != null)
                            _InfoRow(label: '🚩 Landmark', value: widget.params['landmark']),
                          _InfoRow(label: '🗑️ Waste Type', value: '$wasteLabel Waste'),
                          _InfoRow(label: '📦 Quantity', value: quantityLabel),
                          if (widget.params['scheduledAt'] != null)
                            _InfoRow(label: '🕐 Scheduled', value: widget.params['scheduledAt']),
                          if (widget.params['notes'] != null)
                            _InfoRow(label: '📝 Notes', value: widget.params['notes']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Price Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          _PriceRow(label: 'Base pickup fee', value: '₹49'),
                          _PriceRow(label: '$wasteLabel × $quantityLabel', value: '₹${estimatedPrice - 49}'),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              Text('₹$estimatedPrice', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('* Payment will be collected after collector is assigned',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Agreement
                    GestureDetector(
                      onTap: () => setState(() => _agreed = !_agreed),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: _agreed ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _agreed ? AppColors.primary : AppColors.border, width: 2),
                            ),
                            child: _agreed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'I agree to the Terms of Service and understand that cancellation after collector assignment may incur a fee.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                            ),
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
              child: Consumer<BookingProvider>(
                builder: (context, provider, _) => AppButton(
                  label: 'Confirm & Book Pickup',
                  onPressed: _agreed ? _handleConfirm : null,
                  isLoading: provider.isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
