import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/verified_badge.dart';
import '../../../shared/widgets/topsis_weight_bar.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.ownerFill,
                    child: Text(
                      'MR',
                      style: TextStyle(
                        color: AppColors.ownerText,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    MockData.ownerName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const VerifiedBadge(state: VerifiedState.verified),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: AppColors.fieldBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.primaryMid, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Documents submitted',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.primaryMid, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Admin approved',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verified since Mar 12, 2025',
                      style: TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: AppColors.border),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'MY TENANT RANKING',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(foregroundColor: AppColors.ownerPrimary),
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TopsisWeightBar(label: 'Budget fit', weight: 0.50, color: AppColors.ownerPrimary),
            TopsisWeightBar(label: 'Stay duration', weight: 0.30, color: AppColors.ownerDark),
            TopsisWeightBar(label: 'Tenant rating', weight: 0.20, color: AppColors.ownerPrimary),
            const SizedBox(height: 16),
            Divider(color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              'MY RATINGS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(
                  5,
                  (_) => Icon(Icons.star, color: AppColors.amberPrimary, size: 20),
                ),
                const SizedBox(width: 4),
                Text(
                  '4.8',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Review 1
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.fieldBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maria Andres',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (_) => Icon(Icons.star, color: AppColors.amberPrimary, size: 14),
                    ),
                  ),
                  Text(
                    'Great landlord! Very responsive.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Review 2
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.fieldBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jana Ramos',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    children: [
                      ...List.generate(
                        4,
                        (_) => Icon(Icons.star, color: AppColors.amberPrimary, size: 14),
                      ),
                      Icon(Icons.star_outline, color: AppColors.amberPrimary, size: 14),
                    ],
                  ),
                  Text(
                    'Good place, highly recommended.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              'ACCOUNT SETTINGS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            ...[
              'Change password',
              'Notification preferences',
              'Help and support',
              'Terms and privacy',
            ].map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item, style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: AppColors.redPrimary),
                child: const Text('Log out'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
