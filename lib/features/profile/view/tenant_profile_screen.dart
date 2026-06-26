import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/topsis_weight_bar.dart';
import 'edit_constraints_screen.dart';
import 'edit_topsis_screen.dart';

class TenantProfileScreen extends StatelessWidget {
  const TenantProfileScreen({super.key});

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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Avatar & name
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.tenantFillBlue,
                    child: Text(
                      'MS',
                      style: TextStyle(
                        color: AppColors.tenantTextDeep,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    MockData.tenantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    MockData.tenantSchool,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.md),

            // Preferences section
            Row(
              children: [
                const Text(
                  'MY PREFERENCES',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditConstraintsScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryMid,
                  ),
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            const _PrefRow(label: 'Max budget', value: '₱4,500'),
            const _PrefRow(label: 'Gender policy', value: 'Female only'),
            const _PrefRow(label: 'WiFi', value: 'Required'),
            const _PrefRow(label: 'Bathroom', value: 'Shared'),
            const _PrefRow(label: 'Max distance', value: '3.0 km'),
            const _PrefRow(label: 'Curfew', value: '10:00 PM'),

            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.md),

            // Priorities section
            Row(
              children: [
                const Text(
                  'MY PRIORITIES',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditTopsisScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryMid,
                  ),
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            TopsisWeightBar(
              label: 'Monthly rent',
              weight: 0.50,
              color: AppColors.primaryMid,
            ),
            TopsisWeightBar(
              label: 'Distance',
              weight: 0.30,
              color: AppColors.primaryCyan,
            ),
            TopsisWeightBar(
              label: 'Amenities',
              weight: 0.20,
              color: AppColors.primaryTeal,
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.md),

            // Booking history
            const Text(
              'BOOKING HISTORY',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
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
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: const Text(
                'Booked · Aug 1, 2025',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.md),

            // Account settings
            const Text(
              'ACCOUNT SETTINGS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            _SettingsTile(label: 'Change password', onTap: () {}),
            _SettingsTile(label: 'Notification preferences', onTap: () {}),
            _SettingsTile(label: 'Help and support', onTap: () {}),
            _SettingsTile(label: 'Terms and privacy', onTap: () {}),

            const SizedBox(height: AppSpacing.md),

            Center(
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.redPrimary,
                ),
                child: const Text('Log out'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
