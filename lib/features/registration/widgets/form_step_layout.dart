import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import 'step_header.dart';

/// Shared responsive chrome for all registration form steps:
/// a scrollable body of [fields] and a pinned primary action button.
///
/// Designed to be resilient to keyboard appearances, preventing RenderFlex
/// overflow errors while maintaining consistent visual hierarchy across all phone sizes.
class FormStepLayout extends StatelessWidget {
  const FormStepLayout({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onContinue,
    required this.fields,
    this.titleSpans,
    this.footer,
    super.key,
  });

  final String? title;
  final List<InlineSpan>? titleSpans;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onContinue;

  /// Form controls for this step; spaced automatically.
  final List<Widget> fields;

  /// Optional content pinned above the primary button, outside the
  /// scrollable field area (e.g. Terms & conditions checkbox).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 360;
    final horizontalPadding = isCompact ? AppSpacing.md : AppSpacing.lg;
    final verticalPadding = isCompact ? AppSpacing.md : AppSpacing.lg;

    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          verticalPadding,
          horizontalPadding,
          verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StepHeader(
              title: title,
              titleSpans: titleSpans,
              subtitle: subtitle,
            ),
            SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.lg),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final Widget field in fields) ...<Widget>[
                        field,
                        SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.md),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (footer != null) ...<Widget>[
              footer!,
              SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.md),
            ] else
              SizedBox(height: AppSpacing.xs),
            AppPrimaryButton(label: buttonLabel, onPressed: onContinue),
          ],
        ),
      ),
    );
  }
}
