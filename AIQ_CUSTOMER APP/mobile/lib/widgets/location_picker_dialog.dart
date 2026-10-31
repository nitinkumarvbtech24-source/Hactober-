import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/app_theme.dart';
import 'app_button.dart';
import 'responsive_layout.dart';

class PickedLocationResult {
  final String address;
  final double latitude;
  final double longitude;

  const PickedLocationResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class LocationPickerDialog extends StatefulWidget {
  final LatLng initialLocation;
  final String? initialAddress;

  const LocationPickerDialog({
    super.key,
    required this.initialLocation,
    this.initialAddress,
  });

  static Future<PickedLocationResult?> show(
    BuildContext context, {
    LatLng initialLocation = const LatLng(12.9716, 77.5946),
    String? initialAddress,
  }) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    if (isDesktop) {
      return showDialog<PickedLocationResult>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: SizedBox(
            width: 820,
            height: 700,
            child: LocationPickerDialog(
              initialLocation: initialLocation,
              initialAddress: initialAddress,
            ),
          ),
        ),
      );
    } else {
      return Navigator.of(context).push<PickedLocationResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => LocationPickerDialog(
            initialLocation: initialLocation,
            initialAddress: initialAddress,
          ),
        ),
      );
    }
  }

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();
  final Dio _dio = Dio();

  late LatLng _selectedPoint;
  String _currentAddress = 'Pinpointing address...';
  bool _isReverseGeocoding = false;
  bool _isSearching = false;
  bool _showManualCoords = false;
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialLocation;
    _latCtrl.text = _selectedPoint.latitude.toStringAsFixed(6);
    _lngCtrl.text = _selectedPoint.longitude.toStringAsFixed(6);

    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _currentAddress = widget.initialAddress!;
    } else {
      _reverseGeocode(_selectedPoint);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': point.latitude,
          'lon': point.longitude,
          'format': 'json',
        },
        options: Options(headers: {'User-Agent': 'TakeMyTrash_App/1.0'}),
      );
      if (res.data != null && res.data['display_name'] != null) {
        if (mounted) {
          setState(() {
            _currentAddress = res.data['display_name'].toString();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentAddress =
                'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentAddress =
              'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
        });
      }
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 5,
        },
        options: Options(headers: {'User-Agent': 'TakeMyTrash_App/1.0'}),
      );
      if (mounted && res.data is List) {
        setState(() {
          _searchResults = res.data as List;
        });
      }
    } catch (_) {
      // Ignore
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onLocationSelected(LatLng point, {String? addressLabel}) {
    setState(() {
      _selectedPoint = point;
      _latCtrl.text = point.latitude.toStringAsFixed(6);
      _lngCtrl.text = point.longitude.toStringAsFixed(6);
      _searchResults = [];
      _searchCtrl.clear();
      if (addressLabel != null) {
        _currentAddress = addressLabel;
      }
    });
    _mapController.move(point, 16.0);
    if (addressLabel == null) {
      _reverseGeocode(point);
    }
  }

  Future<void> _useCurrentDeviceGps() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final point = LatLng(pos.latitude, pos.longitude);
      _onLocationSelected(point);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access device GPS: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _applyManualCoordinates() {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
      _onLocationSelected(LatLng(lat, lng));
      setState(() => _showManualCoords = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid Latitude (-90 to 90) and Longitude (-180 to 180).'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Location on Map',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Pinpoint coordinates and home address',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Enter Coordinates Manually',
            icon: Icon(
              _showManualCoords ? Icons.tune : Icons.edit_location_alt_outlined,
              color: AppColors.primary,
            ),
            onPressed: () => setState(() => _showManualCoords = !_showManualCoords),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. The Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint,
              initialZoom: 15.0,
              onTap: (_, point) => _onLocationSelected(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.takemytrash.user',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPoint,
                    width: 90,
                    height: 75,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Text(
                            'Selected',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.location_pin,
                          color: AppColors.error,
                          size: 34,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Search Bar & Suggestions
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) {
                      if (val.length > 2) _searchPlaces(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search city, street or colony...',
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : (_searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchResults = []);
                                  },
                                )
                              : null),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final item = _searchResults[i];
                        final name = item['display_name'] ?? '';
                        final lat = double.tryParse(item['lat'].toString()) ?? 0.0;
                        final lon = double.tryParse(item['lon'].toString()) ?? 0.0;
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined, color: AppColors.primary),
                          title: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            _onLocationSelected(LatLng(lat, lon), addressLabel: name);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 3. Manual Coordinates Drawer / Overlay if toggled
          if (_showManualCoords)
            Positioned(
              top: 76,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                    ),
                  ],
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Direct Latitude / Longitude Input',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showManualCoords = false),
                          child: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Latitude',
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _lngCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Longitude',
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check, color: Colors.white, size: 18),
                        label: const Text(
                          'Set Pin to Coordinates',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _applyManualCoordinates,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Map Action Controls (GPS Recenter, Zoom)
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              children: [
                _MapFloatingButton(
                  icon: Icons.my_location,
                  tooltip: 'Current GPS',
                  onTap: _useCurrentDeviceGps,
                ),
                const SizedBox(height: 8),
                _MapFloatingButton(
                  icon: Icons.add,
                  tooltip: 'Zoom In',
                  onTap: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_selectedPoint, zoom + 1);
                  },
                ),
                const SizedBox(height: 8),
                _MapFloatingButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom Out',
                  onTap: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_selectedPoint, zoom - 1);
                  },
                ),
              ],
            ),
          ),

          // 5. Bottom Location Card & Confirmation
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coordinates Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.gps_fixed, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'LAT: ${_selectedPoint.latitude.toStringAsFixed(5)}  |  LNG: ${_selectedPoint.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Tap map to relocate',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Address Text
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _isReverseGeocoding
                            ? const Row(
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Detecting street address...',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _currentAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Confirm Button
                  AppButton(
                    label: 'Confirm Selected Location',
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    height: 50,
                    onPressed: () {
                      Navigator.of(context).pop(
                        PickedLocationResult(
                          address: _currentAddress,
                          latitude: _selectedPoint.latitude,
                          longitude: _selectedPoint.longitude,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _MapFloatingButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
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
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}
