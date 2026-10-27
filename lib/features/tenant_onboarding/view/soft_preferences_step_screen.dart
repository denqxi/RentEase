import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../owner_onboarding/widgets/listing_form_widgets.dart';
import '../cubit/tenant_onboarding_cubit.dart';
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

  @override
  void initState() {
    super.initState();
    final cubitState = context.read<TenantOnboardingCubit>().state;
    if (cubitState.roomType.isNotEmpty) {
      _roomType = cubitState.roomType;
    }
    _preferredAmenities.addAll(cubitState.preferredAmenities);
  }

  void _continue() {
    context.read<TenantOnboardingCubit>().saveSoftPreferences(
      roomType: _roomType,
      preferredAmenities: _preferredAmenities.toList(),
    );
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PoiSetupScreen()));
  }

  @override
  Widget build(BuildContext context) {
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
                        value: 2 / 4,
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
                    '2 / 4',
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

              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Headers
                      Text(
                        'Any nice-to-haves?',
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
                        "Pick extra features you'd like. We'll show places with these first.",
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: context.appColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Room type Section
                      Text(
                        'Room type',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final type
                              in const ['Solo', 'Shared', 'Either']) ...[
                            Expanded(
                              child: _RoomTypePill(
                                label: type,
                                isSelected: _roomType == type,
                                onTap: () => setState(() => _roomType = type),
                              ),
                            ),
                            if (type != 'Either') const SizedBox(width: 8),
                          ],
                        ],
                      ),

                      // Spacing between room type and preferred amenities section
                      const SizedBox(height: 24),

                      // Preferred amenities Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Preferred amenities',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${_preferredAmenities.length} selected',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Amenities categorized by kAmenityGroups (matching Owner create property layout)
                      for (final (group, items) in kAmenityGroups) ...[
                        const SizedBox(height: 6),
                        Text(
                          group,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final a in items)
                              AmenityChip(
                                label: a,
                                selected: _preferredAmenities.contains(a),
                                activeColor: AppColors.primary,
                                onTap: () => setState(() {
                                  if (!_preferredAmenities.remove(a)) {
                                    _preferredAmenities.add(a);
                                  }
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
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
                  onPressed: _continue,
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(context.appColors.ink),
                    foregroundColor: WidgetStateProperty.all(AppColors.onInk),
                    elevation: WidgetStateProperty.all(0),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Continue',
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

/// Pill button for the "Room type" selector (Solo, Shared, Either).
class _RoomTypePill extends StatelessWidget {
  const _RoomTypePill({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.appColors.fieldFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.slate300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.onInk : context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
