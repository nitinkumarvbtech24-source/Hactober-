import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/network/socket_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';

class AssigningCollectorScreen extends StatefulWidget {
  final String bookingId;
  const AssigningCollectorScreen({super.key, required this.bookingId});

  @override
  State<AssigningCollectorScreen> createState() => _AssigningCollectorScreenState();
}

class _AssigningCollectorScreenState extends State<AssigningCollectorScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);

    SocketService.joinBookingRoom(widget.bookingId);
    SocketService.on('booking_assigned', _onAssigned);

    // Polling fallback
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkStatus());
  }

  void _onAssigned(dynamic data) async {
    if (data['bookingId'] != widget.bookingId) return;
    await _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final booking = await context.read<BookingProvider>().fetchBookingById(widget.bookingId);
      if (booking.status == BookingStatus.assigned && mounted) {
        context.pushReplacement('/payment', extra: {'bookingId': widget.bookingId, 'booking': booking});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _pollTimer?.cancel();
    SocketService.off('booking_assigned');
    SocketService.leaveBookingRoom(widget.bookingId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 1, end: 1.5).animate(_pulseCtrl),
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2)),
                      ),
                    ),
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.2, end: 1.8).animate(_pulseCtrl),
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2)),
                      ),
                    ),
                    Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Center(child: Text('🚚', style: TextStyle(fontSize: 40))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('Finding your collector...',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              const Text('We\'re matching you with the nearest available collector. This usually takes less than 2 minutes.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 48),

              // Steps
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: const [
                    _Step(icon: '✅', label: 'Booking created', done: true),
                    SizedBox(height: 16),
                    _Step(icon: '🔍', label: 'Finding nearest collector', done: false, active: true),
                    SizedBox(height: 16),
                    _Step(icon: '👷', label: 'Collector assigned', done: false),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Booking ID: ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  Text(widget.bookingId.substring(0, 8).toUpperCase(),
                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  await context.read<BookingProvider>().cancelBooking(widget.bookingId);
                  if (mounted) context.go('/dashboard');
                },
                child: const Text('Cancel Booking', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String icon;
  final String label;
  final bool done;
  final bool active;
  const _Step({required this.icon, required this.label, this.done = false, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.primary : Colors.transparent,
            border: Border.all(color: done || active ? AppColors.primary : AppColors.border, width: 2),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : (active ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)) : null),
          ),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: done || active ? FontWeight.w600 : FontWeight.w400,
          color: done ? AppColors.success : (active ? AppColors.primary : AppColors.textMuted),
        )),
      ],
    );
  }
}
