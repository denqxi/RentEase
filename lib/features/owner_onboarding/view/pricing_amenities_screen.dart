import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../features/registration/widgets/step_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/presentation/current_uid.dart';
import '../cubit/owner_onboarding_cubit.dart';

class PricingAmenitiesScreen extends StatefulWidget {
  const PricingAmenitiesScreen({super.key});

  @override
  State<PricingAmenitiesScreen> createState() => _PricingAmenitiesScreenState();
}

class _PricingAmenitiesScreenState extends State<PricingAmenitiesScreen> {
  final _rentController = TextEditingController();
  final Set<String> _selected = {};
  bool _saving = false;

  @override
  void dispose() {
    _rentController.dispose();
    super.dispose();
  }

  // Final step: the owner-side TOPSIS weights are fixed (CLAUDE.md — no
  // longer owner-adjustable, unlike the tenant side), so there's no separate
  // weight-slider step here — saving pricing creates the listing directly.
  Future<void> _submit() async {
    final uid = currentUidOrNull(context);
    if (uid == null) {
      _showError('Your session has expired. Please sign in again.');
      return;
    }
    final cubit = context.read<OwnerOnboardingCubit>();
    cubit.savePricing(
      monthlyRent: int.tryParse(_rentController.text) ?? 0,
      // Checklist order, not tap order.
      amenities: MockData.amenities.where(_selected.contains).toList(),
    );

    setState(() => _saving = true);
    await cubit.submitProperty(uid: uid);
    if (!mounted) return;
    setState(() => _saving = false);

    final state = cubit.state;
    if (state.status != OwnerOnboardingStatus.saved) {
      _showError(state.errorMessage ?? 'Could not save your property.');
      return;
    }
    cubit.reset();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.matchingTransition,
      (_) => false,
      arguments: true, // owner
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.destructive),
    );
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
                stepCount: 3,
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
                      label: _saving ? 'Saving...' : 'Find Tenants',
                      onPressed:
                          (int.tryParse(_rentController.text) ?? 0) > 0 &&
                              !_saving
                          ? _submit
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
