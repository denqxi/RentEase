import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/weight_utils.dart';
import '../cubit/edit_preferences_cubit.dart';
import 'edit_constraints_screen.dart';

/// Edits the tenant's three TOPSIS weights (CLAUDE.md: they must always sum
/// to 1.0). Pops `true` once saved and re-ranked.
class EditTopsisScreen extends StatelessWidget {
  const EditTopsisScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      withEditPreferencesCubit(context, const _EditTopsisView());
}

class _EditTopsisView extends StatefulWidget {
  const _EditTopsisView();

  @override
  State<_EditTopsisView> createState() => _EditTopsisViewState();
}

class _EditTopsisViewState extends State<_EditTopsisView> {
  double _rent = 0.35;
  double _distance = 0.35;
  double _amenities = 0.30;
  bool _initialized = false;

  double _round(double v) => (v * 20).round() / 20;

  void _initFrom(EditPreferencesState state) {
    final profile = state.profile;
    if (_initialized || profile == null) return;
    _initialized = true;
    _rent = profile.wRent.toDouble();
    _distance = profile.wDistance.toDouble();
    _amenities = profile.wAmenities.toDouble();
  }

  bool get _sumsToOne => (_rent + _distance + _amenities - 1).abs() < 1e-6;

  void _setWeight({
    required double newValue,
    required double otherA,
    required double otherB,
    required ValueChanged<double> setChanged,
    required ValueChanged<double> setOtherA,
    required ValueChanged<double> setOtherB,
  }) {
    final result = normalizeWeights(
      newValue: newValue,
      otherA: otherA,
      otherB: otherB,
      round: _round,
    );
    setState(() {
      setChanged(result.changed);
      setOtherA(result.otherA);
      setOtherB(result.otherB);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditPreferencesCubit, EditPreferencesState>(
      listener: (context, state) {
        if (state.status == EditPreferencesStatus.saved) {
          Navigator.of(context).pop(true);
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
            title: 'Ranking priorities',
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.profile == null) {
          return EditScaffold(
            title: 'Ranking priorities',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  state.errorMessage ?? 'Could not load your priorities.',
                  style: AppTextStyles.body(context),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final total = ((_rent + _distance + _amenities) * 100).round();
        return EditScaffold(
          title: 'Ranking priorities',
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'How much each factor counts when ranking your '
                        'compatible properties. Drag one — the others adjust '
                        'to keep the total at 100%.',
                        style: AppTextStyles.body(context),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      _SliderSection(
                        label: 'Monthly rent',
                        value: _rent,
                        onChanged: (v) => _setWeight(
                          newValue: v,
                          otherA: _distance,
                          otherB: _amenities,
                          setChanged: (nv) => _rent = nv,
                          setOtherA: (nv) => _distance = nv,
                          setOtherB: (nv) => _amenities = nv,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      _SliderSection(
                        label: 'Distance from your POI',
                        value: _distance,
                        onChanged: (v) => _setWeight(
                          newValue: v,
                          otherA: _rent,
                          otherB: _amenities,
                          setChanged: (nv) => _distance = nv,
                          setOtherA: (nv) => _rent = nv,
                          setOtherB: (nv) => _amenities = nv,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      _SliderSection(
                        label: 'Amenities',
                        value: _amenities,
                        onChanged: (v) => _setWeight(
                          newValue: v,
                          otherA: _rent,
                          otherB: _distance,
                          setChanged: (nv) => _amenities = nv,
                          setOtherA: (nv) => _rent = nv,
                          setOtherB: (nv) => _distance = nv,
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Text(
                            'Total: ',
                            style: AppTextStyles.label(
                              context,
                            ).copyWith(color: context.appColors.textPrimary),
                          ),
                          Text(
                            '$total%',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _sumsToOne
                                  ? AppColors.matchHigh
                                  : AppColors.destructive,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (_sumsToOne)
                            const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: AppColors.matchHigh,
                            ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              SaveBar(
                saving: state.status == EditPreferencesStatus.saving,
                enabled: _sumsToOne,
                note: 'Saving will re-rank your compatible properties.',
                onSave: () => context.read<EditPreferencesCubit>().saveWeights(
                  wRent: _rent,
                  wDistance: _distance,
                  wAmenities: _amenities,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SliderSection extends StatelessWidget {
  const _SliderSection({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.label(
                context,
              ).copyWith(color: context.appColors.textPrimary),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0.0, 1.0),
          min: 0,
          max: 1,
          divisions: 20,
          activeColor: AppColors.accent,
          inactiveColor: context.appColors.indicatorInactive,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
