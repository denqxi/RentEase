import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../features/registration/widgets/step_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../model/property_draft.dart';
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
                        NewPropertyDraft.deposit =
                            int.tryParse(_depositController.text) ?? 0;
                        NewPropertyDraft.advanceMonths =
                            int.tryParse(_advanceController.text) ?? 1;
                        NewPropertyDraft.genderPolicy =
                            _genderPolicy ?? 'Mixed / Any';
                        NewPropertyDraft.smokingAllowed = _smokingAllowed;
                        NewPropertyDraft.petsAllowed = _petsAllowed;
                        NewPropertyDraft.curfew = _curfew;
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
