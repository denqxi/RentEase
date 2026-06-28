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
    super.key,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onContinue;

  /// Form controls for this step; spaced automatically.
  final List<Widget> fields;

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
          SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(label: buttonLabel, onPressed: onContinue),
        ],
      ),
    );
  }
}
