import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/garbage_flag.dart';

class TrashSpotsService {
  TrashSpotsService._internal();
  static final TrashSpotsService instance = TrashSpotsService._internal();

  final ValueNotifier<List<GarbageFlag>> flagsNotifier = ValueNotifier<List<GarbageFlag>>([]);
  
  List<GarbageFlag> _firestoreFlags = [];
  StreamSubscription? _firestoreSub;
  bool _initialized = false;
  DateTime? _resetCutoff;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Load system reset cutoff if configured
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedReset = prefs.getString('system_reset_cutoff');
      if (savedReset != null) {
        _resetCutoff = DateTime.tryParse(savedReset);
      }
    } catch (_) {}

    // Listen to Firestore collection 'trash_spots'
    try {
      _firestoreSub = FirebaseFirestore.instance
          .collection('trash_spots')
          .snapshots()
          .listen(
        (snapshot) {
          _firestoreFlags = snapshot.docs.map((doc) {
            return GarbageFlag.fromJson(doc.data(), doc.id);
          }).where((f) {
            if (_resetCutoff != null) {
              final spotTime = DateTime.tryParse(f.timestamp);
              if (spotTime != null && spotTime.isBefore(_resetCutoff!)) {
                return false;
              }
            }
            return true;
          }).toList();
          _notify();
        },
        onError: (err) {
          debugPrint("TrashSpotsService firestore error: $err");
        },
      );
    } catch (e) {
      debugPrint("TrashSpotsService firestore init error: $e");
    }
  }

  void dispose() {
    _firestoreSub?.cancel();
  }

  void _notify() {
    final list = List<GarbageFlag>.from(_firestoreFlags);
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    flagsNotifier.value = list;
  }

  List<GarbageFlag> get allFlags => flagsNotifier.value;

  List<GarbageFlag> get activeFlags {
    return flagsNotifier.value.where((f) => f.isTrashDetected).toList();
  }

  List<GarbageFlag> get noTrashFlags {
    return flagsNotifier.value.where((f) => f.isNoTrash).toList();
  }

  List<GarbageFlag> get resolvedFlags {
    return flagsNotifier.value.where((f) => f.isResolved).toList();
  }

  Future<void> resolveSpot(String spotId) async {
    try {
      await FirebaseFirestore.instance.collection('trash_spots').doc(spotId).update({
        'status': 'Resolved',
        'resolved_at': FieldValue.serverTimestamp(),
      });
      _firestoreFlags = _firestoreFlags.map((f) {
        if (f.id == spotId) {
          return GarbageFlag(
            id: f.id,
            filename: f.filename,
            imageUrl: f.imageUrl,
            className: f.className,
            displayClass: f.displayClass,
            confidence: f.confidence,
            timestamp: f.timestamp,
            lat: f.lat,
            lng: f.lng,
            vehicleNumber: f.vehicleNumber,
            ward: f.ward,
            zone: f.zone,
            status: 'Resolved',
            modelVersion: f.modelVersion,
            trashCount: f.trashCount,
          );
        }
        return f;
      }).toList();
      _notify();
    } catch (e) {
      debugPrint("Error resolving spot $spotId: $e");
    }
  }

  /// Clears all detections and sets the reset cutoff to now so detection starts fresh from 0
  Future<void> clearAllDetections() async {
    try {
      final now = DateTime.now();
      _resetCutoff = now;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('system_reset_cutoff', now.toIso8601String());

      // Delete all documents in Firestore 'trash_spots'
      final snapshot = await FirebaseFirestore.instance.collection('trash_spots').get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      _firestoreFlags = [];
      flagsNotifier.value = [];
    } catch (e) {
      debugPrint("Error in clearAllDetections: $e");
    }
  }

  /// Clears all trucks in Firestore
  Future<void> clearAllVehicles() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('vehicles').get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint("Error in clearAllVehicles: $e");
    }
  }
}
