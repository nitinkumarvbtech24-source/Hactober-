import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class BookingAddressScreen extends StatefulWidget {
  final String type;
  const BookingAddressScreen({super.key, required this.type});

  @override
  State<BookingAddressScreen> createState() => _BookingAddressScreenState();
}

class _BookingAddressScreenState extends State<BookingAddressScreen> {
  final _addressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _mapController = MapController();
  
  Map<String, dynamic>? _selectedAddress;
  bool _showSuggestions = false;
  bool _isDragging = false;
  LatLng _currentCenter = const LatLng(12.9716, 77.5946);

  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoadingSuggestions = false;

  Future<void> _fetchSuggestions(String query) async {
    setState(() {
      _isLoadingSuggestions = true;
      _showSuggestions = true;
    });
    try {
      final res = await Dio().get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 5,
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'TakeMyTrashApp/1.0'}),
      );
      if (res.data != null && res.data is List) {
        if (mounted) {
          setState(() {
            _suggestions = (res.data as List).map((item) => {
              'label': item['display_name'] ?? '',
              'lat': double.tryParse(item['lat'] ?? '0') ?? 0.0,
              'lng': double.tryParse(item['lon'] ?? '0') ?? 0.0,
            }).toList();
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoadingSuggestions = false;
      });
    }
  }

  void _handleSelectAddress(Map<String, dynamic> suggestion) {
    setState(() {
      _selectedAddress = suggestion;
      _addressCtrl.text = suggestion['label'];
      _showSuggestions = false;
      if (suggestion['lat'] != null && suggestion['lng'] != null) {
        _currentCenter = LatLng(suggestion['lat'], suggestion['lng']);
        _mapController.move(_currentCenter, 15.0);
      }
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final res = await Dio().get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': pos.latitude,
          'lon': pos.longitude,
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'TakeMyTrashApp/1.0'}),
      );
      if (res.data != null && res.data['display_name'] != null) {
        if (mounted) {
          setState(() {
            final address = res.data['display_name'];
            _addressCtrl.text = address;
            _selectedAddress = {
              'label': address,
              'lat': pos.latitude,
              'lng': pos.longitude,
            };
          });
        }
      }
    } catch (_) {}
  }

  void _handleNext() {
    if (_selectedAddress == null && _addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select an address')),
      );
      return;
    }
    
    context.push('/booking-details', extra: {
      'type': widget.type,
      'address': _selectedAddress?['label'] ?? _addressCtrl.text,
      'landmark': _landmarkCtrl.text.isEmpty ? null : _landmarkCtrl.text,
      'latitude': _selectedAddress?['lat'] ?? 12.9716,
      'longitude': _selectedAddress?['lng'] ?? 77.5946,
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isImmediate = widget.type == 'IMMEDIATE';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isImmediate ? '⚡ Immediate' : '📅 Scheduled',
                style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            const Text('Where\'s the pickup?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                    AppTextField(
                      label: 'Pickup Address',
                      hint: 'Search for your address...',
                      controller: _addressCtrl,
                      prefixIcon: Icons.location_on_outlined,
                      onChanged: (v) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        setState(() => _selectedAddress = null);
                        _debounce = Timer(const Duration(milliseconds: 600), () {
                          if (v.length > 2) {
                            _fetchSuggestions(v);
                          } else {
                            setState(() {
                              _suggestions = [];
                              _showSuggestions = false;
                            });
                          }
                        });
                      },
                      onTap: () {
                        if (_selectedAddress == null) {
                          setState(() => _showSuggestions = true);
                        }
                      },
                    ),

                    if (_showSuggestions && _addressCtrl.text.length > 2)
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 12)),
                          ],
                        ),
                        child: _isLoadingSuggestions
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                              )
                            : _suggestions.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(child: Text('No addresses found', style: TextStyle(color: AppColors.textSecondary))),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _suggestions.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                                    itemBuilder: (context, index) {
                                      final s = _suggestions[index];
                                      final shortName = s['label'].split(',').first;
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                                        ),
                                        title: Text(
                                          shortName, 
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Plus Jakarta Sans'),
                                        ),
                                        subtitle: Text(
                                          s['label'], 
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Plus Jakarta Sans', height: 1.4),
                                          maxLines: 2, overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () => _handleSelectAddress(s),
                                      );
                                    },
                                  ),
                      ),

                    AppTextField(
                      label: 'Landmark (Optional)',
                      hint: 'e.g. Near Apollo Hospital',
                      controller: _landmarkCtrl,
                      prefixIcon: Icons.flag_outlined,
                    ),

                    if (_selectedAddress != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Selected Location',
                                      style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(_selectedAddress!['label'],
                                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Map Preview
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _currentCenter,
                                initialZoom: 15.0,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.all,
                                ),
                                onTap: (tapPosition, point) {
                                  _currentCenter = point;
                                  _mapController.move(point, 15.0);
                                  _reverseGeocode(point);
                                },
                                onPositionChanged: (pos, hasGesture) {
                                  if (hasGesture && pos.center != null) {
                                    _currentCenter = pos.center!;
                                  }
                                },
                                onMapEvent: (event) {
                                  if (event is MapEventMoveStart) {
                                    setState(() => _isDragging = true);
                                  } else if (event is MapEventMoveEnd) {
                                    setState(() => _isDragging = false);
                                    _reverseGeocode(_currentCenter);
                                  }
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.takemytrash',
                                ),
                              ],
                            ),
                            IgnorePointer(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 40),
                                  child: Icon(
                                    Icons.location_pin,
                                    size: 40,
                                    color: _isDragging ? AppColors.primary.withOpacity(0.5) : AppColors.primary,
                                  ),
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
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                label: 'Continue',
                onPressed: _addressCtrl.text.isNotEmpty ? _handleNext : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
