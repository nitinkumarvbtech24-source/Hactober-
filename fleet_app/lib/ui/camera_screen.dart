import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/camera_service.dart';
import '../widgets/ngrok_image.dart';

class FleetCameraScreen extends StatefulWidget {
  const FleetCameraScreen({super.key});

  @override
  State<FleetCameraScreen> createState() => _FleetCameraScreenState();
}

class _FleetCameraScreenState extends State<FleetCameraScreen> {
  @override
  void initState() {
    super.initState();
    if (!CameraService().isInitialized) {
      CameraService().initCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CameraService(),
      builder: (context, _) {
        final service = CameraService();
        final isInit = service.isInitialized && service.controller != null;
        final isNoRoad = service.isNoRoad;
        final isTrash = service.isLatestTrash;
        final statusColor = isNoRoad
            ? const Color(0xFFF59E0B)
            : (isTrash ? const Color(0xFFEF4444) : const Color(0xFF10B981));
        final statusIcon = isNoRoad
            ? LucideIcons.alertTriangle
            : (isTrash ? LucideIcons.trash2 : LucideIcons.sparkles);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Camera Preview
              if (isInit)
                Center(child: CameraPreview(service.controller!))
              else if (service.errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.cameraOff, color: Colors.white54, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          service.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: service.initCamera,
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: const Text('Retry Camera'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('Starting AI Camera...', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),

              // Top Status Banner (AI Output)
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: statusColor,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          statusIcon,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              service.latestRoadStatus,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              isNoRoad
                                  ? 'Point camera directly at road surface'
                                  : (service.latestConfidence > 0
                                      ? 'Confidence: ${(service.latestConfidence * 100).toInt()}% • ${isTrash ? "Detected: ${service.latestTrashCount} item(s)" : "Road Clean"}'
                                      : 'Garbage AI Model v7 Active'),
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Server Status Light
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: service.isBackendConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Control Bar
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Auto Mode Toggle
                    ElevatedButton.icon(
                      onPressed: service.toggleAutoCapture,
                      icon: Icon(
                        service.isAutoCapturing ? LucideIcons.pause : LucideIcons.repeat,
                        size: 16,
                      ),
                      label: Text(service.isAutoCapturing ? 'Auto ON' : 'Auto OFF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: service.isAutoCapturing ? const Color(0xFF3B82F6) : Colors.white24,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    // Shutter Button
                    GestureDetector(
                      onTap: service.isProcessing ? null : service.captureAndPredict,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: service.isProcessing ? Colors.grey : const Color(0xFFEF4444),
                        ),
                        child: service.isProcessing
                            ? const Padding(
                                padding: EdgeInsets.all(18.0),
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : const Icon(LucideIcons.camera, color: Colors.white, size: 28),
                      ),
                    ),

                    // Test Sample Image Scan Button
                    ElevatedButton.icon(
                      onPressed: service.isProcessing ? null : service.testWithSampleImage,
                      icon: const Icon(LucideIcons.sparkles, size: 16),
                      label: const Text('Test Sample'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              // Corner Detected Preview Thumbnail
              if (!service.showResultOverlay && service.latestImageUrl != null && service.latestImageUrl!.isNotEmpty)
                Positioned(
                  top: 110,
                  right: 16,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: NgrokImage(
                        url: service.latestImageUrl!,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),
                ),

              // On-Screen Detection Result Modal Card
              if (service.showResultOverlay)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.70),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        constraints: const BoxConstraints(maxWidth: 420),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isNoRoad
                                ? const Color(0xFFF59E0B)
                                : (isTrash ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isNoRoad
                                      ? const Color(0xFFF59E0B)
                                      : (isTrash ? const Color(0xFFEF4444) : const Color(0xFF10B981)))
                                  .withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header Banner
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isNoRoad
                                    ? const Color(0xFFF59E0B)
                                    : (isTrash ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isNoRoad
                                        ? LucideIcons.alertTriangle
                                        : (isTrash ? LucideIcons.trash2 : LucideIcons.checkCircle2),
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isNoRoad
                                          ? 'NO ROAD DETECTED'
                                          : (isTrash ? 'TRASH DETECTED' : 'NO TRASH'),
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.x, color: Colors.white),
                                    onPressed: service.dismissResultOverlay,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),

                            // Captured Image Display
                            if (service.latestImageUrl != null && service.latestImageUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 190,
                                    width: double.infinity,
                                    color: Colors.black,
                                    child: NgrokImage(
                                      url: service.latestImageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),

                            // Details / Status Info
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Database Record',
                                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              LucideIcons.database,
                                              size: 14,
                                              color: isNoRoad ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isNoRoad
                                                  ? 'Logged as No Road'
                                                  : (isTrash ? 'Flagged in trash_spots' : 'Saved to trash_spots (Clean)'),
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildResultInfoTile(
                                          'Confidence',
                                          isNoRoad ? '0%' : '${(service.latestConfidence * 100).toInt()}%',
                                          LucideIcons.percent,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildResultInfoTile(
                                          'Result',
                                          isNoRoad
                                              ? 'No Road Detected'
                                              : (isTrash ? '${service.latestTrashCount} Trash Item(s)' : 'Road Clean'),
                                          isNoRoad
                                              ? LucideIcons.eyeOff
                                              : (isTrash ? LucideIcons.trash2 : LucideIcons.sparkles),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isNoRoad) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(LucideIcons.info, size: 16, color: Color(0xFFF59E0B)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Indoor room, screen, wall, or ceiling detected. Please aim camera towards the street surface.',
                                              style: GoogleFonts.inter(color: const Color(0xFFFDE68A), fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: service.dismissResultOverlay,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isNoRoad
                                            ? const Color(0xFFF59E0B)
                                            : (isTrash ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        'Continue Scanning',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.white60),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

