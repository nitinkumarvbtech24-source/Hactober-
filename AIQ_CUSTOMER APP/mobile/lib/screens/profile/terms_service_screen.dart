import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class TermsServiceScreen extends StatelessWidget {
  const TermsServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Last updated: October 2023',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              SizedBox(height: 24),
              _TermSection(
                title: '1. Acceptance of Terms',
                content: 'By accessing and using TakeMyTrash, you accept and agree to be bound by the terms and provision of this agreement.',
              ),
              _TermSection(
                title: '2. User Responsibilities',
                content: 'Users must ensure that the waste provided matches the description given during booking. Hazardous materials are strictly prohibited. Users must be present at the address during the scheduled pickup time.',
              ),
              _TermSection(
                title: '3. Pricing & Payments',
                content: 'Estimated prices are subject to change based on the actual weight and condition of the materials collected. Final payouts or charges will be processed after driver verification.',
              ),
              _TermSection(
                title: '4. Cancellations',
                content: 'Cancellations must be made at least 2 hours before the scheduled time. Frequent last-minute cancellations may result in account suspension.',
              ),
              _TermSection(
                title: '5. Privacy',
                content: 'Your privacy is important to us. Please refer to our Privacy Policy to understand how we collect, use, and safeguard your data.',
              ),
              SizedBox(height: 40),
              Center(
                child: Text(
                  'End of Terms',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
