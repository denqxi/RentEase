import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/form_step_layout.dart';
import '../../../features/registration/widgets/labeled_text_field.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../shared/widgets/app_toggle.dart';
import 'poi_setup_screen.dart';

class HardConstraintsScreen extends StatefulWidget {
  const HardConstraintsScreen({super.key});

  @override
  State<HardConstraintsScreen> createState() => _HardConstraintsScreenState();
}

class _HardConstraintsScreenState extends State<HardConstraintsScreen> {
  final _budgetController = TextEditingController(text: '4500');
  String? _genderPolicy;
  bool _wifiRequired = true;
  bool _privateBathroom = false;
  String _curfew = '10:00 PM';

  bool get _canProceed =>
      _budgetController.text.trim().isNotEmpty && _genderPolicy != null;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickCurfew() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() => _curfew = picked.format(context));
    }
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PoiSetupScreen()),
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
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
              ),
              child: RegistrationAppBar(
                onBack: () => Navigator.of(context).pop(),
                stepNumber: 1,
                stepCount: 4,
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
                    onChanged: (_) => setState(() {}),
                  ),
                  _LabeledControl(
                    label: 'Gender policy',
                    child: Container(
                      height: AppSizes.fieldHeight,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.appColors.fieldFill,
                        borderRadius: BorderRadius.circular(AppRadii.field),
                        border: Border.all(color: context.appColors.fieldBorder),
                      ),
                      child: DropdownButton<String>(
                        value: _genderPolicy,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        hint: Text(
                          'Select gender policy',
                          style: AppTextStyles.field(context).copyWith(color: context.appColors.hint),
                        ),
                        style: AppTextStyles.field(context).copyWith(
                          color: context.appColors.textPrimary,
                        ),
                        items: [
                          DropdownMenuItem(value: 'Female only', child: Text('Female only')),
                          DropdownMenuItem(value: 'Male only', child: Text('Male only')),
                          DropdownMenuItem(value: 'Mixed / Any', child: Text('Mixed / Any')),
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
                  _ToggleRow(
                    label: 'Private bathroom',
                    value: _privateBathroom,
                    onChanged: (v) => setState(() => _privateBathroom = v),
                  ),
                  _LabeledControl(
                    label: 'Curfew',
                    child: GestureDetector(
                      onTap: _pickCurfew,
                      child: Container(
                        height: AppSizes.fieldHeight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: context.appColors.fieldFill,
                          borderRadius: BorderRadius.circular(AppRadii.field),
                          border: Border.all(color: context.appColors.fieldBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_curfew, style: AppTextStyles.field(context)),
                            Icon(Icons.access_time_rounded,
                                color: context.appColors.hint, size: 20),
                          ],
                        ),
                      ),
                    ),
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

