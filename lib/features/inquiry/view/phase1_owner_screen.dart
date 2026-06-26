import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';

class Phase1OwnerScreen extends StatelessWidget {
  const Phase1OwnerScreen({super.key, required this.inquiry});

  final Map<String, dynamic> inquiry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('New inquiry'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amberFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Review',
              style: TextStyle(
                color: AppColors.amberText,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bot label
            Row(
              children: const [
                Icon(
                  Icons.smart_toy_outlined,
                  size: 12,
                  color: AppColors.tenantTextCyan,
                ),
                SizedBox(width: 4),
                Text(
                  'Tenant summary from RentEase',
                  style: TextStyle(
                    color: AppColors.tenantTextCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Tenant summary card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tenantFillBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inquiry['tenantName'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${inquiry['gender']} · ${inquiry['school']}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Move-in: ${inquiry['moveIn']} · Stay: ${inquiry['stay']}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const Text(
                    'Group size: 1 person',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Budget: ₱${inquiry['budget']}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${inquiry['isSmoker'] == true ? 'Smoker' : 'Non-smoker'} · ${inquiry['hasPet'] == true ? 'Has pet' : 'No pet'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (inquiry['passesAllRules'] == true) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.greenFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.greenPrimary),
                      ),
                      child: const Text(
                        'Passes all your rules',
                        style: TextStyle(
                          color: AppColors.greenText,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            AppButton(
              label: 'Accept inquiry',
              color: AppColors.ownerPrimary,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Decline',
              isDanger: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
