import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_button.dart';

class RatingScreen extends StatefulWidget {
  final String bookingId;
  const RatingScreen({super.key, required this.bookingId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _stars = 0;
  String _comment = '';
  bool _isLoading = false;

  final List<String> _tags = ['On time', 'Professional', 'Clean', 'Friendly', 'Quick'];
  final List<String> _ratingLabels = ['', 'Terrible', 'Bad', 'Okay', 'Good', 'Excellent!'];

  Future<void> _handleSubmit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a star rating')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiClient.instance.post('/ratings', data: {
        'bookingId': widget.bookingId,
        'stars': _stars,
        'comment': _comment.isEmpty ? null : _comment,
      });
      
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('🎉 Thank you!', style: TextStyle(color: AppColors.textPrimary)),
          content: const Text('Your feedback helps us improve our service.', style: TextStyle(color: AppColors.textSecondary)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/dashboard');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_comment.contains(tag)) {
        _comment = _comment.replaceAll('$tag, ', '').replaceAll(', $tag', '').replaceAll(tag, '').trim();
      } else {
        _comment = _comment.isEmpty ? tag : '$_comment, $tag';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.primary, width: 2)),
                child: const Center(child: Text('✅', style: TextStyle(fontSize: 48))),
              ),
              const SizedBox(height: 24),
              const Text('Pickup Completed!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              const Text('How was your experience? Your feedback helps us serve you better.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _stars = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _stars >= star ? Icons.star : Icons.star_border,
                        size: 48,
                        color: _stars >= star ? const Color(0xFFFFB830) : AppColors.border,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              
              if (_stars > 0)
                Text(_ratingLabels[_stars], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFFFB830)))
              else
                const SizedBox(height: 28),
              
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 1.5)),
                child: Column(
                  children: [
                    TextField(
                      controller: TextEditingController(text: _comment)..selection = TextSelection.collapsed(offset: _comment.length),
                      onChanged: (v) => _comment = v,
                      maxLines: 4,
                      maxLength: 300,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Tell us more about your experience (optional)...',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Wrap(
                spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                children: _tags.map((tag) {
                  final isSelected = _comment.contains(tag);
                  return GestureDetector(
                    onTap: () => _toggleTag(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1.5),
                      ),
                      child: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textMuted)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              AppButton(
                label: 'Submit Review',
                onPressed: _stars > 0 ? _handleSubmit : null,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Skip for now', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
