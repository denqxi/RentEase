import 'package:flutter/material.dart';

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
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 16),
    this.fieldSpacing = 12.0,
    this.headerSpacing = 16.0,
    this.buttonHeight = 52.0,
    this.buttonRadius = 12.0,
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

  /// Outer form padding around header, fields, and bottom button.
  final EdgeInsetsGeometry padding;

  /// Vertical spacing between each consecutive field.
  final double fieldSpacing;

  /// Vertical spacing below the header block.
  final double headerSpacing;

  /// Primary button height.
  final double buttonHeight;

  /// Primary button corner radius.
  final double buttonRadius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StepHeader(title: title, subtitle: subtitle),
          SizedBox(height: headerSpacing),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int i = 0; i < fields.length; i++) ...<Widget>[
                    fields[i],
                    if (i < fields.length - 1)
                      SizedBox(height: fieldSpacing),
                  ],
                ],
              ),
            ),
          ),
          if (footer != null) ...<Widget>[
            const SizedBox(height: 12),
            footer!,
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 12),
          AppPrimaryButton(
            label: buttonLabel,
            onPressed: onContinue,
            height: buttonHeight,
            borderRadius: buttonRadius,
          ),
        ],
      ),
    );
  }
}
