import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/telemetry_service.dart';
import '../widgets/trash_pinpoint_marker.dart';

class FleetMapScreen extends StatefulWidget {
  const FleetMapScreen({super.key});

  @override
  State<FleetMapScreen> createState() => _FleetMapScreenState();
}

class _FleetMapScreenState extends State<FleetMapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TelemetryService(),
      builder: (context, _) {
        final pos = TelemetryService().currentPosition;
        final myLocation = pos != null
            ? LatLng(pos.latitude, pos.longitude)
            : const LatLng(13.0568, 77.5028);
        final isNavigating = TelemetryService().isNavigating;

        return Scaffold(
          body: Stack(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trash_spots')
                    .where('status', isEqualTo: 'Flagged')
                    .snapshots(),
                builder: (context, snapshot) {
                  final List<Marker> trashMarkers = [];
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
                      final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
                      if (lat != 0.0 && lng != 0.0) {
                        trashMarkers.add(
                          Marker(
                            point: LatLng(lat, lng),
                            width: 36,
                            height: 44,
                            child: TrashPinpointWidget(
                              isVeryDirty: ((data['trash_count'] as num?)?.toInt() ?? 1) > 1,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Trash Spot: ${data['display_class'] ?? "Dirty Road"}'),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }
                    }
                  }

                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: myLocation,
                      initialZoom: 16.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.streetaqi.fleet_app',
                      ),
                      MarkerLayer(markers: trashMarkers),
                      // Current Vehicle GPS Marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: myLocation,
                            width: 48,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isNavigating ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                                ],
                              ),
                              child: const Center(
                                child: Icon(LucideIcons.truck, color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              // Bottom Shift/Tracking Card
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            TelemetryService().vehicleNumber,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isNavigating ? '🟢 Live Broadcasting' : '⚪ Shift Idle (Standby)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isNavigating ? const Color(0xFF059669) : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          TelemetryService().setNavigating(!isNavigating);
                        },
                        icon: Icon(isNavigating ? LucideIcons.square : LucideIcons.play, size: 16),
                        label: Text(isNavigating ? 'End Shift' : 'Start Shift'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isNavigating ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Right Controls (Recenter)
              Positioned(
                top: 20,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                  onPressed: () {
                    _mapController.move(myLocation, 16.0);
                  },
                  child: const Icon(LucideIcons.locateFixed),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

