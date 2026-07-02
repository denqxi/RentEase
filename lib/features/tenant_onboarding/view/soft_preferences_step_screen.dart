import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../features/registration/widgets/form_step_layout.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import 'poi_setup_screen.dart';

/// Onboarding Step 2 — soft preferences (nice-to-haves).
/// Unlike Step 1's non-negotiables these never remove a property from the
/// matching pool; they only refine how eligible properties are ranked.
/// Editable later via Profile → Soft preferences.
class SoftPreferencesStepScreen extends StatefulWidget {
  const SoftPreferencesStepScreen({super.key});

  @override
  State<SoftPreferencesStepScreen> createState() =>
      _SoftPreferencesStepScreenState();
}

class _SoftPreferencesStepScreenState extends State<SoftPreferencesStepScreen> {
  String _roomType = 'Either';
  final Set<String> _preferredAmenities = <String>{};

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
                stepNumber: 2,
                stepCount: 5,
              ),
            ),
            Expanded(
              child: FormStepLayout(
                title: 'Any nice-to-haves?',
                subtitle:
                    'These fine-tune your ranking — a place missing them can '
                    'still appear, just ranked lower. You can skip this step.',
                buttonLabel: 'Continue',
                onContinue: _continue,
                fields: [
                  Text(
                    'Room type',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      for (final type in const ['Solo', 'Shared', 'Either']) ...[
                        Expanded(
                          child: _PrefChip(
                            label: type,
                            isSelected: _roomType == type,
                            onTap: () => setState(() => _roomType = type),
                          ),
                        ),
                        if (type != 'Either') SizedBox(width: 8),
                      ],
                    ],
                  ),
                  Text(
                    'Preferred amenities (${_preferredAmenities.length} selected)',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final amenity in MockData.amenities)
                        _PrefChip(
                          label: amenity,
                          isSelected: _preferredAmenities.contains(amenity),
                          onTap: () => setState(() {
                            if (!_preferredAmenities.remove(amenity)) {
                              _preferredAmenities.add(amenity);
                            }
                          }),
                        ),
                    ],
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

class _PrefChip extends StatelessWidget {
  const _PrefChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : context.appColors.fieldFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? AppColors.accent : context.appColors.fieldBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color:
                isSelected ? AppColors.onInk : context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
