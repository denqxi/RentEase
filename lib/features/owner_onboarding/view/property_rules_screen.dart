import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../../../shared/widgets/card_over_hero_layout.dart';
import 'pricing_amenities_screen.dart';

class PropertyRulesScreen extends StatefulWidget {
  const PropertyRulesScreen({super.key});

  @override
  State<PropertyRulesScreen> createState() => _PropertyRulesScreenState();
}

class _PropertyRulesScreenState extends State<PropertyRulesScreen> {
  final _depositController = TextEditingController();
  final _advanceController = TextEditingController();
  String? _genderPolicy;
  bool _smokingAllowed = false;
  bool _petsAllowed = false;
  String _curfew = '10:00 PM';

  Future<void> _pickCurfew() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() => _curfew = picked.format(context));
    }
  }

  @override
  void dispose() {
    _depositController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CardOverHeroLayout(
      hero: const HeroPlaceholder(),
      cardContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(currentStep: 2, totalSteps: 3, label: 'Step 3 of 3'),
          SizedBox(height: AppSpacing.md),
          Text(
            'Set your non-negotiables.',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text('Define the house rules for your tenants.', style: AppTextStyles.body(context)),
          SizedBox(height: AppSpacing.lg),
          LabelledField(
            label: 'Deposit (PHP)',
            child: AppTextField(
              controller: _depositController,
              hintText: '3500',
              prefixText: '₱ ',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          LabelledField(
            label: 'Advance months',
            child: AppTextField(
              controller: _advanceController,
              hintText: '1',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          LabelledField(
            label: 'Gender policy',
            child: DropdownButtonFormField<String>(
              initialValue: _genderPolicy,
              hint: Text('Select...', style: TextStyle(color: context.appColors.hint, fontFamily: 'DM Sans')),
              decoration: InputDecoration(
                filled: true,
                fillColor: context.appColors.fieldFill,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  borderSide: BorderSide(color: context.appColors.fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.field)),
              ),
              items: [
                DropdownMenuItem(value: 'Female only', child: Text('Female only')),
                DropdownMenuItem(value: 'Male only', child: Text('Male only')),
                DropdownMenuItem(value: 'Mixed / Any', child: Text('Mixed / Any')),
              ],
              onChanged: (v) => setState(() => _genderPolicy = v),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          _ToggleRow(label: 'Smoking allowed', value: _smokingAllowed, onChanged: (v) => setState(() => _smokingAllowed = v)),
          SizedBox(height: AppSpacing.sm),
          _ToggleRow(label: 'Pets allowed', value: _petsAllowed, onChanged: (v) => setState(() => _petsAllowed = v)),
          SizedBox(height: AppSpacing.md),
          LabelledField(
            label: 'Curfew',
            child: AppTextField(
              hintText: 'Select curfew time',
              controller: TextEditingController(text: _curfew),
              readOnly: true,
              onTap: _pickCurfew,
              suffixIcon: Icon(Icons.access_time_rounded, color: context.appColors.hint, size: 20),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Save and Continue',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PricingAmenitiesScreen()),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.label(context).copyWith(color: context.appColors.textPrimary))),
        AppToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}
