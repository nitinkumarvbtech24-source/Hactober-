import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_button.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometricEnabled = true;
  bool _twoFactorEnabled = false;
  bool _locationTracking = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Security Preferences',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildToggle(
              'Biometric Login',
              'Use Face ID or Fingerprint to log in',
              _biometricEnabled,
              (v) => setState(() => _biometricEnabled = v),
            ),
            const Divider(),
            _buildToggle(
              'Two-Factor Authentication',
              'Require a code sent to your phone',
              _twoFactorEnabled,
              (v) => setState(() => _twoFactorEnabled = v),
            ),
            const SizedBox(height: 32),
            const Text(
              'Privacy Settings',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildToggle(
              'Location Tracking',
              'Allow app to access location for better pickups',
              _locationTracking,
              (v) => setState(() => _locationTracking = v),
            ),
            const SizedBox(height: 48),
            AppButton(
              label: 'Change Password',
              variant: AppButtonVariant.outline,
              onPressed: () {
                // Implementation for change password
              },
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Delete Account',
              variant: AppButtonVariant.primary, // Using primary but will color it red inside style if needed. Outline is better for destructive.
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      activeTrackColor: AppColors.primaryDark,
      inactiveThumbColor: AppColors.textMuted,
      inactiveTrackColor: AppColors.surfaceElevated,
    );
  }
}
