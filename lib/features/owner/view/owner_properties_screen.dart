import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/vacancy_status_pill.dart';
import '../../owner_onboarding/view/add_property_screen.dart';

class OwnerPropertiesScreen extends StatelessWidget {
  const OwnerPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        title: Text(
          'My properties',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AddPropertyScreen()),
            ),
            child: Text(
              'Add property',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
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
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.4,
              children: [
                _MetricCard(label: 'Active listings', value: '3', color: AppColors.accent),
                _MetricCard(label: 'Rooms available', value: '5', color: AppColors.matchHigh),
                _MetricCard(label: 'Pending inquiries', value: '2', color: AppColors.matchMedium),
                _MetricCard(label: 'Avg days to fill', value: '12', color: context.appColors.textPrimary),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Your properties',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            ...MockData.properties.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PropertyCard(property: p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.caption(context),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final Map<String, dynamic> property;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.all(Radius.circular(AppRadii.field)),
            ),
            child: Center(
              child: Icon(Icons.home_work_rounded, color: AppColors.accent, size: 28),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        property['name'] as String,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ),
                    VacancyStatusPill.fromString(property['vacancyStatus'] as String),
                  ],
                ),
                SizedBox(height: 2),
                Text(property['address'] as String, style: AppTextStyles.caption(context)),
                Text(
                  '₱${property['rent']}/mo Â· ${property['amenities']} amenities',
                  style: AppTextStyles.caption(context),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: context.appColors.textSecondary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
