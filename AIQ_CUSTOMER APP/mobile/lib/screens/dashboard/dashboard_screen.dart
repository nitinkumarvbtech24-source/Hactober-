import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../widgets/app_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchBookings();
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Color _statusColor(BookingStatus s) {
    return switch (s) {
      BookingStatus.pending => AppColors.warning,
      BookingStatus.assigned => AppColors.info,
      BookingStatus.inProgress => AppColors.primary,
      BookingStatus.completed => AppColors.success,
      BookingStatus.cancelled => AppColors.error,
    };
  }

  void _onBookingTap(BookingModel b) {
    if (b.status == BookingStatus.inProgress) {
      context.push('/tracking', extra: b.id);
    } else if (b.status == BookingStatus.assigned) {
      context.push('/payment', extra: {'bookingId': b.id, 'booking': b});
    } else {
      context.push('/booking-detail', extra: b.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bookings = context.watch<BookingProvider>();
    final active = bookings.activeBookings;
    final recent = bookings.bookings.take(3).toList();
    final name = auth.user?.name.split(' ').first ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () => bookings.fetchBookings(),
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          '$name 👋',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: AppColors.textSecondary, size: 22),
                    ),
                  ],
                ),
              ),
            ),

            // Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    _StatCard(
                      value: bookings.bookings
                          .where((b) => b.status == BookingStatus.completed)
                          .length
                          .toString(),
                      label: 'Completed',
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: active.length.toString(),
                      label: 'Active',
                      isHighlighted: true,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value:
                          '₹${bookings.bookings.fold(0.0, (s, b) => s + (b.finalPrice ?? 0)).toStringAsFixed(0)}',
                      label: 'Spent',
                    ),
                  ],
                ),
              ),
            ),

            // Book CTA with Parallax Depth
            SliverToBoxAdapter(
              child: StreamBuilder<AccelerometerEvent>(
                stream: accelerometerEventStream(),
                builder: (context, snapshot) {
                  final double xOffset = (snapshot.data?.x ?? 0) * -1.5;
                  final double yOffset = (snapshot.data?.y ?? 0) * -1.5;

                  return GestureDetector(
                    onTap: () => context.push('/book-pickup'),
                    child: Transform.translate(
                      offset: Offset(xOffset.clamp(-15.0, 15.0), yOffset.clamp(-15.0, 15.0)),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Book a Pickup',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Immediate or scheduled — your choice',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('🚚', style: TextStyle(fontSize: 30)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
      ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            emoji: '⚡',
                            title: 'Immediate',
                            subtitle: 'Pickup now',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/booking-address', extra: 'IMMEDIATE');
                            },
                          ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            emoji: '📅',
                            title: 'Schedule',
                            subtitle: 'Pick a time',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/booking-address', extra: 'SCHEDULED');
                            },
                          ).animate().fade(delay: 150.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            emoji: '📋',
                            title: 'History',
                            subtitle: 'All bookings',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.go('/history');
                            },
                          ).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Active Bookings
            if (active.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Text(
                    'Active Bookings',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                    child: _ActiveCard(
                        booking: active[i],
                        onTap: () => _onBookingTap(active[i])),
                  ),
                  childCount: active.length,
                ),
              ),
            ],

            // Recent
            if (recent.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Pickups',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/history'),
                        child: const Text(
                          'See all',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: _RecentCard(
                        booking: recent[i],
                        onTap: () => context.push('/booking-detail',
                            extra: recent[i].id)),
                  ),
                  childCount: recent.length,
                ),
              ),
            ],

            // Loading state (Shimmer)
            if (bookings.isLoading && bookings.bookings.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Shimmer.fromColors(
                    baseColor: AppColors.surface,
                    highlightColor: AppColors.surfaceElevated,
                    child: Column(
                      children: List.generate(
                        2,
                        (index) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Empty state
            if (bookings.bookings.isEmpty && !bookings.isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  child: Column(
                    children: [
                      // Stunning visual empty state
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: AppColors.border, width: 2),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 40, spreadRadius: 10),
                          ],
                        ),
                        child: const Center(
                          child: Text('🌿', style: TextStyle(fontSize: 50)),
                        ),
                      ).animate().fade(duration: 500.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                      const SizedBox(height: 24),
                      const Text(
                        'Your Canvas is Clean',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.2),
                      const SizedBox(height: 12),
                      const Text(
                        'Book your first pickup and help us build a greener, cleaner world today.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                        textAlign: TextAlign.center,
                      ).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2),
                    ],
                  ),
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final bool isHighlighted;

  const _StatCard({
    required this.value,
    required this.label,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isHighlighted ? AppColors.primary : AppColors.textPrimary).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isHighlighted ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isHighlighted ? Colors.white70 : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _ActiveCard({required this.booking, required this.onTap});

  Color get _statusColor {
    return switch (booking.status) {
      BookingStatus.pending => AppColors.warning,
      BookingStatus.assigned => AppColors.info,
      BookingStatus.inProgress => AppColors.primary,
      _ => AppColors.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${booking.status.emoji} ${booking.status.label}',
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  booking.type == BookingType.immediate
                      ? '⚡ Immediate'
                      : '📅 Scheduled',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '📍 ${booking.addressLine}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${booking.estimatedPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status == BookingStatus.inProgress
                        ? 'Track Now →'
                        : 'View Details →',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _RecentCard({required this.booking, required this.onTap});

  Color get _statusColor {
    return switch (booking.status) {
      BookingStatus.completed => AppColors.success,
      BookingStatus.cancelled => AppColors.error,
      _ => AppColors.warning,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(booking.status.emoji,
                style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${booking.wasteType[0].toUpperCase()}${booking.wasteType.substring(1)} Waste',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking.addressLine,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${booking.estimatedPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.status.label,
                  style:
                      TextStyle(fontSize: 11, color: _statusColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
