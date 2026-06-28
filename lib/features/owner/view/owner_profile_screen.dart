import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/topsis_weight_bar.dart';
import '../../../shared/widgets/verified_badge.dart';
import 'edit_owner_topsis_screen.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.md),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.accentSoft,
                    child: Text(
                      MockData.ownerInitials,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.ink,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    MockData.ownerName,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  const VerifiedBadge(),
                  SizedBox(height: 4),
                  Text('Member since Jan 2025', style: AppTextStyles.caption(context)),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Divider(color: context.appColors.fieldBorder, thickness: 0.5),
            SizedBox(height: AppSpacing.md),
            Text(
              'Verification',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
            ),
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.appColors.fieldFill,
                borderRadius: BorderRadius.circular(AppRadii.field),
                border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
              ),
              child: Column(
                children: [
                  _VerificationRow(label: 'Government ID', date: 'Verified Mar 12, 2025'),
                  SizedBox(height: AppSpacing.sm),
                  _VerificationRow(label: 'Property document', date: 'Verified Mar 12, 2025'),
                  SizedBox(height: AppSpacing.sm),
                  _VerificationRow(label: 'Business permit', date: 'Verified Mar 14, 2025'),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Divider(color: context.appColors.fieldBorder, thickness: 0.5),
            SizedBox(height: AppSpacing.md),
            _SectionHeader(
              label: 'My tenant ranking',
              onEdit: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const EditOwnerTopsisScreen()),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            const TopsisWeightBar(label: 'Stay duration', weight: 0.50),
            const TopsisWeightBar(label: 'Credibility score', weight: 0.30),
            const TopsisWeightBar(label: 'Profile completeness', weight: 0.20),
            SizedBox(height: AppSpacing.md),
            Divider(color: context.appColors.fieldBorder, thickness: 0.5),
            SizedBox(height: AppSpacing.md),
            Text(
              'My ratings',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                ...List.generate(5, (i) => Icon(Icons.star_rounded, color: AppColors.matchMedium, size: 24)),
                SizedBox(width: AppSpacing.sm),
                Text(
                  '4.8 average',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            ...[
              ('Maria Andres', '5 stars â€” Very clean and well-maintained!'),
              ('Jana Ramos', '5 stars â€” Owner is very responsive and helpful.'),
            ].map((r) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.appColors.fieldFill,
                borderRadius: BorderRadius.circular(AppRadii.field),
                border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.$1, style: AppTextStyles.label(context)),
                  Text(r.$2, style: AppTextStyles.caption(context)),
                ],
              ),
            )),
            SizedBox(height: AppSpacing.md),
            Divider(color: context.appColors.fieldBorder, thickness: 0.5),
            SizedBox(height: AppSpacing.md),
            Text(
              'Account settings',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
            ),
            SizedBox(height: AppSpacing.sm),
            ...[
              'Edit personal info',
              'Change password',
              'Notification settings',
              'Help & support',
            ].map((label) => _SettingsTile(label: label)),
            SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Log out',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.destructive),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _VerificationRow extends StatelessWidget {
  const _VerificationRow({required this.label, required this.date});

  final String label;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: AppColors.matchHigh, size: 16),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTextStyles.label(context).copyWith(fontWeight: FontWeight.w400))),
        Text(date, style: AppTextStyles.caption(context)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.onEdit});

  final String label;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
        const Spacer(),
        TextButton(
          onPressed: onEdit,
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text('Edit', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.primary)),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appColors.fieldBorder, width: 0.5)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: AppTextStyles.label(context).copyWith(fontWeight: FontWeight.w400, fontSize: 14)),
        trailing: Icon(Icons.chevron_right_rounded, color: context.appColors.textSecondary, size: 20),
        onTap: () {},
      ),
    );
  }
}
