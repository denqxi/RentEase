import '../../../core/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../features/registration/widgets/step_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../cubit/owner_onboarding_cubit.dart';
import 'pricing_amenities_screen.dart';

class PropertyRulesScreen extends StatefulWidget {
  const PropertyRulesScreen({super.key});

  @override
  State<PropertyRulesScreen> createState() => _PropertyRulesScreenState();
}

class _PropertyRulesScreenState extends State<PropertyRulesScreen> {
  final _depositController = TextEditingController();
  final _advanceController = TextEditingController();
  final _maxOccupantsController = TextEditingController();
  String? _genderPolicy;
  bool _smokingAllowed = false;
  bool _petsAllowed = false;
  int _curfewHours = 22;

  String get _curfew => formatCurfew(_curfewHours);

  Future<void> _pickCurfew() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _curfewHours, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() => _curfewHours = picked.hour);
    }
  }

  @override
  void dispose() {
    _depositController.dispose();
    _advanceController.dispose();
    _maxOccupantsController.dispose();
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
                stepNumber: 2,
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
                      title: 'Set your non-negotiables.',
                      subtitle: 'Define the house rules for your tenants.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LabelledField(
                              label: 'Deposit (PHP)',
                              child: AppTextField(
                                controller: _depositController,
                                hintText: '3500',
                                prefixText: '₱ ',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            LabelledField(
                              label: 'Advance months',
                              child: AppTextField(
                                controller: _advanceController,
                                hintText: '1',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Layer 1 OccupancyMatch: a tenant's group size
                            // must not exceed this.
                            LabelledField(
                              label: 'Max occupants per room',
                              child: AppTextField(
                                controller: _maxOccupantsController,
                                hintText: '1',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            LabelledField(
                              label: 'Gender policy',
                              child: DropdownButtonFormField<String>(
                                initialValue: _genderPolicy,
                                hint: Text(
                                  'Select...',
                                  style: TextStyle(
                                    color: context.appColors.hint,
                                    fontFamily: 'DM Sans',
                                  ),
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: context.appColors.fieldFill,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                          vertical: 14),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.field),
                                    borderSide: BorderSide(
                                        color: context.appColors.fieldBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.field),
                                    borderSide: BorderSide(
                                        color: AppColors.accent, width: 1.5),
                                  ),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppRadii.field)),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Female only',
                                      child: Text('Female only')),
                                  DropdownMenuItem(
                                      value: 'Male only',
                                      child: Text('Male only')),
                                  DropdownMenuItem(
                                      value: 'Mixed / Any',
                                      child: Text('Mixed / Any')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _genderPolicy = v),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _ToggleRow(
                              label: 'Smoking allowed',
                              value: _smokingAllowed,
                              onChanged: (v) =>
                                  setState(() => _smokingAllowed = v),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _ToggleRow(
                              label: 'Pets allowed',
                              value: _petsAllowed,
                              onChanged: (v) =>
                                  setState(() => _petsAllowed = v),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            LabelledField(
                              label: 'Curfew',
                              child: AppTextField(
                                hintText: 'Select curfew time',
                                controller:
                                    TextEditingController(text: _curfew),
                                readOnly: true,
                                onTap: _pickCurfew,
                                suffixIcon: Icon(
                                  Icons.access_time_rounded,
                                  color: context.appColors.hint,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppPrimaryButton(
                      label: 'Continue',
                      onPressed: () {
                        final maxOccupants =
                            int.tryParse(_maxOccupantsController.text) ?? 1;
                        context.read<OwnerOnboardingCubit>().saveRules(
                          depositAmount:
                              int.tryParse(_depositController.text) ?? 0,
                          advanceMonths:
                              int.tryParse(_advanceController.text) ?? 1,
                          allowedGender: _genderPolicy ?? 'Mixed / Any',
                          smokingAllowed: _smokingAllowed,
                          petsAllowed: _petsAllowed,
                          curfewHours: _curfewHours,
                          maxOccupants: maxOccupants < 1 ? 1 : maxOccupants,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PricingAmenitiesScreen(),
                          ),
                        );
                      },
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.label(context)
                .copyWith(color: context.appColors.textPrimary),
          ),
        ),
        AppToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}
