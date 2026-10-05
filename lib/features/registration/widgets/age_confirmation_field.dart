import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/presentation/screens/privacy_notice_screen.dart';

/// Required checkbox: "I confirm that I am at least 18 years old and have
/// read the Privacy Notice". Shows [errorText] under the row when set.
class AgeConfirmationField extends StatelessWidget {
  const AgeConfirmationField({
    required this.value,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.accent,
                side: BorderSide(color: context.appColors.fieldBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(!value),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.label(context).copyWith(
                      color: context.appColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      const TextSpan(text: AppStrings.ageConfirmationLabelPrefix),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => PrivacyNoticeScreen.open(context),
                          child: const Text(
                            'Privacy Notice',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              errorText!,
              style: AppTextStyles.caption(context)
                  .copyWith(color: AppColors.destructive),
            ),
          ),
      ],
    );
  }
}
