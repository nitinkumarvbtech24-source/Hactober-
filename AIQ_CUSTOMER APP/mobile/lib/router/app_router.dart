import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

import '../screens/dashboard/home_map_screen.dart';
import '../screens/report/report_issue_screen.dart';

import '../screens/ondemand/book_ondemand_screen.dart';
import '../screens/ondemand/rider_matching_screen.dart';
import '../screens/ondemand/live_tracking_screen.dart';
import '../screens/ondemand/payment_screen.dart';

import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/privacy_security_screen.dart';
import '../screens/profile/notifications_screen.dart';
import '../screens/profile/help_support_screen.dart';
import '../screens/profile/terms_service_screen.dart';
import '../screens/profile/about_screen.dart';

class AppRouter {
  static CustomTransitionPage _buildTransition(Widget child, LocalKey? key) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static GoRouter createRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final isAuth = auth.isAuthenticated;
        final isInitializing = auth.isInitializing;
        final path = state.matchedLocation;

        if (isInitializing) return '/splash';

        if (path == '/splash') {
          return isAuth ? '/home' : '/login';
        }

        final isAuthRoute = path == '/login' || path == '/register';

        if (!isAuth && !isAuthRoute) return '/login';
        if (isAuth && isAuthRoute) return '/home';

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          pageBuilder: (_, state) => _buildTransition(const SplashScreen(), state.pageKey),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (_, state) => _buildTransition(const LoginScreen(), state.pageKey),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (_, state) => _buildTransition(const RegisterScreen(), state.pageKey),
        ),

        // Main shell with bottom nav
        ShellRoute(
          pageBuilder: (context, state, child) => _buildTransition(MainShell(child: child), state.pageKey),
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (_, state) => _buildTransition(const HomeMapScreen(), state.pageKey),
            ),
            GoRoute(
              path: '/report',
              pageBuilder: (_, state) => _buildTransition(const ReportIssueScreen(), state.pageKey),
            ),

            GoRoute(
              path: '/book',
              pageBuilder: (_, state) => _buildTransition(const BookOndemandScreen(), state.pageKey),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (_, state) => _buildTransition(const ProfileScreen(), state.pageKey),
            ),
          ],
        ),

        // On-Demand Full Screen Flows
        GoRoute(
          path: '/matching',
          pageBuilder: (_, state) => _buildTransition(
            RiderMatchingScreen(bookingDetails: state.extra as Map<String, dynamic>?),
            state.pageKey,
          ),
        ),
        GoRoute(
          path: '/tracking_live',
          pageBuilder: (_, state) => _buildTransition(
            LiveTrackingScreen(rideDetails: state.extra as Map<String, dynamic>?),
            state.pageKey,
          ),
        ),
        GoRoute(
          path: '/payment',
          pageBuilder: (_, state) => _buildTransition(const PaymentScreen(), state.pageKey),
        ),

        // Keep profile routes if needed
        // (Moved /profile into ShellRoute above)
        
        GoRoute(
          path: '/edit-profile',
          pageBuilder: (_, state) => _buildTransition(const EditProfileScreen(), state.pageKey),
        ),
        GoRoute(
          path: '/privacy',
          pageBuilder: (_, state) => _buildTransition(const PrivacySecurityScreen(), state.pageKey),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (_, state) => _buildTransition(const NotificationsScreen(), state.pageKey),
        ),
        GoRoute(
          path: '/help',
          pageBuilder: (_, state) => _buildTransition(const HelpSupportScreen(), state.pageKey),
        ),
        GoRoute(
          path: '/terms',
          pageBuilder: (_, state) => _buildTransition(const TermsServiceScreen(), state.pageKey),
        ),
        GoRoute(
          path: '/about',
          pageBuilder: (_, state) => _buildTransition(const AboutScreen(), state.pageKey),
        ),
      ],
    );
  }
}

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  static void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  static void closeDrawer() {
    if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
      scaffoldKey.currentState?.closeDrawer();
    }
  }

  static bool get isDrawerOpen => scaffoldKey.currentState?.isDrawerOpen ?? false;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _routes = ['/home', '/report', '/book', '/profile'];

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/report')) return 1;
    if (location.startsWith('/book')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.lightImpact();
    MainShell.closeDrawer();
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;
    final user = context.watch<AuthProvider>().user;

    // Derived user labels (strictly never show 'Demo User')
    final rawName = user?.name.trim() ?? '';
    final rawUsername = user?.username.trim() ?? '';
    final displayName = (rawName.isNotEmpty && rawName != 'Demo User')
        ? rawName
        : (rawUsername.isNotEmpty ? rawUsername : 'Citizen User');
    final displayUsername = (rawUsername.isNotEmpty)
        ? '@$rawUsername'
        : (user?.email.isNotEmpty == true ? user!.email : '');
    final displayContact = (user?.phone.isNotEmpty == true && user?.phone != '1234567890')
        ? user!.phone
        : (user?.email.isNotEmpty == true ? user!.email : '');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    final sidebarWidget = _buildSidebarContent(
      context,
      selectedIndex: selectedIndex,
      displayName: displayName,
      displayUsername: displayUsername,
      displayContact: displayContact,
      initial: initial,
      isDesktop: isDesktop,
    );

    return Scaffold(
      key: MainShell.scaffoldKey,
      backgroundColor: AppColors.background,
      // Collapsible drawer: comes out when clicked from left
      drawer: Drawer(
        elevation: 16,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
        child: sidebarWidget,
      ),
      body: widget.child,
      // Phone navigation bar: visible on phone/narrow viewports
      bottomNavigationBar: (!isDesktop)
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (idx) => _onItemTapped(idx, context),
                backgroundColor: Colors.white,
                indicatorColor: AppColors.primary.withOpacity(0.12),
                elevation: 0,
                height: 64,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map_rounded, color: AppColors.primary),
                    label: 'Map',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.camera_alt_outlined),
                    selectedIcon: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                    label: 'Report',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.local_shipping_outlined),
                    selectedIcon: Icon(Icons.local_shipping_rounded, color: AppColors.primary),
                    label: 'Book',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                    label: 'Profile',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildSidebarContent(
    BuildContext context, {
    required int selectedIndex,
    required String displayName,
    required String displayUsername,
    required String displayContact,
    required String initial,
    required bool isDesktop,
  }) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Logo & Collapse Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.recycling_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'TakeMyTrash',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Citizen Portal',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Collapse Button
                IconButton(
                  tooltip: 'Collapse sidebar',
                  icon: const Icon(Icons.chevron_left_rounded, size: 26, color: AppColors.textSecondary),
                  onPressed: () => MainShell.closeDrawer(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map_rounded,
                  label: 'Live Tracking Map',
                  isSelected: selectedIndex == 0,
                ),
                const SizedBox(height: 6),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: Icons.camera_alt_outlined,
                  activeIcon: Icons.camera_alt_rounded,
                  label: 'Report Waste Issue',
                  isSelected: selectedIndex == 1,
                ),
                const SizedBox(height: 6),
                _buildNavItem(
                  context,
                  index: 2,
                  icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping_rounded,
                  label: 'Book Doorstep Pickup',
                  isSelected: selectedIndex == 2,
                ),
                const SizedBox(height: 6),
                _buildNavItem(
                  context,
                  index: 3,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile & Settings',
                  isSelected: selectedIndex == 3,
                ),
              ],
            ),
          ),

          // Real User Account Card at Bottom (Never "Demo User")
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (displayUsername.isNotEmpty)
                        Text(
                          displayUsername,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        )
                      else if (displayContact.isNotEmpty)
                        Text(
                          displayContact,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textSecondary),
                  tooltip: 'Sign Out',
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onItemTapped(index, context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: AppColors.primary.withOpacity(0.25)) : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
