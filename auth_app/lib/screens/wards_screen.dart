
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ward.dart';
import '../models/vehicle.dart';
import '../services/trash_spots_service.dart';
import 'ward_drawer_screen.dart';

class WardsScreen extends StatefulWidget {
  const WardsScreen({super.key});

  @override
  State<WardsScreen> createState() => _WardsScreenState();
}

class _WardsScreenState extends State<WardsScreen> {
  String _searchQuery = '';

  void _showAddEditWardDialog([Ward? existing]) {
    final isEdit = existing != null;
    final nameController = TextEditingController(text: isEdit ? existing.name : '');
    final supervisorController = TextEditingController(text: isEdit ? (existing.supervisorName ?? '') : '');
    final phoneController = TextEditingController(text: isEdit ? (existing.supervisorPhone ?? '') : '');
    String selectedZone = isEdit ? existing.zone : 'Central Zone';

    final zones = ['Central Zone', 'North Zone', 'South Zone', 'East Zone', 'West Zone'];
    if (!zones.contains(selectedZone)) {
      zones.add(selectedZone);
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEdit ? LucideIcons.edit : LucideIcons.mapPin,
                      color: const Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit Ward' : 'Create New Ward',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Ward Name / Number *',
                        hintText: 'e.g. Ward 01 - Central or Ward 15',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(LucideIcons.landmark, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedZone,
                      decoration: InputDecoration(
                        labelText: 'Zone *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(LucideIcons.compass, size: 18),
                      ),
                      items: zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedZone = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: supervisorController,
                      decoration: InputDecoration(
                        labelText: 'Supervisor Name',
                        hintText: 'e.g. Rajesh Kumar',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(LucideIcons.user, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Supervisor Contact Phone',
                        hintText: 'e.g. +91 98765 43210',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(LucideIcons.phone, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a ward name')),
                      );
                      return;
                    }

                    final docId = isEdit 
                        ? existing.id 
                        : name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

                    await FirebaseFirestore.instance.collection('wards').doc(docId).set({
                      'name': name,
                      'zone': selectedZone,
                      'supervisorName': supervisorController.text.trim(),
                      'supervisorPhone': phoneController.text.trim(),
                      'createdAt': isEdit 
                          ? existing.createdAt.toIso8601String() 
                          : DateTime.now().toIso8601String(),
                    }, SetOptions(merge: true));

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text(isEdit ? 'Ward updated!' : 'New ward created successfully!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isEdit ? 'Save Changes' : 'Create Ward'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteWard(Ward ward) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${ward.name}?'),
        content: const Text(
          'Are you sure you want to remove this ward? Vehicles currently assigned to this ward will need to be reassigned.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('wards').doc(ward.id).delete();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('${ward.name} deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wards & Zones Management',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Define municipal jurisdictions and assign supervision zones',
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditWardDialog(),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Create Ward'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                decoration: const InputDecoration(
                  icon: Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                  hintText: 'Search wards by name or zone...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
              ),
            ),
            const SizedBox(height: 20),

            // Wards Stream Grid/List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('wards').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  List<Ward> wards = docs.map((d) => Ward.fromJson(d.id, d.data() as Map<String, dynamic>)).toList();

                  if (_searchQuery.isNotEmpty) {
                    wards = wards.where((w) {
                      return w.name.toLowerCase().contains(_searchQuery) ||
                             w.zone.toLowerCase().contains(_searchQuery) ||
                             (w.supervisorName?.toLowerCase().contains(_searchQuery) ?? false);
                    }).toList();
                  }

                  if (wards.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.mapPin, size: 48, color: Color(0xFF3B82F6)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            docs.isEmpty ? 'No wards created yet' : 'No matching wards found',
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            docs.isEmpty 
                                ? 'Click "Create Ward" to add your first administrative ward.'
                                : 'Try searching with a different term.',
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                          ),
                          if (docs.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditWardDialog(),
                              icon: const Icon(LucideIcons.plus, size: 16),
                              label: const Text('Create First Ward'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
                    builder: (context, vehicleSnap) {
                      final vehicles = vehicleSnap.hasData
                          ? vehicleSnap.data!.docs.map((d) => Vehicle.fromJson(d.id, d.data() as Map<String, dynamic>)).toList()
                          : <Vehicle>[];

                      return ValueListenableBuilder(
                        valueListenable: TrashSpotsService.instance.flagsNotifier,
                        builder: (context, flags, _) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 900;
                              return GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWide ? 3 : (constraints.maxWidth > 600 ? 2 : 1),
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: 255,
                                ),
                                itemCount: wards.length,
                                itemBuilder: (context, index) {
                                  final ward = wards[index];
                                  final wardVehicles = vehicles.where((v) => v.assignedWard.toLowerCase().trim() == ward.name.toLowerCase().trim() || v.assignedWard.toLowerCase().trim() == ward.id.toLowerCase().trim()).length;
                                  final wardSpots = flags.where((f) => f.ward.toLowerCase().trim() == ward.name.toLowerCase().trim() && f.isTrashDetected).length;

                                  return Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: const [
                                        BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    ward.name,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFF0F172A),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEFF6FF),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      ward.zone,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: const Color(0xFF2563EB),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(LucideIcons.edit2, size: 16, color: Color(0xFF64748B)),
                                                  tooltip: 'Edit Ward',
                                                  onPressed: () => _showAddEditWardDialog(ward),
                                                ),
                                                IconButton(
                                                  icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFEF4444)),
                                                  tooltip: 'Delete Ward',
                                                  onPressed: () => _confirmDeleteWard(ward),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Divider(color: Colors.grey[200], height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Supervisor',
                                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                                ),
                                                Text(
                                                  ward.supervisorName?.isNotEmpty == true ? ward.supervisorName! : 'Unassigned',
                                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                                ),
                                              ],
                                            ),
                                            if (ward.supervisorPhone?.isNotEmpty == true)
                                              Text(
                                                ward.supervisorPhone!,
                                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                              ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(LucideIcons.truck, size: 14, color: Color(0xFF3B82F6)),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '$wardVehicles Trucks',
                                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: wardSpots > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      LucideIcons.trash2,
                                                      size: 14,
                                                      color: wardSpots > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '$wardSpots Hotspots',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: wardSpots > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => WardBoundaryDrawerScreen(ward: ward),
                                                ),
                                              );
                                            },
                                            icon: Icon(
                                              ward.boundary.length >= 3 ? LucideIcons.penTool : LucideIcons.mapPin,
                                              size: 14,
                                            ),
                                            label: Text(
                                              ward.boundary.length >= 3 
                                                  ? 'Edit Boundary (${ward.boundary.length} pts)' 
                                                  : 'Draw Boundary on Map',
                                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: ward.boundary.length >= 3 
                                                  ? const Color(0xFF2563EB) 
                                                  : const Color(0xFFD97706),
                                              side: BorderSide(
                                                color: ward.boundary.length >= 3 
                                                    ? const Color(0xFFBFDBFE) 
                                                    : const Color(0xFFFDE68A),
                                              ),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
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

