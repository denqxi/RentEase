import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../features/registration/widgets/step_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../model/property_draft.dart';
import 'owner_topsis_screen.dart';

class PricingAmenitiesScreen extends StatefulWidget {
  const PricingAmenitiesScreen({super.key});

  @override
  State<PricingAmenitiesScreen> createState() => _PricingAmenitiesScreenState();
}

class _PricingAmenitiesScreenState extends State<PricingAmenitiesScreen> {
  final _rentController = TextEditingController();
  final Set<String> _selected = {};

  @override
  void dispose() {
    _rentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: RegistrationAppBar(
                onBack: () => Navigator.of(context).maybePop(),
                stepNumber: 3,
                stepCount: 4,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StepHeader(
                      title: 'Pricing & amenities.',
                      subtitle:
                          'Set your rent and list what your property offers.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LabelledField(
                              label: 'Monthly rent (PHP)',
                              child: AppTextField(
                                controller: _rentController,
                                hintText: '3500',
                                prefixText: '₱ ',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Text(
                                  'Amenities',
                                  style: AppTextStyles.label(context).copyWith(
                                    color: context.appColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_selected.length} of ${MockData.amenities.length} selected',
                                  style: AppTextStyles.caption(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: MockData.amenities.map((amenity) {
                                final isSelected = _selected.contains(amenity);
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    if (isSelected) {
                                      _selected.remove(amenity);
                                    } else {
                                      _selected.add(amenity);
                                    }
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.accentSoft
                                          : context.appColors.fieldFill,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.accent
                                            : context.appColors.fieldBorder,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        amenity,
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.accent
                                              : context.appColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppPrimaryButton(
                      label: 'Continue',
                      onPressed: _rentController.text.isNotEmpty
                          ? () {
                              NewPropertyDraft.rent =
                                  int.tryParse(_rentController.text) ?? 0;
                              NewPropertyDraft.amenities = Set.of(_selected);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const OwnerTopsisScreen(
                                    stepNumber: 4,
                                    stepCount: 4,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
