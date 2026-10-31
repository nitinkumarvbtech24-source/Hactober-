import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../../core/theme/app_theme.dart';

class CameraCaptureScreen extends StatefulWidget {
  final String category;
  final double lat;
  final double lng;
  const CameraCaptureScreen({super.key, required this.category, required this.lat, required this.lng});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCaptured = false;
  bool _isSubmitting = false;
  XFile? _capturedImage;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0], // First camera (usually back)
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera found on device.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = photo;
        _isCaptured = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture image.')),
        );
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _isCaptured = false;
      _capturedImage = null;
    });
  }

  Future<void> _submitReport() async {
    if (_capturedImage == null) return;
    
    setState(() => _isSubmitting = true);
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isSubmitting = false);
    
    if (!mounted) return;
    
    context.pop({
      'category': widget.category,
      'comment': _commentController.text.isEmpty ? 'No comments provided' : _commentController.text,
      'lat': widget.lat,
      'lng': widget.lng,
      'status': 'Submitted',
      'id': '#RP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      'image': _capturedImage!.path,
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Camera background is black
      body: Stack(
        children: [
          // 1. Camera View Finder or Captured Image
          Positioned.fill(
            child: _isCaptured && _capturedImage != null
                ? Image.network(
                    _capturedImage!.path,
                    fit: BoxFit.cover,
                  )
                : (_cameraController != null && _cameraController!.value.isInitialized)
                    ? CameraPreview(_cameraController!)
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
          ),

          // 1.5 Location Watermark Overlay on Image
          if (_isCaptured && _capturedImage != null)
            Positioned(
              top: 120, // Below header
              left: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.my_location, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.lat.toStringAsFixed(5)}° N, ${widget.lng.toStringAsFixed(5)}° E\nLocation Captured',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 2. Header
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
                Text(
                  'Report ${widget.category == "pothole" ? "Pothole" : widget.category == "garbage" ? "Garbage" : "Issue"}',
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                  child: const Icon(Icons.flash_off, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),

          // 3. Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _isCaptured
                ? _buildReviewPanel()
                : Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Center(
                      child: GestureDetector(
                        onTap: _captureImage,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPanel() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Comment Box
              const Text('Additional details', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: 'Describe the issue or add any information that may help...',
                  hintStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _retakePhoto,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: const Text('Retake', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: _isSubmitting 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Submit Report', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Space
            ],
          ),
        ),
      ),
    );
  }
}
