import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _smsEnabled = true;
  bool _promoEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
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
              'How we reach you',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildToggle(
              'Push Notifications',
              'Real-time updates on your pickups',
              _pushEnabled,
              (v) => setState(() => _pushEnabled = v),
            ),
            const Divider(),
            _buildToggle(
              'SMS Alerts',
              'Driver arrival and critical alerts',
              _smsEnabled,
              (v) => setState(() => _smsEnabled = v),
            ),
            const Divider(),
            _buildToggle(
              'Email Summaries',
              'Weekly recap and receipts',
              _emailEnabled,
              (v) => setState(() => _emailEnabled = v),
            ),
            const Divider(),
            _buildToggle(
              'Promotional Offers',
              'Discounts and new feature announcements',
              _promoEnabled,
              (v) => setState(() => _promoEnabled = v),
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
