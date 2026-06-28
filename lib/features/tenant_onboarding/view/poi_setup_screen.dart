import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
<<<<<<< Updated upstream
import '../../../shared/widgets/app_button.dart';
import 'topsis_weight_screen.dart';

class PoiSetupScreen extends StatelessWidget {
  const PoiSetupScreen({this.onComplete, super.key});

  final VoidCallback? onComplete;
=======
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
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< Updated upstream
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left,
              color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Set location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Step progress bar — first 2 filled
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primaryMid,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primaryMid,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Step 2 of 3',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Where is your school or work?',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Drop the pin on your school or workplace. This sets your distance anchor for matching.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            // Search field
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.fieldBg,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search,
                      color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'USTP Davao Campus...',
                        hintStyle: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Map container
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.tenantFillBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Grid placeholder
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MapGridPainter(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.location_pin,
                          color: AppColors.primaryMid,
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Matina, Davao City',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.tenantTextDeep,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            AppPrimaryButton(
              label: 'Confirm Location',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TopsisWeightScreen(
                    onComplete: onComplete,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
=======
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
>>>>>>> Stashed changes
          ],
        ),
      ),
    );
  }
}

<<<<<<< Updated upstream
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryMid.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => false;
=======
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
>>>>>>> Stashed changes
}
