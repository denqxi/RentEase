import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../cubit/tenant_onboarding_cubit.dart';
import 'soft_preferences_step_screen.dart';

/// Screen 1 of 5 in Tenant Onboarding: "What are your must-haves?"
class HardConstraintsScreen extends StatefulWidget {
  const HardConstraintsScreen({super.key});

  @override
  State<HardConstraintsScreen> createState() => _HardConstraintsScreenState();
}

class _HardConstraintsScreenState extends State<HardConstraintsScreen> {
  final _budgetController = TextEditingController(text: '4500');
  String? _genderPolicy = 'Female only';
  bool _wifiRequired = true;
  // About you — owners filter on these (Layer 1: smoking, pets, occupancy).
  bool _isSmoker = false;
  bool _hasPet = false;
  final _groupSizeController = TextEditingController(text: '1');

  int? get _groupSize => int.tryParse(_groupSizeController.text.trim());

  num? get _budget => num.tryParse(_budgetController.text.trim());

  // Form validation: budget must be at least 1000, gender policy must be set, group size >= 1
  bool get _canProceed =>
      _budget != null &&
      _budget! >= 1000 &&
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
    final currentGroupSize = _groupSize ?? 1;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Back button, Progress bar, Step text
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.appColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.appColors.fieldBorder,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: context.appColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 1 / 5,
                        minHeight: 5,
                        backgroundColor: context.appColors.indicatorInactive
                            .withValues(alpha: 0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '1 / 5',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Headers
              Text(
                'What are your must-haves?',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.appColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "We'll only show places that meet your needs.",
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Scrollable Cards
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card 1: ABOUT THE PLACE
                      _SectionCard(
                        title: 'ABOUT THE PLACE',
                        children: [
                          // 1. Maximum monthly budget (single-layer input with peso sign and digits-only filter)
                          _FieldLabel(label: 'Maximum monthly budget'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: context.appColors.fieldFill,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              prefixIcon: Padding(
                                padding:
                                    const EdgeInsets.only(left: 14, right: 6),
                                child: Text(
                                  '₱',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    color: context.appColors.textPrimary,
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 0,
                                minHeight: 0,
                              ),
                              hintText: 'Enter max budget (e.g., 5000)',
                              hintStyle: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                color: context.appColors.hint,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.field),
                                borderSide: BorderSide(
                                  color: context.appColors.fieldBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.field),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 2. Gender Policy
                          _FieldLabel(label: 'Gender Policy'),
                          const SizedBox(height: 6),
                          Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: context.appColors.fieldFill,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.field),
                              border: Border.all(
                                color: context.appColors.fieldBorder,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _genderPolicy,
                                isExpanded: true,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: context.appColors.textSecondary,
                                  size: 22,
                                ),
                                hint: Text(
                                  'Select gender policy',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    color: context.appColors.hint,
                                  ),
                                ),
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: context.appColors.textPrimary,
                                ),
                                items: const [
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
                                onChanged: (v) =>
                                    setState(() => _genderPolicy = v),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. WiFi required
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: context.appColors.fieldFill,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.field),
                              border: Border.all(
                                color: context.appColors.fieldBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'WiFi required',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: context.appColors.textPrimary,
                                    ),
                                  ),
                                ),
                                _TextToggle(
                                  value: _wifiRequired,
                                  onChanged: (v) =>
                                      setState(() => _wifiRequired = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Card 2: ABOUT YOU
                      _SectionCard(
                        title: 'ABOUT YOU',
                        children: [
                          // Occupancy Stepper
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'How many people will stay?',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: context.appColors.textPrimary,
                                  ),
                                ),
                              ),
                              _StepperControl(
                                value: currentGroupSize,
                                onChanged: (newVal) {
                                  setState(() {
                                    _groupSizeController.text =
                                        newVal.toString();
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Smoking & Pets Sub-card
                          Container(
                            decoration: BoxDecoration(
                              color: context.appColors.fieldFill,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.field),
                              border: Border.all(
                                color: context.appColors.fieldBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'I smoke',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                context.appColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      _TextToggle(
                                        value: _isSmoker,
                                        onChanged: (v) =>
                                            setState(() => _isSmoker = v),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: context.appColors.fieldBorder
                                      .withValues(alpha: 0.8),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'I have a pet',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                context.appColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      _TextToggle(
                                        value: _hasPet,
                                        onChanged: (v) =>
                                            setState(() => _hasPet = v),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canProceed ? _continue : null,
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.disabled)) {
                        return const Color(0xFFD9D9E0);
                      }
                      return context.appColors.ink;
                    }),
                    foregroundColor:
                        WidgetStateProperty.resolveWith<Color>((states) {
                      return Colors.white;
                    }),
                    elevation: WidgetStateProperty.all(0),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Save and Continue',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section Card with light-gray banner header perfectly aligned to card outline
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appColors.fieldBorder,
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                border: Border(
                  bottom: BorderSide(
                    color: context.appColors.fieldBorder,
                    width: 1.0,
                  ),
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: context.appColors.textPrimary,
      ),
    );
  }
}

/// Stepper control [ -  1  + ]
class _StepperControl extends StatelessWidget {
  const _StepperControl({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appColors.fieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: Icon(
              Icons.remove,
              size: 16,
              color: value > 1
                  ? context.appColors.textPrimary
                  : context.appColors.hint,
            ),
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$value',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: Icon(
              Icons.add,
              size: 16,
              color: context.appColors.textPrimary,
            ),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

/// Custom toggle with ON (teal) / OFF (gray) text
class _TextToggle extends StatelessWidget {
  const _TextToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 58,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? AppColors.primary : const Color(0xFF9CA3AF),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(
                  left: value ? 8 : 0,
                  right: value ? 0 : 6,
                ),
                child: Text(
                  value ? 'ON' : 'OFF',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
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
