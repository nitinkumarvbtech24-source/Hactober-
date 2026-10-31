import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle.dart';
import '../models/ward.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  String _searchQuery = '';

  void _showAddEditVehicleDialog([Vehicle? existing]) {
    final isEdit = existing != null;
    final numberController = TextEditingController(text: isEdit ? existing.vehicleNumber : '');
    final driverController = TextEditingController(text: isEdit ? existing.driverName : '');
    final phoneController = TextEditingController(text: isEdit ? (existing.phoneNumber ?? '') : '');
    String selectedWard = isEdit ? existing.assignedWard : 'Ward 01';

    showDialog(
      context: context,
      builder: (ctx) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('wards').snapshots(),
          builder: (context, wardSnap) {
            final wardDocs = wardSnap.data?.docs ?? [];
            final wardNames = wardDocs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return data['name']?.toString() ?? d.id;
            }).toList();

            if (wardNames.isEmpty) {
              wardNames.addAll(['Ward 01', 'Ward 02', 'Ward 03', 'Ward 04', 'Ward 05']);
            }

            if (!wardNames.contains(selectedWard)) {
              wardNames.insert(0, selectedWard);
            }

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
                          isEdit ? LucideIcons.edit : LucideIcons.truck,
                          color: const Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Edit Vehicle' : 'Register New Truck',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: numberController,
                          enabled: !isEdit, // Vehicle number acts as unique document ID
                          decoration: InputDecoration(
                            labelText: 'Vehicle Number *',
                            hintText: 'e.g. ka 01 aa 0006',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(LucideIcons.truck, size: 18),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: driverController,
                          decoration: InputDecoration(
                            labelText: 'Driver Name *',
                            hintText: 'e.g. Ramesh Kumar',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(LucideIcons.user, size: 18),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Driver Phone',
                            hintText: 'e.g. +91 98765 43210',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(LucideIcons.phone, size: 18),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: selectedWard,
                          decoration: InputDecoration(
                            labelText: 'Assign Ward *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                          ),
                          items: wardNames.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedWard = val);
                            }
                          },
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
                        final vNum = numberController.text.trim();
                        final dName = driverController.text.trim();
                        if (vNum.isEmpty || dName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vehicle number and driver name are required.')),
                          );
                          return;
                        }

                        final docId = vNum.toLowerCase();
                        await FirebaseFirestore.instance.collection('vehicles').doc(docId).set({
                          'vehicleNumber': vNum,
                          'driverName': dName,
                          'phoneNumber': phoneController.text.trim(),
                          'assignedWard': selectedWard,
                          'isActive': isEdit ? existing.isActive : false,
                          'lastHeartbeat': isEdit ? existing.lastHeartbeat?.toIso8601String() : null,
                        }, SetOptions(merge: true));

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(isEdit ? 'Vehicle profile updated!' : 'Truck registered successfully!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isEdit ? 'Save Changes' : 'Register Truck'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _confirmDeleteVehicle(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${vehicle.vehicleNumber}?'),
        content: Text(
          'Are you sure you want to remove truck "${vehicle.vehicleNumber}" (${vehicle.driverName}) from the fleet? Its historical telemetry and assignment will be erased.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('vehicles').doc(vehicle.id).delete();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Vehicle ${vehicle.vehicleNumber} removed from fleet.')),
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fleet Vehicles',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage registered sanitation tippers and assign operational wards',
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditVehicleDialog(),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Add Truck'),
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
                  hintText: 'Search by vehicle number, driver, or ward...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
              ),
            ),
            const SizedBox(height: 20),

            // Vehicle Stream List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  List<Vehicle> vehicles = docs.map((doc) {
                    return Vehicle.fromJson(doc.id, doc.data() as Map<String, dynamic>);
                  }).toList();

                  if (_searchQuery.isNotEmpty) {
                    vehicles = vehicles.where((v) {
                      return v.vehicleNumber.toLowerCase().contains(_searchQuery) ||
                             v.driverName.toLowerCase().contains(_searchQuery) ||
                             v.assignedWard.toLowerCase().contains(_searchQuery);
                    }).toList();
                  }

                  if (vehicles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.truck, size: 48, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            docs.isEmpty ? 'No vehicles registered in fleet yet' : 'No matching vehicles found',
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            docs.isEmpty 
                                ? 'Click "Add Truck" above to register a tipper and assign it to a ward.'
                                : 'Try searching with another vehicle plate or driver name.',
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                          ),
                          if (docs.isEmpty) ...[
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditVehicleDialog(),
                              icon: const Icon(LucideIcons.plus, size: 16),
                              label: const Text('Register First Truck'),
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

                  return ListView.separated(
                    itemCount: vehicles.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final v = vehicles[index];
                      final isOnline = v.isRunning;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                LucideIcons.truck,
                                color: isOnline
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF94A3B8),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        v.vehicleNumber,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isOnline
                                              ? const Color(0xFFDCFCE7)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          v.statusText,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isOnline
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Driver: ${v.driverName}  •  Assigned Ward: ${v.assignedWard}',
                                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  ),
                                  if (v.phoneNumber != null && v.phoneNumber!.isNotEmpty)
                                    Text(
                                      'Phone: ${v.phoneNumber}',
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                    ),
                                  if (v.currentLocation != null)
                                    Text(
                                      'GPS: ${v.currentLocation!.latitude.toStringAsFixed(4)}, ${v.currentLocation!.longitude.toStringAsFixed(4)}',
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.edit2, size: 18, color: Color(0xFF64748B)),
                                  tooltip: 'Edit / Reassign Ward',
                                  onPressed: () => _showAddEditVehicleDialog(v),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFEF4444)),
                                  tooltip: 'Delete Vehicle',
                                  onPressed: () => _confirmDeleteVehicle(v),
                                ),
                              ],
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
