import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class SessionFilterSheet extends StatefulWidget {
  const SessionFilterSheet({
    required this.initialBudget,
    required this.initialDistance,
    required this.onApply,
    super.key,
  });

  final double initialBudget;
  final double initialDistance;
  final void Function(double budget, double distance) onApply;

  @override
  State<SessionFilterSheet> createState() => _SessionFilterSheetState();
}

class _SessionFilterSheetState extends State<SessionFilterSheet> {
  late double _budget;
  late double _distance;

  @override
  void initState() {
    super.initState();
    _budget = widget.initialBudget;
    _distance = widget.initialDistance;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.appColors.fieldBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Session filters',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time_rounded, color: AppColors.matchMedium, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Temporary â€” not saved',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: AppColors.matchMedium,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(
                      'Max budget',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₱${_budget.round()}/mo',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Saved: ₱${MockData.tenantMaxBudget.round()}/mo',
                  style: AppTextStyles.caption(context),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: context.appColors.indicatorInactive,
                    thumbColor: AppColors.accent,
                  ),
                  child: Slider(
                    value: _budget,
                    min: 1000,
                    max: 10000,
                    divisions: 90,
                    onChanged: (v) => setState(() => _budget = v),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text(
                      'Max distance',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_distance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Saved: ${MockData.tenantMaxDistance.toStringAsFixed(1)} km',
                  style: AppTextStyles.caption(context),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: context.appColors.indicatorInactive,
                    thumbColor: AppColors.accent,
                  ),
                  child: Slider(
                    value: _distance,
                    min: 0.5,
                    max: 15,
                    divisions: 29,
                    onChanged: (v) => setState(() => _distance = v),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _budget = MockData.tenantMaxBudget;
                      _distance = MockData.tenantMaxDistance;
                    }),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                AppButton(
                  label: 'Apply',
                  onPressed: () {
                    widget.onApply(_budget, _distance);
                    Navigator.of(context).pop();
                  },
                ),
                SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
