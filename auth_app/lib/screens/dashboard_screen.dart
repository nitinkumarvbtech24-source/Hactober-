import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/trash_spots_service.dart';
import '../models/garbage_flag.dart';
import '../widgets/ngrok_image.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<GarbageFlag>>(
      valueListenable: TrashSpotsService.instance.flagsNotifier,
      builder: (context, flags, _) {
        final totalCaptures = flags.length;
        final pendingTrash = flags.where((f) => f.isTrashDetected).toList();
        final cleanRoadList = flags.where((f) => f.isCleanRoad).toList();
        final noRoadList = flags.where((f) => f.isNoRoad).toList();
        final resolvedList = flags.where((f) => f.isResolved).toList();
        final evaluatedRoads = cleanRoadList.length + pendingTrash.length + resolvedList.length;
        final cleanlinessScore = evaluatedRoads == 0
            ? 100.0
            : (((cleanRoadList.length + resolvedList.length) / evaluatedRoads) * 100.0).clamp(0.0, 100.0);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operations Dashboard',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Street AIQ Cleanliness & Garbage Monitoring',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => onNavigateTab?.call(1), // Map tab
                      icon: const Icon(LucideIcons.map, size: 18),
                      label: const Text('Open Live Map'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // KPI Metrics Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    return GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isWide ? 1.4 : 1.2,
                      children: [
                        _buildKpiCard(
                          title: 'Trash Detected',
                          value: '${pendingTrash.length}',
                          icon: LucideIcons.trash2,
                          color: const Color(0xFFEF4444),
                          sub: 'Flagged for cleaning',
                        ),
                        _buildKpiCard(
                          title: 'No Trash (Clean)',
                          value: '${cleanRoadList.length}',
                          icon: LucideIcons.checkCircle2,
                          color: const Color(0xFF10B981),
                          sub: 'Verified clean roads',
                        ),
                        _buildKpiCard(
                          title: 'Cleanliness Score',
                          value: '${cleanlinessScore.toStringAsFixed(1)}%',
                          icon: LucideIcons.sparkles,
                          color: const Color(0xFF3B82F6),
                          sub: cleanlinessScore > 80 ? 'Optimal Condition' : 'Needs Attention',
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
                          builder: (context, snapshot) {
                            final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                            return _buildKpiCard(
                              title: 'Tracked Fleet',
                              value: '$count',
                              icon: LucideIcons.truck,
                              color: const Color(0xFF8B5CF6),
                              sub: 'Connected vehicles',
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Recent Detections Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Street Detections',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onNavigateTab?.call(4), // Spots tab
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (flags.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(LucideIcons.inbox, size: 40, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 12),
                          Text(
                            'No detections recorded yet',
                            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: flags.take(6).length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = flags[index];
                      final isTrash = item.isTrashDetected;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.imageUrl.isNotEmpty
                                  ? NgrokImage(
                                      url: item.imageUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 64,
                                      height: 64,
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
                                      Builder(
                                        builder: (context) {
                                          Color bBg = const Color(0xFFFEF2F2);
                                          Color bText = const Color(0xFFDC2626);
                                          String bLabel = 'Trash Detected';
                                          if (item.isTrashDetected) {
                                            bBg = const Color(0xFFFEF2F2);
                                            bText = const Color(0xFFDC2626);
                                            bLabel = 'Trash Detected (${item.trashCount})';
                                          } else if (item.isNoTrash) {
                                            bBg = const Color(0xFFECFDF5);
                                            bText = const Color(0xFF059669);
                                            bLabel = 'No Trash';
                                          } else if (item.isResolved) {
                                            bBg = const Color(0xFFEFF6FF);
                                            bText = const Color(0xFF2563EB);
                                            bLabel = 'Resolved';
                                          }
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: bBg,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              bLabel,
                                              style: GoogleFonts.inter(
                                                color: bText,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        },
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
                                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    item.timestamp,
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                            if (isTrash)
                              IconButton(
                                icon: const Icon(LucideIcons.checkCircle, color: Color(0xFF10B981)),
                                tooltip: 'Mark Resolved',
                                onPressed: () {
                                  TrashSpotsService.instance.resolveSpot(item.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Spot marked as resolved!')),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(sub, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }
}
