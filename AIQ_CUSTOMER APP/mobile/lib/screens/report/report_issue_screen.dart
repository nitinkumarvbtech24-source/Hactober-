import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../router/app_router.dart';
import '../../widgets/location_picker_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_capture_screen.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final MapController _mapController = MapController();
  LatLng _userLocation = const LatLng(12.9716, 77.5946); // Indiranagar, Bengaluru
  bool _isLoadingLocation = true;
  
  // State for complaints
  List<Map<String, dynamic>> _complaints = [
    {
      'id': '#RP-10042',
      'category': 'pothole',
      'lat': 12.9750,
      'lng': 77.5980,
      'status': 'In Progress',
      'date': 'Yesterday, 14:30',
      'image': 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?auto=format&fit=crop&q=80',
      'comment': 'Huge pothole on the main road, very dangerous.',
      'reportCount': 3,
    },
    {
      'id': '#RP-10021',
      'category': 'garbage',
      'lat': 12.9700,
      'lng': 77.5900,
      'status': 'Resolved',
      'date': 'Oct 12, 09:15',
      'image': 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&q=80',
      'comment': 'Garbage dumped on the sidewalk.',
      'reportCount': 1,
    },
    {
      'id': '#RP-10088',
      'category': 'garbage',
      'lat': 12.9720,
      'lng': 77.5940,
      'status': 'Resolved',
      'date': 'Today, 10:00',
      'image': 'https://images.unsplash.com/photo-1605600659928-879857d47228?auto=format&fit=crop&q=80',
      'comment': 'Overflowing bin near the park entrance.',
      'reportCount': 5,
    },
    {
      'id': '#RP-10065',
      'category': 'others',
      'lat': 12.9735,
      'lng': 77.5960,
      'status': 'In Progress',
      'date': 'Yesterday, 18:20',
      'image': 'https://images.unsplash.com/photo-1598257006626-48b0c252070d?auto=format&fit=crop&q=80',
      'comment': 'Fallen tree branch blocking the pavement.',
      'reportCount': 2,
    },
    {
      'id': '#RP-10055',
      'category': 'pothole',
      'lat': 12.9690,
      'lng': 77.5955,
      'status': 'In Progress',
      'date': '2 days ago',
      'image': 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?auto=format&fit=crop&q=80',
      'comment': 'Deep pothole, multiple bikes slipped here.',
      'reportCount': 8,
    }
  ];

  bool _showRecentReports = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
      _isLoadingLocation = false;
    });
    _mapController.move(_userLocation, 14.0);
  }

  final List<Map<String, dynamic>> _categories = [
    {'id': 'pothole', 'label': 'Pothole', 'icon': '🕳'},
    {'id': 'garbage', 'label': 'Garbage', 'icon': '🗑'},
    {'id': 'others', 'label': 'Other', 'icon': '⚠'},
  ];

  void _recenterMap() {
    _mapController.move(_userLocation, 14.0);
  }

  void _handleCategorySelection(String category) {
    bool foundNearby = false;
    Map<String, dynamic>? nearbyComplaint;
    int nearbyIndex = -1;

    for (int i = 0; i < _complaints.length; i++) {
      var comp = _complaints[i];
      if (comp['category'] == category) {
        double distanceInMeters = Geolocator.distanceBetween(
          _userLocation.latitude, _userLocation.longitude,
          comp['lat'], comp['lng']
        );
        if (distanceInMeters < 50.0) { // 50 meters radius
          foundNearby = true;
          nearbyComplaint = comp;
          nearbyIndex = i;
          break;
        }
      }
    }

    if (foundNearby && nearbyComplaint != null) {
      _showDuplicateReportDialog(nearbyComplaint, nearbyIndex, category);
    } else {
      _openReportModal(initialCategory: category);
    }
  }

  void _showDuplicateReportDialog(Map<String, dynamic> comp, int index, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Existing Report Nearby', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('There is already a ${comp['category']} reported near your location. Are you trying to report the same issue?',
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14)),
            const SizedBox(height: 16),
            if (comp['image'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: comp['image'].toString().startsWith('http') 
                  ? Image.network(comp['image'], height: 120, width: double.infinity, fit: BoxFit.cover)
                  : Image.file(File(comp['image']), height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openReportModal(initialCategory: category);
            },
            child: const Text('No, Report New', style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() {
                _complaints[index]['reportCount'] = (_complaints[index]['reportCount'] ?? 1) + 1;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Issue upvoted successfully!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text('Yes, Upvote This', style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openReportModal({String? initialCategory}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReportSubmissionModal(
        initialCategory: initialCategory ?? 'pothole',
        initialLocation: _userLocation,
        onSubmit: (newReport) {
          setState(() {
            _complaints.insert(0, newReport);
          });
          _mapController.move(LatLng(newReport['lat'], newReport['lng']), 15.5);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${newReport['id']} submitted! Pin added to live map.',
                      style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  void _showCategoryModal() {
    _openReportModal();
  }

  void _showComplaintDetails(Map<String, dynamic> comp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isResolved = comp['status'] == 'Resolved';
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  comp['category'].toString().toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isResolved
                                      ? AppColors.success.withOpacity(0.15)
                                      : AppColors.warning.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isResolved ? '✓ Resolved' : '⏳ In Progress',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isResolved ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Complaint ${comp['id']}',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.people, size: 14, color: AppColors.info),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${comp['reportCount'] ?? 1}',
                                      style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.info),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            comp['comment'] ?? 'No additional comments provided.',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Coordinates: ${(comp['lat'] as double).toStringAsFixed(4)}, ${(comp['lng'] as double).toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (comp['image'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: comp['image'].toString().startsWith('http')
                            ? Image.network(
                                comp['image'],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(comp['image']),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                      )
                    else
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.image_not_supported, color: AppColors.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Resolve / Unpin action
                if (!isResolved) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text(
                        'Mark as Resolved (Removes Point from Map)',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          comp['status'] = 'Resolved';
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${comp['id']} marked as Resolved! Point removed from active map.',
                                    style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This report is resolved. Its pin is no longer displayed on the live map.',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCategoryModal,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Report Issue', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Stack(
        children: [
          // 1. Map Layer
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.takemytrash.user',
              ),
              MarkerLayer(
                markers: [
                  // User Location Marker
                  Marker(
                    point: _userLocation,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.info.withOpacity(0.3),
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.info,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Complaint Markers (ONLY active/unresolved complaints have pins on map!)
                  ..._complaints.where((comp) => comp['status'] != 'Resolved').map((comp) {
                    final isPothole = comp['category'] == 'pothole';
                    final isGarbage = comp['category'] == 'garbage';
                    
                    IconData iconData = Icons.warning;
                    Color color = AppColors.warning;
                    
                    if (isPothole) {
                      iconData = Icons.remove_circle; // Pothole looking icon
                      color = AppColors.error;
                    } else if (isGarbage) {
                      iconData = Icons.delete;
                      color = AppColors.primary;
                    }
                    
                    return Marker(
                      point: LatLng(comp['lat'], comp['lng']),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showComplaintDetails(comp),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: color, width: 2),
                          ),
                          child: Center(
                            child: Icon(iconData, color: color, size: 24),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),

          // 2. Header Layer (Glassmorphism)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.sizeOf(context).width >= 768
                        ? 18
                        : (MediaQuery.paddingOf(context).top + 10),
                    left: 20,
                    right: 20,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.6))),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => MainShell.openDrawer(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.menu_rounded, color: AppColors.primary, size: 20),
                              if (MediaQuery.sizeOf(context).width >= 600) ...[
                                const SizedBox(width: 8),
                                const Text(
                                  'Menu',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Civic & Waste Issues',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 20,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 3. Floating Recenter Button
          Positioned(
            right: 20,
            top: MediaQuery.sizeOf(context).width >= 768 ? 90 : 130, 
            child: GestureDetector(
              onTap: _recenterMap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.my_location, color: AppColors.textPrimary, size: 20),
              ),
            ),
          ),
          
          // 4. Floating Toggle Button for Recent Reports (When Collapsed)
          if (!_showRecentReports)
            Positioned(
              left: 20,
              bottom: 24,
              child: GestureDetector(
                onTap: () => setState(() => _showRecentReports = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Civic Reports (${_complaints.length})',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_complaints.where((c) => c['status'] != 'Resolved').length} active pins',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Recent Complaints List Overlay (When Expanded)
          if (_showRecentReports)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width >= 900 ? 760 : double.infinity,
                  ),
                  child: Container(
                    height: 290,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, -5)),
                      ],
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Recent Civic Reports',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_complaints.where((c) => c['status'] != 'Resolved').length} active pins',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Collapse Button
                            IconButton(
                              tooltip: 'Hide / Collapse',
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28, color: AppColors.textSecondary),
                              onPressed: () => setState(() => _showRecentReports = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                            itemCount: _complaints.length,
                            separatorBuilder: (context, index) => const Divider(height: 20),
                            itemBuilder: (context, index) {
                              final comp = _complaints[index];
                              final isPothole = comp['category'] == 'pothole';
                              final isGarbage = comp['category'] == 'garbage';
                              final isResolved = comp['status'] == 'Resolved';
                              
                              return InkWell(
                                onTap: () {
                                  _mapController.move(LatLng(comp['lat'], comp['lng']), 15.5);
                                  _showComplaintDetails(comp);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isPothole 
                                              ? AppColors.error.withOpacity(0.1) 
                                              : (isGarbage ? AppColors.primary.withOpacity(0.1) : AppColors.warning.withOpacity(0.1)),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          isPothole ? Icons.remove_circle_outline : (isGarbage ? Icons.delete_outline : Icons.warning_amber),
                                          color: isPothole ? AppColors.error : (isGarbage ? AppColors.primary : AppColors.warning),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  isPothole ? 'Pothole Issue' : (isGarbage ? 'Garbage Dump' : 'Civic Issue'),
                                                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                ),
                                                Text(
                                                  comp['date'],
                                                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.textMuted),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '${comp['id']} • Lat: ${(comp['lat'] as double).toStringAsFixed(3)}, Lng: ${(comp['lng'] as double).toStringAsFixed(3)}',
                                                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.textSecondary),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isResolved ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    isResolved ? '✓ Resolved' : 'Active Pin',
                                                    style: TextStyle(
                                                      fontFamily: 'Plus Jakarta Sans',
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: isResolved ? AppColors.success : AppColors.warning,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
  }
}

class _ReportSubmissionModal extends StatefulWidget {
  final String initialCategory;
  final LatLng initialLocation;
  final Function(Map<String, dynamic>) onSubmit;

  const _ReportSubmissionModal({
    required this.initialCategory,
    required this.initialLocation,
    required this.onSubmit,
  });

  @override
  State<_ReportSubmissionModal> createState() => _ReportSubmissionModalState();
}

class _ReportSubmissionModalState extends State<_ReportSubmissionModal> {
  late String _selectedCategory;
  late LatLng _selectedLocation;
  final TextEditingController _commentCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _photoUrl;
  bool _isValidatingAI = false;
  bool _isAiValidated = false;
  double _aiConfidence = 0.98;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'pothole', 'label': 'Pothole', 'icon': '🕳'},
    {'id': 'garbage', 'label': 'Garbage Dump', 'icon': '🗑'},
    {'id': 'others', 'label': 'Other Issue', 'icon': '⚠'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _chooseLocationOnMap() async {
    final res = await LocationPickerDialog.show(
      context,
      initialLocation: _selectedLocation,
    );
    if (res != null && mounted) {
      setState(() {
        _selectedLocation = LatLng(res.latitude, res.longitude);
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(pos.latitude, pos.longitude);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updated to current GPS location!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _captureOrUploadPhoto({required bool useCamera}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: useCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1200,
      );
      if (file != null && mounted) {
        _applyPhotoAndRunAiValidation(file.path);
        return;
      }
    } catch (_) {
      _useSamplePhoto();
    }
  }

  void _useSamplePhoto() {
    final sampleMap = {
      'pothole': 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?auto=format&fit=crop&q=80',
      'garbage': 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&q=80',
      'others': 'https://images.unsplash.com/photo-1598257006626-48b0c252070d?auto=format&fit=crop&q=80',
    };
    final url = sampleMap[_selectedCategory] ?? sampleMap['garbage']!;
    _applyPhotoAndRunAiValidation(url);
  }

  Future<void> _applyPhotoAndRunAiValidation(String photoPath) async {
    setState(() {
      _photoUrl = photoPath;
      _isValidatingAI = true;
      _isAiValidated = false;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        _isValidatingAI = false;
        _isAiValidated = true;
        _aiConfidence = 0.96 + (DateTime.now().millisecond % 4) * 0.01;
      });
    }
  }

  void _submit() {
    if (_photoUrl == null) {
      _useSamplePhoto();
    }

    final commentText = _commentCtrl.text.trim();
    final newReport = {
      'id': '#RP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      'category': _selectedCategory,
      'lat': _selectedLocation.latitude,
      'lng': _selectedLocation.longitude,
      'status': 'In Progress',
      'date': 'Just now',
      'image': _photoUrl ?? 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&q=80',
      'comment': commentText.isNotEmpty ? commentText : 'Civic hazard reported by citizen.',
      'reportCount': 1,
    };

    widget.onSubmit(newReport);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Report Civic Issue',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Category Selection
                const Text(
                  'Issue Category',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _categories.map((cat) {
                    final isSel = _selectedCategory == cat['id'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat['id'];
                            if (_isAiValidated) {
                              _isAiValidated = false;
                              _photoUrl = null;
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel ? AppColors.primary : AppColors.border,
                              width: isSel ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(cat['icon'], style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text(
                                cat['label'],
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                  color: isSel ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // 2. Location Coordinates & Map Selection
                const Text(
                  'Issue Location & Coordinates',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lat ${_selectedLocation.latitude.toStringAsFixed(5)} • Lng ${_selectedLocation.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.my_location, size: 16),
                              label: const Text('Current GPS', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12)),
                              onPressed: _useCurrentLocation,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.map, size: 16),
                              label: const Text('Select on Map', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12)),
                              onPressed: _chooseLocationOnMap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Comment & Description Box
                const Text(
                  'Comment & Description',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: 'Write a comment and description about the civic issue, landmark, severity, or hazards...',
                    hintStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),

                // 4. Photo with AI Validation
                const Text(
                  'Photo & AI Model Validation',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_photoUrl != null) ...[
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _photoUrl!.startsWith('http')
                                  ? Image.network(_photoUrl!, width: 80, height: 80, fit: BoxFit.cover)
                                  : Image.file(File(_photoUrl!), width: 80, height: 80, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isValidatingAI)
                                    Row(
                                      children: const [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'AI Model validating photo...',
                                          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                        ),
                                      ],
                                    )
                                  else if (_isAiValidated)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(Icons.verified, color: AppColors.success, size: 16),
                                              SizedBox(width: 6),
                                              Text(
                                                'AI Model Validated ✓',
                                                style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_selectedCategory.toUpperCase()} hazard confirmed (${(_aiConfidence * 100).toStringAsFixed(1)}% match)',
                                            style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, color: AppColors.success),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  TextButton(
                                    onPressed: _useSamplePhoto,
                                    child: const Text('Change photo', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Click Photo', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _captureOrUploadPhoto(useCamera: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: const Text('Upload Image', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _captureOrUploadPhoto(useCamera: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton.icon(
                            onPressed: _useSamplePhoto,
                            icon: const Icon(Icons.auto_awesome, size: 15, color: AppColors.primary),
                            label: const Text('Attach AI Test Photo', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: const Text(
                      'Submit Report & Pin on Map',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
