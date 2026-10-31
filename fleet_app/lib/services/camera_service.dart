import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import 'telemetry_service.dart';

class CameraService extends ChangeNotifier {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isAutoCapturing = false;
  Timer? _autoTimer;

  bool _isBackendConnected = false;
  String _latestRoadStatus = 'READY';
  double _latestConfidence = 0.0;
  int _latestTrashCount = 0;
  String? _latestImageUrl;
  String? _errorMessage;
  int _detectionsToday = 0;
  bool _showResultOverlay = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isProcessing => _isProcessing;
  bool get isAutoCapturing => _isAutoCapturing;
  bool get isBackendConnected => _isBackendConnected;
  String get latestRoadStatus => _latestRoadStatus;
  double get latestConfidence => _latestConfidence;
  int get latestTrashCount => _latestTrashCount;
  String? get latestImageUrl => _latestImageUrl;
  int get detectionsToday => _detectionsToday;
  bool get showResultOverlay => _showResultOverlay;
  bool get isNoRoad => _latestRoadStatus.toLowerCase().contains('no road');
  bool get isLatestTrash => !isNoRoad && (_latestTrashCount > 0 || _latestRoadStatus.toLowerCase().contains('trash'));
  bool get isCleanRoad => !isNoRoad && !isLatestTrash;

  void dismissResultOverlay() {
    _showResultOverlay = false;
    notifyListeners();
  }

  Future<void> initCamera() async {
    try {
      _errorMessage = null;
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _errorMessage = 'No camera device found on this system.';
        notifyListeners();
        return;
      }

      _controller = CameraController(
        _cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
      notifyListeners();

      _checkBackendHealth();
    } catch (e) {
      debugPrint("CameraService init error: $e");
      _errorMessage = 'Camera initialization failed: $e';
      notifyListeners();
    }
  }

  Future<void> _checkBackendHealth() async {
    try {
      final res = await http.get(
        Uri.parse('$activeGarbageAiUrl/api/snapshots'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      ).timeout(const Duration(seconds: 4));
      _isBackendConnected = res.statusCode == 200;
      notifyListeners();
    } catch (_) {
      _isBackendConnected = false;
      notifyListeners();
    }
  }

  void toggleAutoCapture() {
    _isAutoCapturing = !_isAutoCapturing;
    notifyListeners();

    if (_isAutoCapturing) {
      _autoTimer?.cancel();
      _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!_isProcessing) {
          captureAndPredict();
        }
      });
    } else {
      _autoTimer?.cancel();
    }
  }

  Future<Map<String, dynamic>?> captureAndPredict() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return null;
    }

    try {
      final XFile imageFile = await _controller!.takePicture();
      final bytes = await imageFile.readAsBytes();
      return await predictFromBytes(bytes);
    } catch (e) {
      debugPrint("Capture error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> predictFromBytes(Uint8List bytes) async {
    if (_isProcessing) return null;

    _isProcessing = true;
    notifyListeners();

    try {
      final base64Image = base64Encode(bytes);
      final pos = TelemetryService().currentPosition;
      final lat = pos?.latitude ?? 13.0568;
      final lng = pos?.longitude ?? 77.5028;
      final vehicle = TelemetryService().vehicleNumber;
      final ward = TelemetryService().assignedWard;

      final response = await http.post(
        Uri.parse('$activeGarbageAiUrl/process_frame'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({
          'image': 'data:image/jpeg;base64,$base64Image',
          'lat': lat,
          'lng': lng,
          'vehicle_number': vehicle,
          'ward': ward,
          'zone': 'Central Zone',
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        _isBackendConnected = true;
        final data = json.decode(response.body);

        final rawDecision = (data['decision'] ?? data['road_status'] ?? 'Unknown').toString();
        final rawRoadStatus = (data['road_status'] ?? '').toString();
        final bool isRoad = (data['is_road'] != false) &&
            !rawRoadStatus.toLowerCase().contains('no road') &&
            !rawDecision.toUpperCase().contains('NO ROAD');
        final conf = (data['confidence'] as num?)?.toDouble() ?? (data['road_confidence'] as num?)?.toDouble() ?? 0.0;
        final trashCount = (data['trash_count'] as num?)?.toInt() ?? 0;
        final imgUrl = data['image_url']?.toString();

        if (!isRoad) {
          _latestRoadStatus = 'No Road Detected';
          _latestConfidence = 0.0;
          _latestTrashCount = 0;
          _latestImageUrl = imgUrl != null ? '$activeGarbageAiUrl$imgUrl' : null;
          _showResultOverlay = true;

          // Save to Firestore collection 'trash_spots' as No Road Detected
          final docId = data['id'] ?? 'spot_${DateTime.now().millisecondsSinceEpoch}';
          await FirebaseFirestore.instance.collection('trash_spots').doc(docId).set({
            'id': docId,
            'lat': lat,
            'lng': lng,
            'road_status': 'No Road Detected',
            'display_class': 'No Road Detected',
            'class': 'No_Road',
            'confidence': 0.0,
            'image_url': _latestImageUrl ?? '',
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'No Road Detected',
            'is_trash': false,
            'is_road': false,
            'vehicle_number': vehicle,
            'ward': ward,
            'zone': 'Central Zone',
            'model_version': 'v7_mobilenetv3',
            'trash_count': 0,
            'detected_by': 'Fleet Tipper App',
          });

          notifyListeners();
          return data;
        }

        final bool isTrash = (data['is_trash'] == true) || trashCount > 0 || rawDecision.toLowerCase().contains('trash');
        final String formattedStatus = isTrash ? 'Trash Detected' : 'No Trash';

        _latestRoadStatus = formattedStatus;
        _latestConfidence = conf;
        _latestTrashCount = trashCount;
        _latestImageUrl = imgUrl != null ? '$activeGarbageAiUrl$imgUrl' : null;
        _showResultOverlay = true;

        if (isTrash) {
          _detectionsToday++;
        }

        // Save EVERY capture to Firestore collection 'trash_spots'
        final docId = data['id'] ?? 'spot_${DateTime.now().millisecondsSinceEpoch}';
        await FirebaseFirestore.instance.collection('trash_spots').doc(docId).set({
          'id': docId,
          'lat': lat,
          'lng': lng,
          'road_status': formattedStatus,
          'display_class': formattedStatus,
          'class': isTrash ? 'Trash_Detected' : 'No_Trash',
          'confidence': conf,
          'image_url': _latestImageUrl ?? '',
          'timestamp': FieldValue.serverTimestamp(),
          'status': isTrash ? 'Flagged' : 'No Trash',
          'is_trash': isTrash,
          'is_road': true,
          'vehicle_number': vehicle,
          'ward': ward,
          'zone': 'Central Zone',
          'model_version': 'v7_mobilenetv3',
          'trash_count': trashCount,
          'detected_by': 'Fleet Tipper App',
        });

        notifyListeners();
        return data;
      } else {
        _latestRoadStatus = 'HTTP ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Prediction error: $e");
      _latestRoadStatus = 'OFFLINE / ERROR';
      _isBackendConnected = false;
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
    return null;
  }

  Future<void> testWithSampleImage() async {
    try {
      final res = await http.get(
        Uri.parse('$activeGarbageAiUrl/snapshots/sample.jpg'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      if (res.statusCode == 200) {
        await predictFromBytes(res.bodyBytes);
      } else {
        debugPrint("Sample photo returned status: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching test sample image: $e");
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}
