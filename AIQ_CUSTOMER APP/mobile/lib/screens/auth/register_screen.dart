import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/location_picker_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isFetchingLocation = false;
  double? _selectedLat;
  double? _selectedLng;
  String _coordinateSource = '';

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': position.latitude,
          'lon': position.longitude,
          'format': 'json',
        },
        options: Options(headers: {'User-Agent': 'TakeMyTrash_App/1.0'}),
      );

      setState(() {
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
        _coordinateSource = 'Device GPS';
        if (response.data != null && response.data['display_name'] != null) {
          _addressCtrl.text = response.data['display_name'].toString();
        } else {
          _addressCtrl.text =
              'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location captured: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _openMapPicker() async {
    final initialLat = _selectedLat ?? 12.9716;
    final initialLng = _selectedLng ?? 77.5946;

    final result = await LocationPickerDialog.show(
      context,
      initialLocation: LatLng(initialLat, initialLng),
      initialAddress: _addressCtrl.text.isNotEmpty ? _addressCtrl.text : null,
    );

    if (result != null) {
      setState(() {
        _addressCtrl.text = result.address;
        _selectedLat = result.latitude;
        _selectedLng = result.longitude;
        _coordinateSource = 'Chosen on Map';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selected from Map: Lat ${result.latitude.toStringAsFixed(4)}, Lng ${result.longitude.toStringAsFixed(4)}',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    try {
      String finalLat = _selectedLat?.toString() ?? '';
      String finalLng = _selectedLng?.toString() ?? '';
      final addressQuery = _addressCtrl.text.trim();

      // If coordinates not explicitly picked yet, fallback to geocoding address
      if (finalLat.isEmpty || finalLng.isEmpty) {
        final dio = Dio();
        final response = await dio.get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {
            'q': addressQuery,
            'format': 'json',
            'limit': 1,
          },
          options: Options(headers: {'User-Agent': 'TakeMyTrash_App/1.0'}),
        );

        if (response.data != null && (response.data as List).isNotEmpty) {
          final location = response.data[0];
          finalLat = location['lat'].toString();
          finalLng = location['lon'].toString();
        } else {
          // Default fallback coordinates if search returns nothing
          finalLat = '12.9716';
          finalLng = '77.5946';
        }
      }

      await auth.register(
        name: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: addressQuery,
        lat: finalLat,
        lng: finalLng,
        password: _passwordCtrl.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: isDesktop ? Colors.white : AppColors.surface,
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  // Left Branded Hero Column (Fills desktop width with rich civic design)
                  Expanded(
                    flex: 5,
                    child: Container(
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryDark,
                            AppColors.primary,
                            Color(0xFF2D6A4F),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.recycling_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'TrashTracker',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Text(
                            'Empowering Clean\nNeighborhoods.',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Register to track live neighborhood tippers, schedule doorstep recyclables pickup, and report civic issues directly to municipal authorities.',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.85),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 36),
                          _buildDesktopHeroFeature(
                            icon: Icons.map_rounded,
                            title: 'Precise GPS Pinpointing',
                            desc: 'Choose your home address or pick exact map coordinates',
                          ),
                          const SizedBox(height: 20),
                          _buildDesktopHeroFeature(
                            icon: Icons.notifications_active_rounded,
                            title: 'Civic Priority Alerts',
                            desc: 'Get notified when garbage tippers approach your street',
                          ),
                          const SizedBox(height: 20),
                          _buildDesktopHeroFeature(
                            icon: Icons.eco_rounded,
                            title: 'Doorstep Recyclable Pickups',
                            desc: 'Instant booking with Ola/Uber style rider tracking',
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildHeroStat('100%', 'Free App'),
                                Container(width: 1, height: 28, color: Colors.white24),
                                _buildHeroStat('24/7', 'Municipal Sync'),
                                Container(width: 1, height: 28, color: Colors.white24),
                                _buildHeroStat('4.9 ★', 'Resident Rating'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Form Column (Full-height scrollable, clean spacious padding)
                  Expanded(
                    flex: 7,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                      child: Form(
                        key: _formKey,
                        child: _buildRegisterFormContent(auth, isDesktop: true),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: _buildRegisterFormContent(auth, isDesktop: false),
                ),
              ),
      ),
    );
  }

  Widget _buildDesktopHeroFeature({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterFormContent(AuthProvider auth, {required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDesktop) ...[
          // App Brand Badge
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.18),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.recycling_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Header Titles
        Text(
          'Create Your Account',
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Join TrashTracker for smart, seamless on-demand waste management.',
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

                  // Error Banner
                  if (auth.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.error.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              auth.error!,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: auth.clearError,
                            child: const Icon(Icons.close, color: AppColors.error, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // SECTION 1: Personal Details
                  _buildSectionHeader('Personal Details', Icons.badge_outlined),
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Full Name',
                          hint: 'Alex Morgan',
                          controller: _nameCtrl,
                          prefixIcon: Icons.person_outline,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Name is required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Username',
                          hint: 'alex_m',
                          controller: _usernameCtrl,
                          prefixIcon: Icons.alternate_email,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Username required' : null,
                        ),
                      ),
                    ],
                  ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Email Address',
                          hint: 'alex@example.com',
                          controller: _emailCtrl,
                          prefixIcon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Phone Number',
                          hint: '9876543210',
                          controller: _phoneCtrl,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.length != 10) return 'Enter 10 digits';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 2: Home Address & Coordinate Picker
                  _buildSectionHeader(
                    'Home & Pickup Address',
                    Icons.location_on_outlined,
                    actionText: 'Coordinates Required',
                  ),
                  const SizedBox(height: 12),

                  // Address Input field
                  AppTextField(
                    label: 'Address Details',
                    hint: _isFetchingLocation
                        ? 'Fetching your device GPS...'
                        : 'e.g. Flat 302, Green Park Avenue',
                    controller: _addressCtrl,
                    prefixIcon: Icons.home_outlined,
                    suffixIcon: _addressCtrl.text.isNotEmpty ? Icons.clear : null,
                    onSuffixTap: () {
                      _addressCtrl.clear();
                      setState(() {
                        _selectedLat = null;
                        _selectedLng = null;
                        _coordinateSource = '';
                      });
                    },
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Address is required' : null,
                  ),

                  // Options: Get Current Location & Choose on Map
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Set Exact Coordinates:',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // 1. Get Current Location Button
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 12),
                                  side: BorderSide(
                                    color: _isFetchingLocation
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: _coordinateSource == 'Device GPS'
                                      ? AppColors.primary.withOpacity(0.08)
                                      : AppColors.surface,
                                ),
                                icon: _isFetchingLocation
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : const Icon(Icons.my_location,
                                        size: 18, color: AppColors.primary),
                                label: Text(
                                  _isFetchingLocation ? 'Locating...' : 'Get Live GPS',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 2. Choose on Map Button
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 12),
                                  backgroundColor: AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.map_outlined,
                                    size: 18, color: Colors.white),
                                label: const Text(
                                  'Choose on Map',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: _openMapPicker,
                              ),
                            ),
                          ],
                        ),

                        // Latitude / Longitude info badge if coordinates exist
                        if (_selectedLat != null && _selectedLng != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Coordinates Linked ($_coordinateSource)',
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Lat: ${_selectedLat!.toStringAsFixed(6)}  •  Lng: ${_selectedLng!.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(40, 24),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: _openMapPicker,
                                  child: const Text(
                                    'Adjust',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // SECTION 3: Password & Security
                  _buildSectionHeader('Security', Icons.lock_outline),
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Password',
                          hint: 'Min. 8 characters',
                          controller: _passwordCtrl,
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          validator: (v) {
                            if (v == null || v.length < 8) {
                              return 'Min 8 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Confirm Password',
                          hint: 'Repeat password',
                          controller: _confirmCtrl,
                          prefixIcon: Icons.shield_outlined,
                          isPassword: true,
                          validator: (v) {
                            if (v != _passwordCtrl.text) {
                              return 'Passwords mismatch';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  AppButton(
                    label: 'Create Account',
                    onPressed: _register,
                    isLoading: auth.isLoading,
                  ),
                  const SizedBox(height: 14),

                  // Terms & Privacy disclaimer
                  const Text(
                    'By signing up, you agree to our Terms of Service & Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Already have account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              );
  }

  Widget _buildSectionHeader(String title, IconData icon, {String? actionText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        if (actionText != null)
          Text(
            actionText,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }
}
