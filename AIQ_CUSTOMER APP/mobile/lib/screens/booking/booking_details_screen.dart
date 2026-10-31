import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const BookingDetailsScreen({super.key, required this.params});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  String _selectedWaste = '';
  String _selectedQuantity = '';
  final _notesCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  Color get _activeThemeColor {
    return switch (_selectedWaste) {
      'recyclable' => Colors.cyanAccent,
      'organic' => Colors.greenAccent,
      'electronic' => Colors.purpleAccent,
      'hazardous' => Colors.redAccent,
      _ => AppColors.primary,
    };
  }

  int? get _estimatedPrice {
    if (_selectedWaste.isEmpty || _selectedQuantity.isEmpty) return null;
    final q = AppConstants.quantities.firstWhere((q) => q['value'] == _selectedQuantity);
    return q['price'] as int;
  }

  bool get _isValid {
    if (_selectedWaste.isEmpty || _selectedQuantity.isEmpty) return false;
    if (widget.params['type'] == 'SCHEDULED') {
      if (_dateCtrl.text.isEmpty || _timeCtrl.text.isEmpty) return false;
    }
    return true;
  }

  void _handleNext() {
    if (!_isValid) return;

    DateTime? scheduledAt;
    if (widget.params['type'] == 'SCHEDULED') {
      try {
        scheduledAt = DateTime.parse('${_dateCtrl.text} ${_timeCtrl.text}');
      } catch (_) {
        // Fallback or ignore for demo
        scheduledAt = DateTime.now().add(const Duration(days: 1));
      }
    }

    context.push('/booking-confirm', extra: {
      ...widget.params,
      'wasteType': _selectedWaste,
      'quantity': _selectedQuantity,
      'notes': _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
      'estimatedPrice': _estimatedPrice?.toDouble() ?? 49.0,
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _dateCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTimeSlot() async {
    final slots = [
      '09:00 - 10:00',
      '10:00 - 11:00',
      '11:00 - 12:00',
      '12:00 - 13:00',
      '13:00 - 14:00',
      '14:00 - 15:00',
      '15:00 - 16:00',
      '16:00 - 17:00',
    ];

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Time Slot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    return ListTile(
                      title: Text(slot, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                      onTap: () {
                        setState(() {
                          _timeCtrl.text = slot.split(' - ')[0]; // Store the start time '09:00'
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isImmediate = widget.params['type'] == 'IMMEDIATE';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isImmediate ? '⚡ Immediate' : '📅 Scheduled',
                style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            const Text('Pickup Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address preview
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.params['address'] as String,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Waste Type',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12, runSpacing: 12,
                      children: AppConstants.wasteTypes.map((w) {
                        final isSelected = _selectedWaste == w['value'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedWaste = w['value']!),
                          child: Container(
                            width: (MediaQuery.of(context).size.width - 48 - 24) / 3,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? _activeThemeColor.withOpacity(0.15) : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? _activeThemeColor : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(w['emoji']!, style: const TextStyle(fontSize: 24)),
                                const SizedBox(height: 8),
                                Text(w['label']!,
                                    style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w600,
                                      color: isSelected ? _activeThemeColor : AppColors.textMuted,
                                    ), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    const Text('Quantity / Volume',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: AppConstants.quantities.asMap().entries.map((entry) {
                          final i = entry.key;
                          final q = entry.value;
                          final isSelected = _selectedQuantity == q['value'];
                          return Column(
                            children: [
                              ListTile(
                                onTap: () => setState(() => _selectedQuantity = q['value'] as String),
                                leading: Container(
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? _activeThemeColor : AppColors.border,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: _activeThemeColor, shape: BoxShape.circle)))
                                      : null,
                                ),
                                title: Text(q['label'] as String,
                                    style: TextStyle(fontSize: 13, color: isSelected ? _activeThemeColor : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                                trailing: Text('₹${q['price']}',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _activeThemeColor)),
                              ),
                              if (i < AppConstants.quantities.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!isImmediate) ...[
                      const Text('Schedule Date & Time',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              hint: 'Select Date',
                              controller: _dateCtrl,
                              prefixIcon: Icons.calendar_today,
                              readOnly: true,
                              onTap: _selectDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              hint: 'Select Slot',
                              controller: _timeCtrl,
                              prefixIcon: Icons.access_time,
                              readOnly: true,
                              onTap: _selectTimeSlot,
                            ),
                          ),
                        ],
                      ),
                    ],

                    AppTextField(
                      label: 'Special Instructions (Optional)',
                      hint: 'e.g. Please call before arriving...',
                      controller: _notesCtrl,
                      prefixIcon: Icons.chat_bubble_outline,
                      maxLines: 3,
                    ),

                    if (_estimatedPrice != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _activeThemeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _activeThemeColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Price',
                                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            Text('₹$_estimatedPrice',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _activeThemeColor)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                label: 'Review Booking',
                onPressed: _isValid ? _handleNext : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
