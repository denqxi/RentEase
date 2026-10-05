import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import 'privacy_notice_content.dart';

/// Scrollable Privacy Notice (text lives in [PrivacyNoticeContent]).
class PrivacyNoticeScreen extends StatelessWidget {
  const PrivacyNoticeScreen({super.key});

  /// Pushes the notice from anywhere (sign-up links, Terms and Profile).
  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PrivacyNoticeScreen()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.appColors.textPrimary),
        title: Text(
          PrivacyNoticeContent.title,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Text(
                          PrivacyNoticeContent.intro,
                          style: AppTextStyles.body(context),
                        ),
                      ),
                      for (final s in PrivacyNoticeContent.sections)
                        _Section(title: s.title, body: s.body),
                      const _Section(
                        title: PrivacyNoticeContent.contactHeading,
                        body: PrivacyNoticeContent.contactBody,
                      ),
                      SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(body, style: AppTextStyles.body(context)),
        ],
      ),
    );
  }
}
