import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// Title + supporting subtitle shown at the top of each registration step.
class StepHeader extends StatelessWidget {
  const StepHeader({
    this.title,
    this.titleSpans,
    required this.subtitle,
    super.key,
  }) : assert(title != null || titleSpans != null);

  final String? title;
  final List<InlineSpan>? titleSpans;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (titleSpans != null)
          Text.rich(
            TextSpan(
              style: AppTextStyles.title(context),
              children: titleSpans,
            ),
          )
        else
          Text(title!, style: AppTextStyles.title(context)),
        const SizedBox(height: AppSpacing.sm),
        Text(subtitle, style: AppTextStyles.body(context)),
      ],
    );
  }
}
