import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class BookPickupScreen extends StatelessWidget {
  const BookPickupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Book a Pickup',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 28, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary, letterSpacing: -1.0)),
                    const SizedBox(height: 8),
                    const Text("Choose how you'd like us to collect your trash",
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: AppColors.textSecondary,
                            height: 1.5)),
                    const SizedBox(height: 32),

                    // Immediate card
                    _PickupTypeCard(
                      emoji: '⚡',
                      title: 'Immediate Pickup',
                      description:
                          'A collector will be assigned right now. Expected arrival in 15–30 minutes.',
                      badge: 'Available 24/7',
                      color: AppColors.primary,
                      lightColor: AppColors.primaryLight,
                      onTap: () => context.push('/booking-address', extra: 'IMMEDIATE'),
                    ),
                    const SizedBox(height: 16),

                    // Scheduled card
                    _PickupTypeCard(
                      emoji: '📅',
                      title: 'Scheduled Pickup',
                      description:
                          'Choose a date and time that works best for you. We\'ll send you a reminder.',
                      badge: 'Pick your slot',
                      color: AppColors.accent,
                      lightColor: AppColors.accentLight,
                      onTap: () => context.push('/booking-address', extra: 'SCHEDULED'),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.info),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, color: AppColors.info, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pricing starts at ₹49. Final price based on waste type & quantity.',
                              style: TextStyle(color: AppColors.info, fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickupTypeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final String badge;
  final Color color;
  final Color lightColor;
  final VoidCallback onTap;

  const _PickupTypeCard({
    required this.emoji, required this.title, required this.description,
    required this.badge, required this.color, required this.lightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface, // Pure dark surface
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.6), width: 2), // Stronger neon border
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: color, // Solid neon block
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  emoji, 
                  style: const TextStyle(fontSize: 26, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      )),
                  const SizedBox(height: 6),
                  Text(description,
                      style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color, width: 1.5),
                    ),
                    child: Text(badge,
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, color: color, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
