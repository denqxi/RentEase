import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';

/// Displays the RentEase terms of service and privacy policy for review
/// during signup.
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.appColors.textPrimary),
        title: Text(
          'Terms and agreement',
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
                      _Section(
                        title: 'Use of the platform',
                        body:
                            'RentEase matches tenants and boarding house owners in Davao City '
                            'using a bilateral compatibility filter and TOPSIS ranking. You '
                            'agree to provide accurate information in your profile and '
                            'constraints, since matching results and rankings depend on it.',
                      ),
                      _Section(
                        title: 'Account and role',
                        body:
                            'You choose a role (tenant or owner) at signup. Your role is '
                            'permanent and cannot be changed afterward. Owner accounts require '
                            'admin verification before property listings can be posted.',
                      ),
                      _Section(
                        title: 'Communication',
                        body:
                            'In-app messaging is only enabled between a tenant and owner once '
                            'both sides pass bilateral compatibility checks. Auto-shared '
                            'profile and property information is provided in good faith by '
                            'each party.',
                      ),
                      _Section(
                        title: 'Data and privacy',
                        body:
                            'Your profile details, location pin, and preferences are stored to '
                            'compute matches and are not sold to third parties. Location data '
                            'is used only for distance calculations and map display.',
                      ),
                      _Section(
                        title: 'Conduct',
                        body:
                            'You agree not to submit false verification documents, misuse the '
                            'inquiry system, or harass other users. Violations may result in '
                            'account suspension.',
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
