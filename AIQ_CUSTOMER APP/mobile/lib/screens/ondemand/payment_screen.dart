import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedMethod;
  bool _isProcessing = false;
  bool _isPaid = false;

  final List<Map<String, dynamic>> _methods = [
    {'id': 'upi', 'label': 'UPI (Google Pay, PhonePe)', 'icon': Icons.qr_code_scanner},
    {'id': 'card', 'label': 'Credit / Debit Card', 'icon': Icons.credit_card},
    {'id': 'cash', 'label': 'Cash to Rider', 'icon': Icons.money},
  ];

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;
    
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isPaid = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isPaid ? 'Receipt' : 'Complete Payment',
          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false, // Don't allow back during payment
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width >= 900 ? 780 : double.infinity,
            ),
            child: _isPaid ? _buildReceipt() : _buildPayment(),
          ),
        ),
      ),
    );
  }

  Widget _buildPayment() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bill Summary
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pickup Summary', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      _buildBillRow('Waste', 'Household Waste'),
                      const SizedBox(height: 8),
                      _buildBillRow('Quantity', '5–15 kg'),
                      const SizedBox(height: 8),
                      _buildBillRow('Pickup', 'Doorstep'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: AppColors.border),
                      ),
                      _buildBillRow('Pickup fee', '₹29'),
                      const SizedBox(height: 8),
                      _buildBillRow('Service fee', '₹15'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: AppColors.border),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Total', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          Text('₹44', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Payment Methods
                const Text('Payment Method', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                ..._methods.map((method) {
                  final isSelected = _selectedMethod == method['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMethod = method['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(method['icon'], color: isSelected ? AppColors.primary : AppColors.textSecondary),
                          const SizedBox(width: 16),
                          Text(
                            method['label'],
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Row(
                  children: const [
                    Icon(Icons.lock, size: 14, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Text('Your payment information is protected securely.', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        
        // Sticky Pay Button
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedMethod == null || _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isProcessing 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Pay ₹44', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceipt() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: AppColors.success, size: 40),
          ),
          const SizedBox(height: 24),
          const Text('Pickup Completed ✓', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text('Thanks for helping keep your neighborhood clean.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: AppColors.textSecondary)),
          
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Collection Details', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                _buildBillRow('Rider', 'Arun Kumar'),
                const SizedBox(height: 8),
                _buildBillRow('Vehicle', 'Mini Tipper'),
                const SizedBox(height: 8),
                _buildBillRow('Waste', 'Household Waste'),
                const SizedBox(height: 8),
                _buildBillRow('Amount', '₹44'),
                const SizedBox(height: 8),
                _buildBillRow('Time', 'Just now'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: AppColors.border),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Status', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: AppColors.textSecondary)),
                    Text('🟢 Completed', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          const Text('How was your pickup?', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.star_border, color: AppColors.warning, size: 40),
            )),
          ),
          
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: const Text('View Receipt', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Done', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
