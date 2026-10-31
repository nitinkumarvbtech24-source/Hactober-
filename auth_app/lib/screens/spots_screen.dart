import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/trash_spots_service.dart';
import '../models/garbage_flag.dart';
import '../widgets/ngrok_image.dart';

class SpotsScreen extends StatefulWidget {
  const SpotsScreen({super.key});

  @override
  State<SpotsScreen> createState() => _SpotsScreenState();
}

class _SpotsScreenState extends State<SpotsScreen> {
  int _filterIndex = 0; // 0: Active, 1: Resolved, 2: All
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Garbage Spots Directory',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Review AI detected waste hotspots and update resolution status',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),

            // Filter Tabs & Search Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      decoration: const InputDecoration(
                        icon: Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                        hintText: 'Search by vehicle, ward, or zone...',
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Trash Detected')),
                    ButtonSegment(value: 1, label: Text('No Trash')),
                    ButtonSegment(value: 2, label: Text('No Road')),
                    ButtonSegment(value: 3, label: Text('Resolved')),
                    ButtonSegment(value: 4, label: Text('All Captures')),
                  ],
                  selected: {_filterIndex},
                  onSelectionChanged: (set) {
                    setState(() {
                      _filterIndex = set.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Spots List
            Expanded(
              child: ValueListenableBuilder<List<GarbageFlag>>(
                valueListenable: TrashSpotsService.instance.flagsNotifier,
                builder: (context, flags, _) {
                  List<GarbageFlag> filtered = flags;
                  if (_filterIndex == 0) {
                    filtered = flags.where((f) => f.isTrashDetected).toList();
                  } else if (_filterIndex == 1) {
                    filtered = flags.where((f) => f.isCleanRoad).toList();
                  } else if (_filterIndex == 2) {
                    filtered = flags.where((f) => f.isNoRoad).toList();
                  } else if (_filterIndex == 3) {
                    filtered = flags.where((f) => f.isResolved).toList();
                  }

                  if (_searchQuery.isNotEmpty) {
                    filtered = filtered.where((f) {
                      return f.vehicleNumber.toLowerCase().contains(_searchQuery) ||
                          f.ward.toLowerCase().contains(_searchQuery) ||
                          f.zone.toLowerCase().contains(_searchQuery);
                    }).toList();
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.checkCheck, size: 48, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 12),
                          Text(
                            'No matching spots found',
                            style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isTrash = item.isTrashDetected;
                      final isCleanRoad = item.isCleanRoad;
                      final isNoRoad = item.isNoRoad;
                      final isResolved = item.isResolved;

                      Color badgeBg = const Color(0xFFFEF2F2);
                      Color badgeText = const Color(0xFFDC2626);
                      String badgeLabel = 'Trash Detected';

                      if (isTrash) {
                        badgeBg = const Color(0xFFFEF2F2);
                        badgeText = const Color(0xFFDC2626);
                        badgeLabel = 'Trash Detected (${item.trashCount})';
                      } else if (isCleanRoad) {
                        badgeBg = const Color(0xFFECFDF5);
                        badgeText = const Color(0xFF059669);
                        badgeLabel = 'No Trash (Clean)';
                      } else if (isNoRoad) {
                        badgeBg = const Color(0xFFFFFBEB);
                        badgeText = const Color(0xFFD97706);
                        badgeLabel = 'No Road Detected';
                      } else if (isResolved) {
                        badgeBg = const Color(0xFFEFF6FF);
                        badgeText = const Color(0xFF2563EB);
                        badgeLabel = 'Resolved';
                      }

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isTrash ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                            width: isTrash ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.imageUrl.isNotEmpty
                                  ? NgrokImage(
                                      url: item.imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(LucideIcons.image, color: Color(0xFF94A3B8)),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          badgeLabel,
                                          style: GoogleFonts.inter(
                                            color: badgeText,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(item.confidence * 100).toInt()}% conf',
                                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Vehicle: ${item.vehicleNumber}  •  ${item.ward}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    'GPS: ${item.lat.toStringAsFixed(4)}, ${item.lng.toStringAsFixed(4)}',
                                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                  ),
                                  Text(
                                    item.timestamp,
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                            if (isTrash)
                              ElevatedButton.icon(
                                onPressed: () {
                                  TrashSpotsService.instance.resolveSpot(item.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Marked as Resolved!')),
                                  );
                                },
                                icon: const Icon(LucideIcons.check, size: 16),
                                label: const Text('Deflag'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
