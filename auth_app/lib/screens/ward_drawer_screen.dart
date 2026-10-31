import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ward.dart';

class WardBoundaryDrawerScreen extends StatefulWidget {
  final Ward ward;

  const WardBoundaryDrawerScreen({super.key, required this.ward});

  @override
  State<WardBoundaryDrawerScreen> createState() => _WardBoundaryDrawerScreenState();
}

class _WardBoundaryDrawerScreenState extends State<WardBoundaryDrawerScreen> {
  final MapController _mapController = MapController();
  final List<LatLng> _points = [];
  bool _isSaving = false;
  LatLng? _liveUserPosition;

  @override
  void initState() {
    super.initState();
    if (widget.ward.boundary.isNotEmpty) {
      _points.addAll(widget.ward.boundary);
    } else {
      _fetchUserLocation();
    }
  }

  Future<void> _fetchUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 4));
        final latLng = LatLng(pos.latitude, pos.longitude);
        setState(() => _liveUserPosition = latLng);
        if (_points.isEmpty) {
          _mapController.move(latLng, 15.0);
        }
      }
    } catch (_) {}
  }

  void _onMapTap(TapPosition tapPos, LatLng latLng) {
    setState(() {
      _points.add(latLng);
    });
  }

  void _undoPoint() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.removeLast();
      });
    }
  }

  void _clearPoints() {
    if (_points.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Boundary?'),
        content: const Text('Are you sure you want to remove all boundary points?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _points.clear();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBoundary() async {
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap at least 3 points on the map to form a closed ward boundary.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final boundaryData = _points.map((pt) => {
        'lat': pt.latitude,
        'lng': pt.longitude,
      }).toList();

      await FirebaseFirestore.instance.collection('wards').doc(widget.ward.id).update({
        'boundary': boundaryData,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ward boundary for "${widget.ward.name}" saved successfully! (${_points.length} points)')),
        );
        Navigator.pop(context, _points);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving boundary: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  LatLng _getInitialCenter() {
    if (_points.isNotEmpty) {
      return _points.first;
    }
    if (_liveUserPosition != null) {
      return _liveUserPosition!;
    }
    return const LatLng(13.0568, 77.5028); // Fallback
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _getInitialCenter();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Draw Boundary: ${widget.ward.name}',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Zone: ${widget.ward.zone} • Tap map to add vertices',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveBoundary,
              icon: _isSaving 
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(LucideIcons.check, size: 16),
              label: Text(_isSaving ? 'Saving...' : 'Save Boundary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.streetaqi.auth_app',
              ),
              // Polygon layer for 3 or more points
              if (_points.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon<Object>(
                      points: _points,
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                      borderColor: const Color(0xFF1D4ED8),
                      borderStrokeWidth: 3.0,
                    ),
                  ],
                ),
              // Polyline layer if only 2 points
              if (_points.length == 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _points,
                      color: const Color(0xFF1D4ED8),
                      strokeWidth: 3.0,
                    ),
                  ],
                ),
              // Vertex markers with numbers
              MarkerLayer(
                markers: _points.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final pt = entry.value;

                  return Marker(
                    point: pt,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Floating helper instruction bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(LucideIcons.penTool, size: 16, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _points.isEmpty
                          ? 'Tap anywhere on the map to place the first point of the ward perimeter.'
                          : _points.length < 3
                              ? 'Tap to add ${_points.length == 1 ? "2 more points" : "1 more point"} to close the polygon.'
                              : '${_points.length} points placed. Tap more vertices or tap "Save Boundary".',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _points.length >= 3 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_points.length} pts',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _points.length >= 3 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Editing Toolbar (Undo, Clear, Recenter)
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'undoBtn',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                  tooltip: 'Undo Last Point',
                  onPressed: _points.isNotEmpty ? _undoPoint : null,
                  child: const Icon(LucideIcons.undo2),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'clearBtn',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFEF4444),
                  tooltip: 'Clear All Points',
                  onPressed: _points.isNotEmpty ? _clearPoints : null,
                  child: const Icon(LucideIcons.trash2),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'recenterBtn',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                  tooltip: 'Recenter on Ward / My Location',
                  onPressed: () {
                    if (_points.isNotEmpty) {
                      _mapController.move(_points.first, 15.0);
                    } else if (_liveUserPosition != null) {
                      _mapController.move(_liveUserPosition!, 15.0);
                    } else {
                      _fetchUserLocation();
                    }
                  },
                  child: const Icon(LucideIcons.locateFixed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
