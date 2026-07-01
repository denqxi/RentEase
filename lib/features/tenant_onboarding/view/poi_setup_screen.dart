import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/form_step_layout.dart';
import '../../../features/registration/widgets/labeled_text_field.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import 'distance_preference_screen.dart';

class PoiSetupScreen extends StatefulWidget {
  const PoiSetupScreen({super.key});

  @override
  State<PoiSetupScreen> createState() => _PoiSetupScreenState();
}

class _PoiSetupScreenState extends State<PoiSetupScreen> {
  String _poiType = 'School';
  final _searchController = TextEditingController();
  String? _resolvedAddress;
  bool _hasMarker = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _simulatePinDrop() {
    setState(() {
      _hasMarker = true;
      _resolvedAddress =
          'University of Southeastern Philippines, Matina, Davao City';
    });
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DistancePreferenceScreen(
          poiName: _resolvedAddress ?? '$_poiType location',
        ),
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
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
              ),
              child: RegistrationAppBar(
                onBack: () => Navigator.of(context).pop(),
                stepNumber: 2,
                stepCount: 4,
              ),
            ),
            Expanded(
              child: FormStepLayout(
                title: 'Where is your school\nor work?',
                subtitle: 'Tap the map to set your Point of Interest (POI).',
                buttonLabel: 'Confirm Location',
                onContinue: _hasMarker ? _continue : null,
                fields: [
                  _PoiTypeSelector(
                    selected: _poiType,
                    onSelected: (v) => setState(() => _poiType = v),
                  ),
                  LabeledTextField(
                    label: 'Search location',
                    hint: 'Search for your school or workplace...',
                    onChanged: (_) {},
                  ),
                  _MapPlaceholder(
                    hasMarker: _hasMarker,
                    onTap: _simulatePinDrop,
                    onLocate: _simulatePinDrop,
                  ),
                  if (_resolvedAddress != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadii.field),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              color: AppColors.accent, size: 16),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _resolvedAddress!,
                              style: AppTextStyles.caption(context)
                                  .copyWith(color: context.appColors.textPrimary),
                            ),
                          ),
                        ],
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

class _PoiTypeSelector extends StatelessWidget {
  const _PoiTypeSelector({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['School', 'Workplace', 'Other'].map((type) {
        final isSelected = selected == type;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => onSelected(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : context.appColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? AppColors.accent : context.appColors.fieldBorder,
                ),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppColors.onInk
                      : context.appColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({
    required this.hasMarker,
    required this.onTap,
    required this.onLocate,
  });

  final bool hasMarker;
  final VoidCallback onTap;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadii.field),
          border: Border.all(color: context.appColors.fieldBorder),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_rounded, color: AppColors.accent, size: 48),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tap to set your location',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (hasMarker)
              Center(
                child: Icon(Icons.location_pin,
                    color: AppColors.accent, size: 40),
              ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Container(
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  border: Border.all(color: context.appColors.fieldBorder),
                ),
                child: IconButton(
                  icon: Icon(Icons.my_location_rounded,
                      color: AppColors.accent, size: 20),
                  onPressed: onLocate,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
