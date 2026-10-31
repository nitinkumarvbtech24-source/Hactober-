import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchBookings();
    });
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

  @override
  Widget build(BuildContext context) {
    final bookingsProvider = context.watch<BookingProvider>();
    final bookings = bookingsProvider.bookings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking History', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Text(
                '${bookingsProvider.total} total',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
      body: bookingsProvider.isLoading && bookings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () => bookingsProvider.fetchBookings(),
              child: bookings.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        const Center(child: Text('📭', style: TextStyle(fontSize: 64))),
                        const SizedBox(height: 16),
                        const Center(child: Text('No bookings yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                        const SizedBox(height: 8),
                        const Center(child: Text('Your pickup history will appear here', style: TextStyle(color: AppColors.textSecondary))),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms)
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final b = bookings[index];
                        final color = _getStatusColor(b.status);
                        final dateStr = b.createdAt.toString().split(' ')[0]; // Simplified for demo
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Slidable(
                            key: ValueKey(b.id),
                            endActionPane: ActionPane(
                              motion: const StretchMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (_) {
                                    HapticFeedback.mediumImpact();
                                    // Handle cancel logic
                                  },
                                  backgroundColor: AppColors.error.withOpacity(0.15),
                                  foregroundColor: AppColors.error,
                                  icon: Icons.cancel_outlined,
                                  label: 'Cancel',
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ],
                            ),
                            startActionPane: ActionPane(
                              motion: const StretchMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (_) {
                                    HapticFeedback.lightImpact();
                                    context.push('/tracking', extra: b.id);
                                  },
                                  backgroundColor: AppColors.primary.withOpacity(0.15),
                                  foregroundColor: AppColors.primary,
                                  icon: Icons.location_on_outlined,
                                  label: 'Track',
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onTap: () => context.push('/booking-detail', extra: b.id),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.textPrimary.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(b.type == BookingType.immediate ? '⚡ Immediate' : '📅 Scheduled', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text('${b.status.emoji} ${b.status.label}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text('📍 ${b.addressLine}', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('${b.wasteType[0].toUpperCase()}${b.wasteType.substring(1)} • ${b.quantity[0].toUpperCase()}${b.quantity.substring(1)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('₹${(b.finalPrice ?? b.estimatedPrice).toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                            const SizedBox(height: 2),
                                            Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: (50 * index).ms, duration: 400.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad, duration: 400.ms);
                      },
                    ),
            ),
    );
  }
}
