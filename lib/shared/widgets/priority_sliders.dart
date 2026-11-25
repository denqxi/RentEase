import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../features/matching/domain/entities/priority_weights.dart';

/// The rule and the three priority sliders, shared by onboarding and Profile.
/// Moving one slider rebalances the other two so the total stays at 100%.
class PrioritySliders extends StatefulWidget {
  const PrioritySliders({
    required this.weights,
    required this.onChanged,
    super.key,
  });

  final PriorityWeights weights;
  final ValueChanged<PriorityWeights> onChanged;

  @override
  State<PrioritySliders> createState() => _PrioritySlidersState();
}

class _PrioritySlidersState extends State<PrioritySliders> {
  /// Weights when the current drag began; see [PriorityWeights.rebalance].
  PriorityWeights? _dragStart;

  static const _copy = {
    Priority.rent: ('Lower Monthly Rent', 'Show cheaper rates first'),
    Priority.distance: (
      'Shorter Daily Commute',
      'Show rooms closer to your school or work first',
    ),
    Priority.amenities: (
      'More Amenities & Inclusions',
      'Show rooms with Wi-Fi, AC, and bath first',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _rule(context),
        for (final p in Priority.values) ...[
          const SizedBox(height: 12),
          _card(context, p),
        ],
      ],
    );
  }

  Widget _rule(BuildContext context) {
    final total = widget.weights.total;
    final balanced = total == 100;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: balanced ? AppColors.accentSoft : AppColors.amberFill50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                balanced
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: balanced ? AppColors.primaryCyan : AppColors.amber800,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: $total%',
                    // The box keeps its light tint in dark mode, so the text
                    // stays on the matching dark tokens.
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: balanced ? AppColors.ink : AppColors.amber800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'The three always add up to 100%. Move one and the other '
                    'two adjust to fit.',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                      height: 1.35,
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

  Widget _card(BuildContext context, Priority p) {
    final colors = context.appColors;
    final (label, subtext) = _copy[p]!;
    final value = widget.weights[p];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Read out by the slider below, so hidden from screen readers here.
          ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtext,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$value%',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryCyan,
              inactiveTrackColor: colors.fieldBorder,
              thumbColor: AppColors.primaryCyan,
              overlayColor: AppColors.primaryCyan.withValues(alpha: 0.15),
              tickMarkShape: SliderTickMarkShape.noTickMark,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: MergeSemantics(
              child: Semantics(
                label: '$label priority. $subtext.',
                child: Slider(
                  value: value.toDouble().clamp(0, 100),
                  max: 100,
                  divisions: 100 ~/ PriorityWeights.step,
                  semanticFormatterCallback: (v) => '${v.round()} percent',
                  onChangeStart: (_) => _dragStart = widget.weights,
                  onChanged: (v) => widget.onChanged(
                    (_dragStart ?? widget.weights).rebalance(p, v),
                  ),
                  onChangeEnd: (_) => _dragStart = null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
