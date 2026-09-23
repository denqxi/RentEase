import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/form_step_layout.dart';
import '../../../features/registration/widgets/labeled_text_field.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../cubit/tenant_onboarding_cubit.dart';
import 'soft_preferences_step_screen.dart';

class HardConstraintsScreen extends StatefulWidget {
  const HardConstraintsScreen({super.key});

  @override
  State<HardConstraintsScreen> createState() => _HardConstraintsScreenState();
}

class _HardConstraintsScreenState extends State<HardConstraintsScreen> {
  final _budgetController = TextEditingController(text: '4500');
  String? _genderPolicy;
  bool _wifiRequired = true;
  // About you — owners filter on these (Layer 1: smoking, pets, occupancy).
  bool _isSmoker = false;
  bool _hasPet = false;
  final _groupSizeController = TextEditingController(text: '1');

  int? get _groupSize => int.tryParse(_groupSizeController.text.trim());

  num? get _budget => num.tryParse(_budgetController.text.trim());

  bool get _canProceed =>
      _budget != null &&
      _budget! > 0 &&
      _genderPolicy != null &&
      _groupSize != null &&
      _groupSize! >= 1;

  @override
  void initState() {
    super.initState();
    // Entering Step 1 always starts a fresh draft.
    context.read<TenantOnboardingCubit>().reset();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _groupSizeController.dispose();
    super.dispose();
  }

  void _continue() {
    context.read<TenantOnboardingCubit>().saveHardConstraints(
      maxBudget: _budget!,
      requiredGender: _genderPolicy!,
      needsWifi: _wifiRequired,
      isSmoker: _isSmoker,
      hasPet: _hasPet,
      groupSize: _groupSize!,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SoftPreferencesStepScreen(),
      ),
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
                onBack: () => Navigator.of(context).pop(),
                stepNumber: 1,
                stepCount: 5,
              ),
            ),
            Expanded(
              child: FormStepLayout(
                title: 'What are your\nnon-negotiables?',
                subtitle: 'Set the hard limits for your boarding house search.',
                buttonLabel: 'Save and Continue',
                onContinue: _canProceed ? _continue : null,
                fields: [
                  LabeledTextField(
                    label: 'Max budget (PHP/month)',
                    hint: '4500',
                    prefixText: '₱ ',
                    keyboardType: TextInputType.number,
                    controller: _budgetController,
                    onChanged: (_) => setState(() {}),
                  ),
                  _LabeledControl(
                    label: 'Gender policy',
                    child: Container(
                      height: AppSizes.fieldHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: context.appColors.fieldFill,
                        borderRadius: BorderRadius.circular(AppRadii.field),
                        border: Border.all(
                          color: context.appColors.fieldBorder,
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: _genderPolicy,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        hint: Text(
                          'Select gender policy',
                          style: AppTextStyles.field(
                            context,
                          ).copyWith(color: context.appColors.hint),
                        ),
                        style: AppTextStyles.field(
                          context,
                        ).copyWith(color: context.appColors.textPrimary),
                        items: [
                          DropdownMenuItem(
                            value: 'Female only',
                            child: Text('Female only'),
                          ),
                          DropdownMenuItem(
                            value: 'Male only',
                            child: Text('Male only'),
                          ),
                          DropdownMenuItem(
                            value: 'Mixed / Any',
                            child: Text('Mixed / Any'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _genderPolicy = v),
                      ),
                    ),
                  ),
                  _ToggleRow(
                    label: 'WiFi required',
                    value: _wifiRequired,
                    onChanged: (v) => setState(() => _wifiRequired = v),
                  ),
                  Text('About you', style: AppTextStyles.label(context)),
                  _ToggleRow(
                    label: 'I smoke',
                    value: _isSmoker,
                    onChanged: (v) => setState(() => _isSmoker = v),
                  ),
                  _ToggleRow(
                    label: 'I have a pet',
                    value: _hasPet,
                    onChanged: (v) => setState(() => _hasPet = v),
                  ),
                  LabeledTextField(
                    label: 'How many people will stay?',
                    hint: '1',
                    keyboardType: TextInputType.number,
                    controller: _groupSizeController,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledControl extends StatelessWidget {
  const _LabeledControl({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label(context)),
        SizedBox(height: AppSpacing.sm),
        child,
      ],
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
        Expanded(child: Text(label, style: AppTextStyles.label(context))),
        AppToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}
