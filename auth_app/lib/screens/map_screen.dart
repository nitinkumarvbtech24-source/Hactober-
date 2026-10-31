import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/trash_spots_service.dart';
import '../models/garbage_flag.dart';
import '../models/vehicle.dart';
import '../models/ward.dart';
import '../widgets/trash_pinpoint_marker.dart';
import '../widgets/ngrok_image.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();
  LatLng _initialCenter = const LatLng(13.0568, 77.5028); // Default fallback
  bool _showResolved = false;

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  String? _locationStatus;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocationTracking({bool moveToCenter = false}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationStatus = 'GPS service disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationStatus = 'Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationStatus = 'Location permanently blocked in browser');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 5));

      setState(() {
        _currentPosition = pos;
        _initialCenter = LatLng(pos.latitude, pos.longitude);
        _locationStatus = 'Live GPS active';
      });

      _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
      _startLocationStream();
    } catch (e) {
      debugPrint("Error initializing live location: $e");
      setState(() => _locationStatus = 'Locating...');
    }
  }

  void _startLocationStream() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((Position pos) {
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
      }
    });
  }

  void _showSpotDetails(GarbageFlag flag) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isTrash = flag.isTrashDetected;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isTrash
                          ? const Color(0xFFFEF2F2)
                          : (flag.isNoRoad
                              ? const Color(0xFFFFFBEB)
                              : (flag.isCleanRoad ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF))),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isTrash
                          ? 'Trash Detected (${flag.trashCount})'
                          : (flag.isNoRoad
                              ? 'No Road Detected'
                              : (flag.isCleanRoad ? 'No Trash (Clean Road)' : 'Resolved')),
                      style: GoogleFonts.inter(
                        color: isTrash
                            ? const Color(0xFFDC2626)
                            : (flag.isNoRoad
                                ? const Color(0xFFD97706)
                                : (flag.isCleanRoad ? const Color(0xFF059669) : const Color(0xFF2563EB))),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${(flag.confidence * 100).toStringAsFixed(0)}% Confidence',
                    style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (flag.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: NgrokImage(
                      url: flag.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Vehicle: ${flag.vehicleNumber}',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Ward: ${flag.ward}  •  Zone: ${flag.zone}',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
              ),
              Text(
                'Coordinates: ${flag.lat.toStringAsFixed(5)}, ${flag.lng.toStringAsFixed(5)}',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
              ),
              Text(
                'Captured: ${flag.timestamp}',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),
              if (isTrash)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      TrashSpotsService.instance.resolveSpot(flag.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Spot marked as Resolved!')),
                      );
                    },
                    icon: const Icon(LucideIcons.checkCircle2),
                    label: const Text('Mark Cleaned & Deflag'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ValueListenableBuilder<List<GarbageFlag>>(
            valueListenable: TrashSpotsService.instance.flagsNotifier,
            builder: (context, allFlags, _) {
              final flagsToShow = _showResolved
                  ? allFlags
                  : allFlags.where((f) => f.isTrashDetected).toList();

              // Auto-center map on first spot if available
              if (flagsToShow.isNotEmpty && _initialCenter.latitude == 13.0568) {
                final first = flagsToShow.first;
                if (first.lat != 0.0 && first.lng != 0.0) {
                  _initialCenter = LatLng(first.lat, first.lng);
                }
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('wards').snapshots(),
                builder: (context, wardSnap) {
                  final List<Ward> wardsWithBoundaries = [];
                  if (wardSnap.hasData) {
                    for (var doc in wardSnap.data!.docs) {
                      final w = Ward.fromJson(doc.id, doc.data() as Map<String, dynamic>);
                      if (w.boundary.length >= 3) {
                        wardsWithBoundaries.add(w);
                      }
                    }
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
                    builder: (context, vehicleSnap) {
                      final List<Vehicle> vehicles = [];
                      if (vehicleSnap.hasData) {
                        for (var doc in vehicleSnap.data!.docs) {
                          vehicles.add(Vehicle.fromJson(doc.id, doc.data() as Map<String, dynamic>));
                        }
                      }

                      return FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _initialCenter,
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.streetaqi.auth_app',
                          ),
                          // Ward Boundary Polygons
                          PolygonLayer(
                            polygons: wardsWithBoundaries.map((ward) {
                              return Polygon<Object>(
                                points: ward.boundary,
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                borderColor: const Color(0xFF2563EB),
                                borderStrokeWidth: 2.2,
                              );
                            }).toList(),
                          ),
                          // Ward Name Labels on Map
                          MarkerLayer(
                            markers: wardsWithBoundaries.map((ward) {
                              return Marker(
                                point: ward.boundary.first,
                                width: 140,
                                height: 26,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      ward.name,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          // Garbage Spot Markers
                          MarkerLayer(
                            markers: flagsToShow.where((f) => f.lat != 0.0 && f.lng != 0.0).map((f) {
                              return Marker(
                                point: LatLng(f.lat, f.lng),
                                width: 40,
                                height: 48,
                                child: TrashPinpointWidget(
                                  isVeryDirty: f.trashCount > 1,
                                  count: f.trashCount,
                                  onTap: () => _showSpotDetails(f),
                                ),
                              );
                            }).toList(),
                          ),
                          // Fleet Vehicle Markers
                          MarkerLayer(
                            markers: vehicles.where((v) => v.currentLocation != null).map((v) {
                              return Marker(
                                point: v.currentLocation!,
                                width: 44,
                                height: 44,
                                child: GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Vehicle: ${v.vehicleNumber} (${v.statusText})')),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: v.isRunning ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(LucideIcons.truck, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          // Live User/Authority Location Marker
                          if (_currentPosition != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  width: 54,
                                  height: 54,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6).withValues(alpha: 0.22),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2)),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(LucideIcons.user, color: Colors.white, size: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),

          // Bottom Left Live GPS Status Pill
          Positioned(
            bottom: 24,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPosition != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentPosition != null
                        ? 'Live GPS: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                        : (_locationStatus ?? 'Requesting location...'),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                  ),
                  if (_currentPosition == null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _initLocationTracking(moveToCenter: true),
                      child: Text(
                        'Enable',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Top Right Controls (Toggle Resolved, Locate Me, Recenter)
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _showResolved ? LucideIcons.eye : LucideIcons.eyeOff,
                      color: _showResolved ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    ),
                    tooltip: _showResolved ? 'Showing All (Tap to hide clean)' : 'Showing Trash Only',
                    onPressed: () {
                      setState(() {
                        _showResolved = !_showResolved;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _currentPosition != null ? LucideIcons.locateFixed : LucideIcons.locate,
                      color: _currentPosition != null ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    ),
                    tooltip: 'Center on My Live Location',
                    onPressed: () async {
                      if (_currentPosition != null) {
                        _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 16.0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Centered on your live GPS location')),
                        );
                      } else {
                        await _initLocationTracking(moveToCenter: true);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.sparkles, color: Color(0xFF1E293B)),
                    tooltip: 'Recenter on Trash Spots',
                    onPressed: () {
                      final active = TrashSpotsService.instance.activeFlags;
                      if (active.isNotEmpty && active.first.lat != 0.0) {
                        _mapController.move(LatLng(active.first.lat, active.first.lng), 15.0);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No active trash spots to center on')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

