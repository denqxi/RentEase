import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/presentation/screens/privacy_notice_screen.dart';
import '../../auth/presentation/screens/terms_and_conditions_screen.dart';

/// Checkbox row requiring the user to confirm they are at least 18 years old
/// and agree to both the Terms and Agreement and Privacy Notice.
class TermsAgreementField extends StatelessWidget {
  const TermsAgreementField({
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
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
                      fontSize: 13,
                    ),
                    children: [
                      const TextSpan(
                        text: 'I am at least 18 years old and agree to the ',
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const TermsAndConditionsScreen(),
                            ),
                          ),
                          child: const Text(
                            'Terms and Agreement',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' and '),
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
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs, left: 28),
            child: Text(
              errorText!,
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.destructive,
              ),
            ),
          ),
      ],
    );
  }
}
