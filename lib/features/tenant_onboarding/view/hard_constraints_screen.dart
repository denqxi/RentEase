import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_toggle.dart';
import 'poi_setup_screen.dart';

class HardConstraintsScreen extends StatefulWidget {
  const HardConstraintsScreen({this.onComplete, super.key});

  /// Called by the last screen in the onboarding chain (TopsisWeightScreen)
  /// instead of popping to root. Pass this when entering from registration.
  final VoidCallback? onComplete;

  @override
  State<HardConstraintsScreen> createState() => _HardConstraintsScreenState();
}

class _HardConstraintsScreenState extends State<HardConstraintsScreen> {
  final TextEditingController _budgetController = TextEditingController();
  String? _selectedGender;
  bool _wifiRequired = false;
  bool _privateBath = false;
  double _maxDistance = 3.0;
  TimeOfDay? _curfewTime;

  bool get _canProceed =>
      _budgetController.text.isNotEmpty && _selectedGender != null;

  @override
  void initState() {
    super.initState();
    _budgetController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickCurfewTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _curfewTime ?? const TimeOfDay(hour: 22, minute: 0),
    );
    if (picked != null) {
      setState(() => _curfewTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left,
              color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Preferences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Step progress bar
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMid,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Step 1 of 3',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'What are your non-negotiables?',
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Only matching properties will appear in your search.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Max monthly budget',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _budgetController,
                    prefixText: '₱',
                    keyboardType: TextInputType.number,
                    hintText: '4,500',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Gender policy',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    hint: const Text(
                      'Select gender policy',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 14),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.fieldBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primaryMid,
                          width: 1.5,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Female only',
                        child: Text('Female only'),
                      ),
                      DropdownMenuItem(
                        value: 'Male only',
                        child: Text('Male only'),
                      ),
                      DropdownMenuItem(
                        value: 'Any',
                        child: Text('Any'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedGender = v),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'WiFi required',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      AppToggle(
                        value: _wifiRequired,
                        onChanged: (v) =>
                            setState(() => _wifiRequired = v),
                        activeColor: AppColors.primaryMid,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Private bathroom',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      AppToggle(
                        value: _privateBath,
                        onChanged: (v) =>
                            setState(() => _privateBath = v),
                        activeColor: AppColors.primaryMid,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Max distance from school/work',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_maxDistance.round()} km',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryMid,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primaryMid,
                      thumbColor: AppColors.primaryMid,
                      inactiveTrackColor: AppColors.border,
                      overlayColor:
                          AppColors.primaryMid.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: _maxDistance,
                      min: 0,
                      max: 10,
                      divisions: 20,
                      onChanged: (v) =>
                          setState(() => _maxDistance = v),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Curfew needed',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickCurfewTime,
                    child: Container(
                      height: 52,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.fieldBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _curfewTime != null
                            ? _curfewTime!.format(context)
                            : 'Set time',
                        style: TextStyle(
                          fontSize: 14,
                          color: _curfewTime != null
                              ? AppColors.textPrimary
                              : AppColors.hint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: AppPrimaryButton(
              label: 'Save and Continue',
              onPressed: _canProceed
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PoiSetupScreen(
                            onComplete: widget.onComplete,
                          ),
                        ),
                      )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
