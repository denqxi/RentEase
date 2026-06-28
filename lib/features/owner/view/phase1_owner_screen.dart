import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import 'phase2_chat_owner_screen.dart';

class Phase1OwnerScreen extends StatelessWidget {
  const Phase1OwnerScreen({required this.inquiry, super.key});

  final Map<String, dynamic> inquiry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.appColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'New inquiry',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.matchMedium.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Review',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.matchMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.smart_toy_outlined, color: AppColors.accent, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Tenant summary from RentEase',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadii.field),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryRow('Name', inquiry['tenantName'] as String),
                          _SummaryRow('Gender', inquiry['gender'] as String),
                          _SummaryRow('School', inquiry['school'] as String),
                          _SummaryRow('Move-in date', inquiry['moveIn'] as String),
                          _SummaryRow('Length of stay', inquiry['stay'] as String),
                          _SummaryRow('Group size', '${inquiry['groupSize']} person(s)'),
                          _SummaryRow('Budget', '₱${inquiry['budget']}/mo'),
                          _SummaryRow('Smoker', inquiry['isSmoker'] == true ? 'Yes' : 'No'),
                          _SummaryRow('Has pet', inquiry['hasPet'] == true ? 'Yes' : 'No'),
                          _SummaryRow('Emergency contact', inquiry['emergencyContact'] as String),
                          if (inquiry['passesAllRules'] == true) ...[
                            SizedBox(height: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.matchHigh.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(AppRadii.chip),
                                border: Border.all(color: AppColors.matchHigh, width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AppColors.matchHigh, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Passes all your rules',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.matchHigh,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  AppButton(
                    label: 'Accept',
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => Phase2ChatOwnerScreen(inquiry: inquiry),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Decline',
                    variant: AppButtonVariant.destructiveOutline,
                    onPressed: () => _showDeclineDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeclineDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Decline inquiry',
          style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Provide a reason for declining (optional):',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14),
            ),
            SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                filled: true,
                fillColor: context.appColors.fieldFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.field)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: context.appColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Confirm',
              style: TextStyle(color: AppColors.destructive, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    reasonController.dispose();
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.caption(context).copyWith(color: context.appColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption(context).copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
