import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/phase_badge.dart';
import 'phase1_tenant_screen.dart';
import 'phase2_tenant_screen.dart';

class TenantInquiriesScreen extends StatelessWidget {
  const TenantInquiriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final property = MockData.properties[0];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'My inquiries',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Active section
          const Text(
            'ACTIVE',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          ...MockData.inquiries.map((inquiry) {
            final int phase = inquiry['phase'] as int;
            final bool isPhase1 = phase == 1;

            return GestureDetector(
              onTap: () {
                if (isPhase1) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          Phase1TenantScreen(property: property),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          Phase2TenantScreen(property: property),
                    ),
                  );
                }
              },
              child: Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.tenantFillBlue,
                    child: Text(
                      inquiry['propertyInitials'] as String,
                      style: const TextStyle(
                        color: AppColors.tenantTextDeep,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    inquiry['propertyName'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inquiry['ownerName'] as String,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPhase1
                            ? 'Waiting for owner response'
                            : 'Chat is open',
                        style: TextStyle(
                          color: isPhase1
                              ? AppColors.amberPrimary
                              : AppColors.primaryMid,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PhaseBadge(phase: phase),
                      const SizedBox(height: 4),
                      Text(
                        inquiry['date'] as String,
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: AppSpacing.md),

          // Resolved section
          const Text(
            'RESOLVED',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Resolved card 1
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.tenantFillBlue,
                child: Text(
                  'SB',
                  style: TextStyle(
                    color: AppColors.tenantTextDeep,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: const Text(
                'Sunshine Boarding House',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Maria Reyes',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Booking completed',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.fieldBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Booked',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),

          // Resolved card 2
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.tenantFillBlue,
                child: Text(
                  'BD',
                  style: TextStyle(
                    color: AppColors.tenantTextDeep,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: const Text(
                'BlueSky Dormitory',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Ana Santos',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Booking completed',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.fieldBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Booked',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
