import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/app_button.dart';

/// Tenant soft preferences — nice-to-haves that refine TOPSIS ranking but,
/// unlike the non-negotiables (hard constraints), never remove a property
/// from the matching pool.
class SoftPreferencesScreen extends StatefulWidget {
  const SoftPreferencesScreen({super.key});

  @override
  State<SoftPreferencesScreen> createState() => _SoftPreferencesScreenState();
}

class _SoftPreferencesScreenState extends State<SoftPreferencesScreen> {
  String _roomType = 'Either';
  final Set<String> _preferredAmenities = <String>{
    'WiFi',
    'Study area or desk',
    'Water included in rent',
  };

  void _save() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Soft preferences saved. Your rankings will refresh.',
        ),
        backgroundColor: context.appColors.ink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: context.appColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Soft preferences',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Explainer ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.accent, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Soft preferences fine-tune how properties are ranked '
                      'for you. Unlike your non-negotiables, they never hide '
                      'a property — a place missing these can still appear, '
                      'just ranked lower.',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12.5,
                        height: 1.4,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // ── Room type ────────────────────────────────────────────────
            Text(
              'Room type',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
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
            SizedBox(height: AppSpacing.lg),

            // ── Preferred amenities ──────────────────────────────────────
            Text(
              'Preferred amenities (${_preferredAmenities.length} selected)',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Properties offering more of these rank higher on your feed.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                color: context.appColors.hint,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
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
            SizedBox(height: AppSpacing.xl),

            AppButton(label: 'Save preferences', onPressed: _save),
            SizedBox(height: AppSpacing.lg),
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
