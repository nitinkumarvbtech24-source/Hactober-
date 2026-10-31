import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelemetryService extends ChangeNotifier {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isNavigating = false;
  String _vehicleNumber = 'ka 01 aa 0006';
  String _driverName = 'Tipper Driver 01';
  String _assignedWard = 'Ward 01';
  DateTime? _lastFirestoreWrite;

  Position? get currentPosition => _currentPosition;
  bool get isNavigating => _isNavigating;
  String get vehicleNumber => _vehicleNumber;
  String get driverName => _driverName;
  String get assignedWard => _assignedWard;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _vehicleNumber = prefs.getString('vehicle_number') ?? 'ka 01 aa 0006';
    _driverName = prefs.getString('driver_name') ?? 'Tipper Driver 01';
    _fetchAssignedWard();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 4));
      _currentPosition = pos;
      notifyListeners();

      _startLocationStream();
    } catch (e) {
      debugPrint("TelemetryService init error: $e");
    }
  }

  void _startLocationStream() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update every 5 meters
      ),
    ).listen((Position pos) {
      _currentPosition = pos;
      notifyListeners();

      if (_isNavigating) {
        _broadcastPosition(pos);
      }
    });
  }

  void setNavigating(bool val) {
    _isNavigating = val;
    notifyListeners();
    if (_currentPosition != null) {
      _broadcastPosition(_currentPosition!);
    }
  }

  Future<void> setVehicleInfo(String vehicleNum, String driver) async {
    _vehicleNumber = vehicleNum;
    _driverName = driver;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vehicle_number', vehicleNum);
    await prefs.setString('driver_name', driver);
    _fetchAssignedWard();
    notifyListeners();
    if (_currentPosition != null) {
      _broadcastPosition(_currentPosition!);
    }
  }

  Future<void> _fetchAssignedWard() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('vehicles').doc(_vehicleNumber).get();
      if (doc.exists && doc.data() != null && doc.data()!['assignedWard'] != null) {
        _assignedWard = doc.data()!['assignedWard'].toString();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _broadcastPosition(Position pos) async {
    final now = DateTime.now();
    if (_lastFirestoreWrite != null && now.difference(_lastFirestoreWrite!).inSeconds < 3) {
      return; // Rate limit writes to every 3 seconds
    }
    _lastFirestoreWrite = now;

    try {
      final docRef = FirebaseFirestore.instance.collection('vehicles').doc(_vehicleNumber);
      await docRef.set({
        'vehicleNumber': _vehicleNumber,
        'driverName': _driverName,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'speed': pos.speed,
        'heading': pos.heading,
        'isActive': _isNavigating,
        'lastHeartbeat': now.toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error broadcasting vehicle telemetry: $e");
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}

