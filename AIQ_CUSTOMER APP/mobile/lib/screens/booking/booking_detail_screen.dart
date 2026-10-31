import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/app_button.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  BookingModel? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final b = await context.read<BookingProvider>().fetchBookingById(widget.bookingId);
      if (mounted) setState(() => _booking = b);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(BookingStatus s) {
    return switch (s) {
      BookingStatus.pending => AppColors.warning,
      BookingStatus.assigned => AppColors.info,
      BookingStatus.inProgress => AppColors.primary,
      BookingStatus.completed => AppColors.success,
      BookingStatus.cancelled => AppColors.error,
    };
  }

  String _getStatusDesc(BookingStatus s) {
    return switch (s) {
      BookingStatus.pending => 'Waiting for collector assignment',
      BookingStatus.assigned => 'Complete payment to proceed',
      BookingStatus.inProgress => 'Collector is on the way',
      BookingStatus.completed => 'Pickup was successful',
      BookingStatus.cancelled => 'This booking was cancelled',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
    }

    if (_booking == null) {
      return Scaffold(backgroundColor: AppColors.background, appBar: AppBar(title: const Text('Error')), body: const Center(child: Text('Booking not found')));
    }

    final b = _booking!;
    final color = _getStatusColor(b.status);
    final wasteLabel = b.wasteType.replaceFirst(RegExp(r'^[a-z]'), b.wasteType[0].toUpperCase());
    final quantityLabel = b.quantity.replaceFirst(RegExp(r'^[a-z]'), b.quantity[0].toUpperCase());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Booking Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color, width: 1.5)),
                child: Row(
                  children: [
                    Text(b.status.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.status.label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(_getStatusDesc(b.status), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Booking ID', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  Text(b.id.substring(0, 8).toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),

              // Details
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Type', value: b.type == BookingType.immediate ? '⚡ Immediate' : '📅 Scheduled'),
                    _InfoRow(label: 'Address', value: b.addressLine),
                    if (b.landmark != null) _InfoRow(label: 'Landmark', value: b.landmark!),
                    _InfoRow(label: 'Waste Type', value: wasteLabel),
                    _InfoRow(label: 'Quantity', value: quantityLabel),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (b.collectorName != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Collector', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: Center(child: Text(b.collectorName![0].toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.collectorName!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              if (b.collectorRating != null)
                                Text('⭐ ${b.collectorRating!.toStringAsFixed(1)} rating', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (b.status == BookingStatus.inProgress)
                AppButton(
                  label: 'Track Collector',
                  onPressed: () => context.push('/tracking', extra: b.id),
                )
              else if (b.status == BookingStatus.assigned)
                AppButton(
                  label: 'Complete Payment',
                  onPressed: () => context.push('/payment', extra: {'bookingId': b.id, 'booking': b}),
                )
              else if (b.status == BookingStatus.completed && b.rating == null)
                AppButton(
                  label: 'Rate Your Experience',
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.push('/rating', extra: b.id),
                )
              else if (b.status == BookingStatus.pending || b.status == BookingStatus.assigned)
                AppButton(
                  label: 'Cancel Booking',
                  variant: AppButtonVariant.danger,
                  onPressed: () async {
                    await context.read<BookingProvider>().cancelBooking(b.id);
                    if (mounted) context.pop();
                  },
                ),
            ],
          ),
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
