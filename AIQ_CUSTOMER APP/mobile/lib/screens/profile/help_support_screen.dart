import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_button.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
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
            children: [
              // Contact options
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Live Chat',
                      variant: AppButtonVariant.primary,
                      onPressed: () {},
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      label: 'Email Us',
                      variant: AppButtonVariant.outline,
                      onPressed: () {},
                      icon: const Icon(Icons.email_outlined, color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              _buildFaq(
                'How does pricing work?',
                'Pricing is calculated based on the type of waste, total weight, and the distance to the nearest recycling facility. The exact estimate is shown before booking.',
              ),
              _buildFaq(
                'What types of waste do you accept?',
                'We accept plastic, electronic waste (e-waste), paper, glass, and general recyclable dry waste. Hazardous materials are not accepted.',
              ),
              _buildFaq(
                'Can I cancel a scheduled pickup?',
                'Yes! You can cancel a pickup up to 2 hours before the scheduled time without any penalty.',
              ),
              _buildFaq(
                'When do I get paid?',
                'For scrap that carries value, the amount is credited directly to your registered payment method or wallet within 24 hours after successful pickup.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaq(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
