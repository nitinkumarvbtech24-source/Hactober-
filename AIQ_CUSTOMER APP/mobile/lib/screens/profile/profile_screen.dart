import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/app_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign Out', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to sign out of TakeMyTrash?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final displayName = (user?.name.isNotEmpty == true && user?.name != 'Demo User')
        ? user!.name
        : (user?.username.isNotEmpty == true ? user!.username : 'Citizen User');
    final displayUsername = user?.username.isNotEmpty == true
        ? '@${user!.username}'
        : (user?.email.isNotEmpty == true ? user!.email : '');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 36 : 20,
            vertical: isDesktop ? 28 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Menu Trigger
              Row(
                children: [
                  GestureDetector(
                    onTap: () => MainShell.openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_rounded, color: AppColors.primary, size: 20),
                          if (MediaQuery.sizeOf(context).width >= 600) ...[
                            const SizedBox(width: 8),
                            const Text(
                              'Menu',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Account & Profile',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 22,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Responsive Body Layout
              if (isDesktop)
                // 2-Column Desktop / Laptop Layout (Fills width without blank gutters)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Profile & Address)
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildUserIdentityCard(user, displayName, displayUsername, initial),
                          const SizedBox(height: 20),
                          _buildCitizenStatsCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 28),
                    // Right Column (Settings & Actions)
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildSettingsMenu(),
                          const SizedBox(height: 20),
                          _buildSignOutSection(),
                        ],
                      ),
                    ),
                  ],
                )
              else
                // Mobile Vertical Flow
                Column(
                  children: [
                    _buildUserIdentityCard(user, displayName, displayUsername, initial),
                    const SizedBox(height: 18),
                    _buildCitizenStatsCard(),
                    const SizedBox(height: 18),
                    _buildSettingsMenu(),
                    const SizedBox(height: 24),
                    _buildSignOutSection(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserIdentityCard(dynamic user, String displayName, String displayUsername, String initial) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (displayUsername.isNotEmpty)
                      Text(
                        displayUsername,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (user?.email != null && user!.email.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.email,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (user?.phone != null && user!.phone.isNotEmpty && user!.phone != '1234567890') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            user!.phone,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '✓ Verified',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // Registered Home Address & Coordinates
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withOpacity(0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registered Service Address',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (user?.address != null && user!.address!.isNotEmpty)
                            ? user!.address!
                            : 'Sapthagiri Layout, Main Road, Bengaluru, 560068',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Coordinates: Lat ${user?.lat ?? 12.9716} • Lng ${user?.lng ?? 77.5946}',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitizenStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Civic & Eco Impact',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildImpactPill('♻ Waste Diverted', '48 kg', AppColors.primary),
              const SizedBox(width: 10),
              _buildImpactPill('🚛 Doorstep Pickups', '14 completed', AppColors.info),
              const SizedBox(width: 10),
              _buildImpactPill('⭐ Civic Karma', '520 pts', AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactPill(String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.person_outline,
            label: 'Edit Profile Information',
            onTap: () => context.push('/edit-profile'),
          ),
          const Divider(height: 1, color: AppColors.border),
          _MenuItem(
            icon: Icons.shield_outlined,
            label: 'Privacy & Security Controls',
            onTap: () => context.push('/privacy'),
          ),
          const Divider(height: 1, color: AppColors.border),
          _MenuItem(
            icon: Icons.notifications_none,
            label: 'Notification Preferences',
            onTap: () => context.push('/notifications'),
          ),
          const Divider(height: 1, color: AppColors.border),
          _MenuItem(
            icon: Icons.help_outline,
            label: 'Help, FAQ & Civic Support',
            onTap: () => context.push('/help'),
          ),
          const Divider(height: 1, color: AppColors.border),
          _MenuItem(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () => context.push('/terms'),
          ),
          const Divider(height: 1, color: AppColors.border),
          _MenuItem(
            icon: Icons.info_outline,
            label: 'About TakeMyTrash',
            onTap: () => context.push('/about'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutSection() {
    return Column(
      children: [
        AppButton(
          label: 'Sign Out',
          variant: AppButtonVariant.outline,
          onPressed: () => _handleLogout(context),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'TakeMyTrash Citizen Portal • Bangalore Urban Ward 150',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
    );
  }
}
