import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../features/registration/widgets/step_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../model/property_draft.dart';
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

  bool get _canContinue =>
      _nameController.text.isNotEmpty && _addressController.text.isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
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
                stepNumber: 1,
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
                      title: 'Add your property.',
                      subtitle:
                          'Fill in the basic details of your boarding house.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LabelledField(
                              label: 'Property name',
                              child: AppTextField(
                                controller: _nameController,
                                hintText: 'e.g. Sunshine Boarding House',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            LabelledField(
                              label: 'Address',
                              child: AppTextField(
                                controller: _addressController,
                                hintText: 'Street, Barangay, City',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Location',
                              style: AppTextStyles.label(context)
                                  .copyWith(color: context.appColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            GestureDetector(
                              onTap: () => setState(() => _hasLocation = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 140,
                                decoration: BoxDecoration(
                                  color: _hasLocation
                                      ? AppColors.accentSoft
                                      : context.appColors.fieldFill,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.field),
                                  border: Border.all(
                                    color: _hasLocation
                                        ? AppColors.accent
                                        : context.appColors.fieldBorder,
                                    width: _hasLocation ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _hasLocation
                                            ? Icons.location_pin
                                            : Icons.map_rounded,
                                        color: _hasLocation
                                            ? AppColors.accent
                                            : context.appColors.hint,
                                        size: 32,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        _hasLocation
                                            ? 'Location set'
                                            : 'Tap to pin location',
                                        style: AppTextStyles.caption(context)
                                            .copyWith(
                                                color: _hasLocation
                                                    ? AppColors.accent
                                                    : context
                                                        .appColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Photos',
                              style: AppTextStyles.label(context)
                                  .copyWith(color: context.appColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: List.generate(3, (i) {
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        right: i < 2 ? AppSpacing.sm : 0),
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _photoSlots[i] = !_photoSlots[i]),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: _photoSlots[i]
                                              ? AppColors.accentSoft
                                              : context.appColors.fieldFill,
                                          borderRadius: BorderRadius.circular(
                                              AppRadii.field),
                                          border: Border.all(
                                            color: _photoSlots[i]
                                                ? AppColors.accent
                                                : context.appColors.fieldBorder,
                                            width: _photoSlots[i] ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _photoSlots[i]
                                                ? Icons.check_rounded
                                                : Icons.add_a_photo_outlined,
                                            color: _photoSlots[i]
                                                ? AppColors.accent
                                                : context.appColors.hint,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppPrimaryButton(
                      label: 'Continue',
                      onPressed: _canContinue
                          ? () {
                              NewPropertyDraft.name = _nameController.text.trim();
                              NewPropertyDraft.address =
                                  _addressController.text.trim();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PropertyRulesScreen(),
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
