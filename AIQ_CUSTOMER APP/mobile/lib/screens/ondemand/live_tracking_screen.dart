import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

enum CollectionState {
  onTheWay,
  arrived,
  collecting,
  completed,
}

class LiveTrackingScreen extends StatefulWidget {
  final Map<String, dynamic>? rideDetails;

  const LiveTrackingScreen({super.key, this.rideDetails});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late LatLng _userLocation;
  late LatLng _riderLocation;
  late Map<String, dynamic> _rider;
  late String _pickupAddress;
  late String _bookingId;
  late int _fare;

  CollectionState _currentState = CollectionState.onTheWay;
  int _etaMinutes = 3;

  @override
  void initState() {
    super.initState();
    final coords = widget.rideDetails?['pickupCoords'] as Map<String, dynamic>?;
    final lat = coords?['lat'] as double? ?? 12.9716;
    final lng = coords?['lng'] as double? ?? 77.5946;
    _userLocation = LatLng(lat, lng);

    _rider = widget.rideDetails?['rider'] as Map<String, dynamic>? ?? {
      'name': 'Suresh Kumar',
      'rating': 4.9,
      'trips': '1,240 pickups',
      'vehicle': 'Green Eco Tipper',
      'plate': 'KA-04-TR-102',
      'phone': '+91 98765 43210',
      'etaMinutes': 3,
      'price': 64,
    };

    _fare = widget.rideDetails?['rider']?['price'] as int? ?? 64;
    _pickupAddress = widget.rideDetails?['pickupAddress'] as String? ?? 'Sapthagiri Layout, Main Road, Bengaluru';
    _bookingId = widget.rideDetails?['bookingId'] as String? ?? '#BK-998124';

    // Start rider slightly away
    _riderLocation = LatLng(lat + 0.0035, lng + 0.0038);

    _simulateRideArrival();
  }

  Future<void> _simulateRideArrival() async {
    // 1. Rider Moving closer step by step
    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        _riderLocation = LatLng(
          _riderLocation.latitude - 0.0008,
          _riderLocation.longitude - 0.0009,
        );
        _etaMinutes = (3 - (i * 0.8)).clamp(1, 3).toInt();
      });
      _mapController.move(_riderLocation, 15.5);
    }

    // 2. Arrived at Doorstep
    if (!mounted) return;
    setState(() {
      _riderLocation = _userLocation;
      _currentState = CollectionState.arrived;
      _etaMinutes = 0;
    });
    await Future.delayed(const Duration(seconds: 3));

    // 3. Collecting & Weighing waste
    if (!mounted) return;
    setState(() => _currentState = CollectionState.collecting);
    await Future.delayed(const Duration(seconds: 4));

    // 4. Completed
    if (!mounted) return;
    setState(() => _currentState = CollectionState.completed);
    await Future.delayed(const Duration(seconds: 2));

    // 5. Navigate to Payment
    if (!mounted) return;
    context.pushReplacement('/payment');
  }

  Future<void> _callRider() async {
    final phone = _rider['phone'] as String? ?? '+919876543210';
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling rider: $phone')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Live Map with Route Polyline
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.takemytrash.user',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_riderLocation, _userLocation],
                    color: AppColors.primary,
                    strokeWidth: 4.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // User Destination Marker
                  Marker(
                    point: _userLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  // Live Moving Rider Marker
                  Marker(
                    point: _riderLocation,
                    width: 56,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.local_shipping, color: AppColors.primary, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Status Bar & Close Button
          Positioned(
            top: MediaQuery.paddingOf(context).top + 14,
            left: 20,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12),
                      ],
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentState == CollectionState.onTheWay
                                ? 'Rider arriving in $_etaMinutes mins'
                                : (_currentState == CollectionState.arrived
                                    ? 'Rider has arrived at your gate!'
                                    : (_currentState == CollectionState.collecting
                                        ? 'Collecting & weighing waste...'
                                        : 'Pickup complete!')),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Tracking & Driver Details Sheet
          DraggableScrollableSheet(
            initialChildSize: isDesktop ? 0.48 : 0.42,
            minChildSize: isDesktop ? 0.35 : 0.28,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 680 : double.infinity,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, -10),
                        ),
                      ],
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // OTP Security Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Pickup Security OTP',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Share with rider upon arrival',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  '4829',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Driver Profile Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Center(
                                  child: Icon(Icons.person, color: Colors.white, size: 30),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _rider['name'] ?? 'Suresh Kumar',
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.star, size: 14, color: Colors.amber),
                                        Text(
                                          ' ${_rider['rating'] ?? 4.9}',
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_rider['vehicle']} • ${_rider['plate']}',
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _callRider,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.phone, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pickup Progress Timeline
                        const Text(
                          'Arrival & Pickup Progress',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              _buildTimelineStep(
                                title: 'Rider Dispatched',
                                subtitle: 'Confirmed & on the way',
                                isDone: true,
                                isActive: false,
                              ),
                              _buildTimelineStep(
                                title: 'On the Way (Live Tracking)',
                                subtitle: 'Driver approaching via main road',
                                isDone: _currentState != CollectionState.onTheWay,
                                isActive: _currentState == CollectionState.onTheWay,
                              ),
                              _buildTimelineStep(
                                title: 'Arrived at Doorstep',
                                subtitle: 'Share OTP 4829 with rider',
                                isDone: _currentState == CollectionState.collecting ||
                                    _currentState == CollectionState.completed,
                                isActive: _currentState == CollectionState.arrived,
                              ),
                              _buildTimelineStep(
                                title: 'Waste Collected & Weighed',
                                subtitle: 'Digital weighing scale verification',
                                isDone: _currentState == CollectionState.completed,
                                isActive: _currentState == CollectionState.collecting,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Fare & Location summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Doorstep Payment',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹$_fare',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              icon: const Icon(Icons.share_location, size: 16),
                              label: const Text('Share Trip', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12)),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Trip tracking link copied!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.success
                    : (isActive ? AppColors.primary : Colors.white),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone
                      ? AppColors.success
                      : (isActive ? AppColors.primary : AppColors.border),
                  width: 2,
                ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : (isActive
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isDone ? AppColors.success : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
