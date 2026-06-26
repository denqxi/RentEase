import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_toggle.dart';
import 'pricing_amenities_screen.dart';

class PropertyRulesScreen extends StatefulWidget {
  const PropertyRulesScreen({super.key});

  @override
  State<PropertyRulesScreen> createState() => _PropertyRulesScreenState();
}

class _PropertyRulesScreenState extends State<PropertyRulesScreen> {
  String? selectedGender;
  bool smokingAllowed = false;
  bool petsAllowed = false;
  TimeOfDay? curfewTime;
  int minStay = 1;
  int maxOccupants = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set your non-negotiables.'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Define who can rent your space. These rules will filter incoming tenant requests.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            Text(
              'Allowed gender',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedGender,
              items: ['Female only', 'Male only', 'All']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => selectedGender = v),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.fieldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  borderSide: BorderSide(color: AppColors.ownerPrimary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Smoking allowed',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                ),
                AppToggle(
                  value: smokingAllowed,
                  onChanged: (v) => setState(() => smokingAllowed = v),
                  activeColor: AppColors.ownerPrimary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pets allowed',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                ),
                AppToggle(
                  value: petsAllowed,
                  onChanged: (v) => setState(() => petsAllowed = v),
                  activeColor: AppColors.ownerPrimary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Curfew hour',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: curfewTime ?? TimeOfDay.now(),
                );
                if (picked != null) setState(() => curfewTime = picked);
              },
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.fieldBg,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      curfewTime != null
                          ? curfewTime!.format(context)
                          : 'Tap to set',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Minimum stay (months)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(() {
                    if (minStay > 1) minStay--;
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  '$minStay',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => minStay++),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Max occupants',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(() {
                    if (maxOccupants > 1) maxOccupants--;
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  '$maxOccupants',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => maxOccupants++),
                ),
              ],
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Save and continue',
              color: AppColors.ownerPrimary,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PricingAmenitiesScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
