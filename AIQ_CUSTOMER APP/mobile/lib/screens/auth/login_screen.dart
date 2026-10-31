import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/responsive_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final accounts = await ApiClient.getRegisteredAccounts();
      if (mounted) {
        setState(() {
          _savedAccounts = accounts;
          if (_savedAccounts.isNotEmpty && _identifierCtrl.text.isEmpty) {
            final latest = _savedAccounts.last;
            final un = latest['username']?.toString() ?? '';
            final em = latest['email']?.toString() ?? '';
            _identifierCtrl.text = un.isNotEmpty ? un : em;
            if (latest['password'] != null) {
              _passwordCtrl.text = latest['password'].toString();
            }
          }
        });
      }
    } catch (_) {}
  }

  void _selectSavedAccount(Map<String, dynamic> acc) {
    setState(() {
      final un = acc['username']?.toString() ?? '';
      final em = acc['email']?.toString() ?? '';
      _identifierCtrl.text = un.isNotEmpty ? un : em;
      if (acc['password'] != null && acc['password'].toString().isNotEmpty) {
        _passwordCtrl.text = acc['password'].toString();
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final id = _identifierCtrl.text.trim();
    final isEmail = id.contains('@');

    try {
      await auth.login(
        email: isEmail ? id : id,
        phone: !isEmail && RegExp(r'^[0-9]+$').hasMatch(id) ? id : null,
        password: _passwordCtrl.text,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
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
                          // Brand Pill
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
                          // Headline
                          const Text(
                            'Smart Waste Management\nFor Cleaner Cities.',
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
                            'Live GPS tipper tracking, AI-validated civic complaints, and on-demand doorstep recyclables pickup right in your neighborhood.',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.85),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 36),
                          // Feature Highlights
                          _buildDesktopHeroFeature(
                            icon: Icons.gps_fixed_rounded,
                            title: 'Live Tipper GPS Fleet',
                            desc: 'Real-time street arrival tracking & morning alerts',
                          ),
                          const SizedBox(height: 20),
                          _buildDesktopHeroFeature(
                            icon: Icons.camera_enhance_rounded,
                            title: 'AI Civic Vision',
                            desc: 'Instant verification for waste dumps and potholes',
                          ),
                          const SizedBox(height: 20),
                          _buildDesktopHeroFeature(
                            icon: Icons.electric_moped_rounded,
                            title: 'Ola/Uber Style Doorstep Pickup',
                            desc: 'Book riders with live route & arrival tracking',
                          ),
                          const Spacer(),
                          // Trust row
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
                                _buildHeroStat('14,200+', 'Residents'),
                                Container(width: 1, height: 28, color: Colors.white24),
                                _buildHeroStat('98.4%', 'AI Accuracy'),
                                Container(width: 1, height: 28, color: Colors.white24),
                                _buildHeroStat('<12 min', 'Pickup ETA'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Auth Form Column (Full-height scrollable, clean spacious padding)
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Form(
                            key: _formKey,
                            child: _buildFormContent(auth, isDesktop: true),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: _buildFormContent(auth, isDesktop: false),
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

  Widget _buildFormContent(AuthProvider auth, {required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDesktop) ...[
          // Brand Logo for Mobile
          Center(
            child: Container(
              width: 68,
              height: 68,
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
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.recycling_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Headings
        Text(
          'Welcome Back',
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to access real-time garbage tracking\nand on-demand doorstep pickups.',
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Saved Accounts quick switcher
        if (_savedAccounts.isNotEmpty) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saved Accounts on this Device:',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _savedAccounts.map((acc) {
                  final name = acc['name']?.toString() ?? 'User';
                  final un = acc['username']?.toString() ?? '';
                  final isSelected = _identifierCtrl.text == un ||
                      _identifierCtrl.text == acc['email'];

                  return ActionChip(
                    avatar: CircleAvatar(
                      radius: 12,
                      backgroundColor: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    label: Text(
                      un.isNotEmpty ? '@$un' : name,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    backgroundColor: isSelected
                        ? AppColors.primaryLight
                        : Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    onPressed: () => _selectSavedAccount(acc),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],

        // Error banner
        if (auth.error != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 20),
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
                  child: const Icon(Icons.close,
                      color: AppColors.error, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Input Fields
        AppTextField(
          label: 'Username, Email or Phone',
          hint: 'e.g. johndoe or user@example.com',
          controller: _identifierCtrl,
          prefixIcon: Icons.person_outline,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Please enter your username, email, or phone';
            }
            return null;
          },
        ),

        AppTextField(
          label: 'Password',
          hint: 'Enter your password',
          controller: _passwordCtrl,
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            return null;
          },
        ),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text(
              'Forgot password?',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Sign In Button
        AppButton(
          label: 'Sign In',
          onPressed: _login,
          isLoading: auth.isLoading,
        ),
        const SizedBox(height: 24),

        // Don't have account
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/register'),
              child: const Text(
                'Sign Up',
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
      ],
    );
  }
}
