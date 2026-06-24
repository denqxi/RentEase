import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// Top bar for the registration flow: a circular back button plus an optional
/// progress indicator ("1/3" with a fill bar) for the form steps.
class RegistrationAppBar extends StatelessWidget {
  const RegistrationAppBar({
    required this.onBack,
    this.stepNumber,
    this.stepCount,
    super.key,
  });

  /// Tapped when the back button is pressed.
  final VoidCallback onBack;

  /// 1-based step number, or null to hide the progress bar.
  final int? stepNumber;

  /// Total number of steps; required when [stepNumber] is provided.
  final int? stepCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _BackButton(onTap: onBack),
        if (stepNumber != null && stepCount != null) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _ProgressBar(value: stepNumber! / stepCount!),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$stepNumber / $stepCount',
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        side: const BorderSide(color: AppColors.fieldBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.field),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.chevron_left, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  static const Duration _animDuration = Duration(milliseconds: 650);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animDuration);
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: oldWidget.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, Widget? child) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _animation.value,
          minHeight: 6,
          backgroundColor: AppColors.fieldFill,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
        ),
      ),
    );
  }
}
