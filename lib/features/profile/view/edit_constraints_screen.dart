import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_toggle.dart';

class EditConstraintsScreen extends StatefulWidget {
  const EditConstraintsScreen({super.key});

  @override
  State<EditConstraintsScreen> createState() => _EditConstraintsScreenState();
}

class _EditConstraintsScreenState extends State<EditConstraintsScreen> {
  final TextEditingController budgetController =
      TextEditingController(text: '4500');
  String? selectedGender = 'Female only';
  bool wifiRequired = true;
  bool privateBath = false;
  double maxDistance = 3.0;
  TimeOfDay curfewTime = const TimeOfDay(hour: 22, minute: 0);

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickCurfewTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: curfewTime,
    );
    if (picked != null) {
      setState(() => curfewTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit preferences',
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // 1. Max monthly budget
                  const Text(
                    'Max monthly budget',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppTextField(
                    controller: budgetController,
                    prefixText: 'PHP',
                    keyboardType: TextInputType.number,
                    hintText: '0',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Gender policy
                  const Text(
                    'Gender policy',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGender,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.fieldBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.field),
                        borderSide: const BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.field),
                        borderSide: const BorderSide(
                          color: AppColors.primaryMid,
                          width: 1,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.field),
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
                    onChanged: (val) =>
                        setState(() => selectedGender = val),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 3. WiFi required
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
                        value: wifiRequired,
                        onChanged: (val) =>
                            setState(() => wifiRequired = val),
                        activeColor: AppColors.primaryMid,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 4. Private bathroom
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
                        value: privateBath,
                        onChanged: (val) =>
                            setState(() => privateBath = val),
                        activeColor: AppColors.primaryMid,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 5. Max distance
                  Row(
                    children: [
                      const Text(
                        'Max distance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${maxDistance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryMid,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: maxDistance,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    activeColor: AppColors.primaryMid,
                    onChanged: (val) =>
                        setState(() => maxDistance = val),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 6. Curfew needed
                  const Text(
                    'Curfew needed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    onTap: _pickCurfewTime,
                    child: Container(
                      height: AppSizes.fieldHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.fieldBg,
                        borderRadius: BorderRadius.circular(AppRadii.field),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        curfewTime.format(context),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Column(
              children: [
                AppButton(
                  label: 'Save changes',
                  color: AppColors.primaryMid,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Saving will recompute your property matches.',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
