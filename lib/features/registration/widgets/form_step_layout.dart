import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import 'step_header.dart';

/// Shared chrome for the three progress-tracked form steps: a scrollable body
/// of [fields] and a pinned primary action button.
///
/// The app bar (back button + progress bar) is rendered by the parent
/// [RegistrationFlowScreen] so it persists across step transitions.
class FormStepLayout extends StatelessWidget {
  const FormStepLayout({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onContinue,
    required this.fields,
    this.footer,
    super.key,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onContinue;

  /// Form controls for this step; spaced automatically.
  final List<Widget> fields;

  /// Optional content pinned above the primary button, outside the
  /// scrollable field area — for gating content like a terms checkbox that
  /// should stay attached to the action it gates rather than scroll away.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StepHeader(title: title, subtitle: subtitle),
          SizedBox(height: AppSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final Widget field in fields) ...<Widget>[
                    field,
                    SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
          if (footer != null) ...<Widget>[
            footer!,
            SizedBox(height: AppSpacing.md),
          ] else
            SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(label: buttonLabel, onPressed: onContinue),
        ],
      ),
    );
  }
}
