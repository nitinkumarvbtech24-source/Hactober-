import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class RiderMatchingScreen extends StatefulWidget {
  final Map<String, dynamic>? bookingDetails;

  const RiderMatchingScreen({super.key, this.bookingDetails});

  @override
  State<RiderMatchingScreen> createState() => _RiderMatchingScreenState();
}

class _RiderMatchingScreenState extends State<RiderMatchingScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late LatLng _userPickupLocation;
  String _pickupAddress = 'Sapthagiri Layout, Bengaluru';
  int _selectedRiderIndex = 0;
  bool _isConfirming = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Surrounding pickup riders (Ola / Uber style)
  late List<Map<String, dynamic>> _nearbyRiders;

  @override
  void initState() {
    super.initState();
    final lat = widget.bookingDetails?['lat'] as double? ?? 12.9716;
    final lng = widget.bookingDetails?['lng'] as double? ?? 77.5946;
    _userPickupLocation = LatLng(lat, lng);
    _pickupAddress = widget.bookingDetails?['address'] as String? ?? 'Sapthagiri Layout, Bengaluru';

    // Surrounding riders positioned realistically relative to user coordinates
    _nearbyRiders = [
      {
        'id': 'rider_1',
        'name': 'Suresh Kumar',
        'rating': 4.9,
        'trips': '1,240 pickups',
        'vehicle': 'Green Eco Tipper',
        'plate': 'KA-04-TR-102',
        'etaMinutes': 3,
        'distance': '0.6 km away',
        'price': widget.bookingDetails?['fare'] ?? 49,
        'icon': '🚛',
        'type': 'Eco Tipper (Quick Pickup)',
        'location': LatLng(lat + 0.0035, lng + 0.0038),
        'phone': '+91 98765 43210',
      },
      {
        'id': 'rider_2',
        'name': 'Ramesh Gowda',
        'rating': 4.8,
        'trips': '890 pickups',
        'vehicle': 'Eco Cargo Auto',
        'plate': 'KA-01-EA-554',
        'etaMinutes': 5,
        'distance': '1.2 km away',
        'price': (widget.bookingDetails?['fare'] ?? 49) + 30,
        'icon': '🛺',
        'type': 'Cargo Auto (Bulk Load)',
        'location': LatLng(lat - 0.0028, lng - 0.0035),
        'phone': '+91 98450 11223',
      },
      {
        'id': 'rider_3',
        'name': 'Arun Kumar',
        'rating': 4.9,
        'trips': '2,100 pickups',
        'vehicle': 'Heavy Tipper Van',
        'plate': 'KA-05-WT-882',
        'etaMinutes': 8,
        'distance': '1.9 km away',
        'price': (widget.bookingDetails?['fare'] ?? 49) + 90,
        'icon': '🚚',
        'type': 'Heavy Tipper (Large Load)',
        'location': LatLng(lat - 0.0045, lng + 0.0050),
        'phone': '+91 99001 22334',
      },
    ];

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _recenterToUser() {
    _mapController.move(_userPickupLocation, 15.0);
  }

  void _confirmRider() async {
    setState(() => _isConfirming = true);
    final confirmedRider = _nearbyRiders[_selectedRiderIndex];

    // Simulate instant dispatch handshake with rider
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // Transition to the live arrival tracking map screen
    context.pushReplacement('/tracking_live', extra: {
      'rider': confirmedRider,
      'pickupCoords': {
        'lat': _userPickupLocation.latitude,
        'lng': _userPickupLocation.longitude,
      },
      'pickupAddress': _pickupAddress,
      'bookingId': '#BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;
    final confirmedRider = _nearbyRiders[_selectedRiderIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Full-screen Interactive Ola/Uber Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userPickupLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.takemytrash.user',
              ),

              // Connect line between user and selected rider
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      confirmedRider['location'] as LatLng,
                      _userPickupLocation,
                    ],
                    color: AppColors.primary.withOpacity(0.6),
                    strokeWidth: 3.5,
                  ),
                ],
              ),

              MarkerLayer(
                markers: [
                  // User Pickup Location Marker
                  Marker(
                    point: _userPickupLocation,
                    width: 60,
                    height: 60,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.25),
                            ),
                            child: Center(
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Surrounding Pickup Riders on Map
                  ..._nearbyRiders.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final rider = entry.value;
                    final isSelected = idx == _selectedRiderIndex;
                    final riderLoc = rider['location'] as LatLng;

                    return Marker(
                      point: riderLoc,
                      width: 80,
                      height: 70,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedRiderIndex = idx);
                          _mapController.move(riderLoc, 15.0);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ETA Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? Colors.white : AppColors.border,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${rider['etaMinutes']} min',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Vehicle Marker Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : AppColors.primary,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  rider['icon'],
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. Top Navigation Bar (Pickup Info & Back)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Pickup Location',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _pickupAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Recenter Button
          Positioned(
            right: isDesktop ? 480 : 20,
            bottom: isDesktop ? 30 : 360,
            child: GestureDetector(
              onTap: _recenterToUser,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.my_location, color: AppColors.primary, size: 22),
              ),
            ),
          ),

          // 4. Ola / Uber Style Rider Selection Panel
          if (isDesktop)
            // Desktop Side Panel (Right Hand Side)
            Positioned(
              right: 24,
              top: MediaQuery.paddingOf(context).top + 16,
              bottom: 24,
              width: 440,
              child: _buildBookingSheetContent(confirmedRider),
            )
          else
            // Mobile Bottom Sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBookingSheetContent(confirmedRider),
            ),
        ],
      ),
    );
  }

  // RIDER BOOKING & CONFIRMATION PANEL (Ola / Uber Style)
  Widget _buildBookingSheetContent(Map<String, dynamic> confirmedRider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Surrounding Pickup Riders',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_nearbyRiders.length} drivers nearby ready to pick up waste',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, size: 8, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Live Fleet',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rider / Vehicle Cards (Uber Style)
          ..._nearbyRiders.asMap().entries.map((entry) {
            final idx = entry.key;
            final rider = entry.value;
            final isSelected = idx == _selectedRiderIndex;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedRiderIndex = idx);
                _mapController.move(rider['location'] as LatLng, 15.0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(rider['icon'], style: const TextStyle(fontSize: 24)),
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
                                rider['name'],
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 13, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${rider['rating']}',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${rider['vehicle']} • ${rider['plate']} • ${rider['distance']}',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${rider['price']}',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${rider['etaMinutes']} min away',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),

          // Payment Option Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: const [
                Icon(Icons.payments_outlined, color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Doorstep Payment • Cash / UPI accepted upon weighing',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.check_circle, color: AppColors.success, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Rider Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isConfirming ? null : _confirmRider,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isConfirming
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Confirming Driver...',
                          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    )
                  : Text(
                      'Confirm Rider (${confirmedRider['name'].toString().split(' ').first}) • ₹${confirmedRider['price']}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
