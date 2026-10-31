import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/socket_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/booking_provider.dart';

class TrackingScreen extends StatefulWidget {
  final String bookingId;
  const TrackingScreen({super.key, required this.bookingId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with SingleTickerProviderStateMixin {
  BookingModel? _booking;
  Map<String, dynamic>? _collectorLocation;
  String _pickupStatus = 'in_progress';
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    
    _loadBooking();
    
    SocketService.joinBookingRoom(widget.bookingId);
    SocketService.on('collector_location', _onLocationUpdate);
    SocketService.on('pickup_completed', _onPickupCompleted);
  }

  Future<void> _loadBooking() async {
    try {
      final b = await context.read<BookingProvider>().fetchBookingById(widget.bookingId);
      if (mounted) setState(() => _booking = b);
    } catch (_) {}
  }

  void _onLocationUpdate(dynamic data) {
    if (mounted) setState(() => _collectorLocation = data as Map<String, dynamic>);
  }

  void _onPickupCompleted(dynamic data) {
    if (data['bookingId'] != widget.bookingId) return;
    if (mounted) {
      setState(() => _pickupStatus = 'completed');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.pushReplacement('/rating', extra: widget.bookingId);
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    SocketService.off('collector_location');
    SocketService.off('pickup_completed');
    SocketService.leaveBookingRoom(widget.bookingId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _collectorLocation != null
                    ? LatLng(_collectorLocation!['lat'], _collectorLocation!['lng'])
                    : const LatLng(12.9716, 77.5946), // default to Bangalore
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.takemytrash',
                ),
                if (_collectorLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_collectorLocation!['lat'], _collectorLocation!['lng']),
                        width: 60,
                        height: 60,
                        child: const Text('🚚', style: TextStyle(fontSize: 40)),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
            ),
          ),

          // ETA Chip
          if (_collectorLocation != null && _collectorLocation!['eta'] != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Text('ETA: ${_collectorLocation!['eta']} min', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_pickupStatus == 'completed')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary)),
                      child: Row(
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 36)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Pickup Completed!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                Text('Redirecting to rating screen...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        ScaleTransition(
                          scale: Tween<double>(begin: 1, end: 1.2).animate(_pulseCtrl),
                          child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                        ),
                        const SizedBox(width: 12),
                        Text(_collectorLocation != null ? 'Collector is on the way' : 'Tracking collector...', style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  
                  if (_booking != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: Center(child: Text(_booking!.collectorName?[0].toUpperCase() ?? 'C', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_booking!.collectorName ?? 'Your Collector', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text('⭐ ${_booking!.collectorRating?.toStringAsFixed(1) ?? '5.0'} • ${_booking!.type == BookingType.immediate ? '⚡ Immediate' : '📅 Scheduled'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          if (_booking!.collectorPhone != null)
                            GestureDetector(
                              onTap: () => launchUrl(Uri.parse('tel:${_booking!.collectorPhone}')),
                              child: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.call, color: Colors.white, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
