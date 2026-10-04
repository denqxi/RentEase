import '../../../core/constants/app_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../cubit/edit_preferences_cubit.dart';
import 'edit_constraints_screen.dart';

/// Tenant soft preferences — nice-to-haves that refine TOPSIS ranking but,
/// unlike the non-negotiables (hard constraints), never remove a property
/// from the matching pool.
class SoftPreferencesScreen extends StatelessWidget {
  const SoftPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      withEditPreferencesCubit(context, const _SoftPreferencesView());
}

class _SoftPreferencesView extends StatefulWidget {
  const _SoftPreferencesView();

  @override
  State<_SoftPreferencesView> createState() => _SoftPreferencesViewState();
}

class _SoftPreferencesViewState extends State<_SoftPreferencesView> {
  static const _roomTypes = ['Solo', 'Shared', 'Either'];

  String _roomType = 'Either';
  final Set<String> _preferredAmenities = <String>{};
  bool _initialized = false;

  void _initFrom(EditPreferencesState state) {
    final profile = state.profile;
    if (_initialized || profile == null) return;
    _initialized = true;
    final saved = profile.roomType;
    _roomType = saved != null && _roomTypes.contains(saved) ? saved : 'Either';
    _preferredAmenities
      ..clear()
      ..addAll(profile.preferredAmenities ?? const <String>[]);
  }

  void _save() {
    context.read<EditPreferencesCubit>().saveSoftPreferences(
      roomType: _roomType,
      preferredAmenities: _preferredAmenities.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditPreferencesCubit, EditPreferencesState>(
      listener: (context, state) {
        if (state.status == EditPreferencesStatus.saved) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Soft preferences saved.'),
              backgroundColor: context.appColors.ink,
            ),
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      },
      builder: (context, state) {
        _initFrom(state);
        if (state.status == EditPreferencesStatus.loading) {
          return const EditScaffold(
            title: 'Soft preferences',
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.profile == null) {
          return EditScaffold(
            title: 'Soft preferences',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  state.errorMessage ?? 'Could not load your preferences.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return _buildForm(context, state);
      },
    );
  }

  Widget _buildForm(BuildContext context, EditPreferencesState state) {
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
                for (final type in _roomTypes) ...[
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
                for (final amenity in AppOptions.amenities)
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

            AppButton(
              label: state.status == EditPreferencesStatus.saving
                  ? 'Saving...'
                  : 'Save preferences',
              onPressed: state.status == EditPreferencesStatus.saving ? null : _save,
            ),
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
