import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/card_over_hero_layout.dart';
import 'property_rules_screen.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _hasLocation = false;
  final List<bool> _photoSlots = [false, false, false];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CardOverHeroLayout(
      hero: const HeroPlaceholder(),
      cardHeightFraction: 0.82,
      cardContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(currentStep: 1, totalSteps: 3, label: 'Step 2 of 3'),
          SizedBox(height: AppSpacing.md),
          Text(
            'Add your property.',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text('Fill in the basic details of your boarding house.', style: AppTextStyles.body(context)),
          SizedBox(height: AppSpacing.lg),
          LabelledField(
            label: 'Property name',
            child: AppTextField(
              controller: _nameController,
              hintText: 'e.g. Sunshine Boarding House',
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          LabelledField(
            label: 'Address',
            child: AppTextField(
              controller: _addressController,
              hintText: 'Street, Barangay, City',
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text('Location', style: AppTextStyles.label(context).copyWith(color: context.appColors.textSecondary)),
          SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTapDown: (_) => setState(() => _hasLocation = true),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadii.field),
                border: Border.all(color: context.appColors.fieldBorder),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasLocation ? Icons.location_pin : Icons.map_rounded,
                      color: AppColors.accent,
                      size: 36,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      _hasLocation ? 'Location set' : 'Tap to pin location',
                      style: AppTextStyles.caption(context).copyWith(color: context.appColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text('Photos', style: AppTextStyles.label(context).copyWith(color: context.appColors.textSecondary)),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? AppSpacing.sm : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _photoSlots[i] = !_photoSlots[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 80,
                      decoration: BoxDecoration(
                        color: _photoSlots[i] ? AppColors.accentSoft : context.appColors.fieldFill,
                        borderRadius: BorderRadius.circular(AppRadii.field),
                        border: Border.all(
                          color: _photoSlots[i] ? AppColors.accent : context.appColors.fieldBorder,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _photoSlots[i] ? Icons.check_rounded : Icons.add_a_photo_outlined,
                          color: _photoSlots[i] ? AppColors.accent : context.appColors.hint,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Continue',
            onPressed: _nameController.text.isNotEmpty && _addressController.text.isNotEmpty
                ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const PropertyRulesScreen()),
                    )
                : null,
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
