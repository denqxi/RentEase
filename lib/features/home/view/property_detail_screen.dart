import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/ci_score_pill.dart';
import '../../../shared/widgets/constraint_check_row.dart';
import '../../inquiry/view/phase1_tenant_screen.dart';

class PropertyDetailScreen extends StatelessWidget {
  const PropertyDetailScreen({required this.property, super.key});

  final Map<String, dynamic> property;

  @override
  Widget build(BuildContext context) {
    final bool isOutside = property['isOutsidePreference'] == true;
    final int bScore = (property['bScore'] as num).toInt();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Outside preferences banner
          if (isOutside)
            Container(
              color: AppColors.amberFill,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16,
                8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.amberPrimary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Outside your saved preferences',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amberText,
                          ),
                        ),
                        Text(
                          [
                            if ((property['distanceExcess'] ?? 0) > 0)
                              'Distance is ${property['distanceExcess']} km over limit',
                            if ((property['budgetExcess'] ?? 0) > 0)
                              'Budget is ₱${property['budgetExcess']} over limit',
                            if ((property['distanceExcess'] ?? 0) == 0 &&
                                (property['budgetExcess'] ?? 0) == 0)
                              'Budget is within range',
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Scrollable content
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Hero image with back + heart buttons
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Container(
                        height: 240,
                        color: isOutside
                            ? AppColors.amberFill
                            : AppColors.tenantFillBlue,
                        child: Center(
                          child: Icon(
                            Icons.home_outlined,
                            size: 72,
                            color: isOutside
                                ? AppColors.amberPrimary
                                : AppColors.primaryMid,
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top +
                            (isOutside ? 0 : 8),
                        left: 8,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: isOutside
                                ? AppColors.amberText
                                : AppColors.textPrimary,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top +
                            (isOutside ? 0 : 8),
                        right: 8,
                        child: IconButton(
                          icon: Icon(
                            Icons.favorite_border,
                            color: isOutside
                                ? AppColors.amberText
                                : AppColors.textPrimary,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + address + price
                        Text(
                          property['name'] as String,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          property['address'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱${property['rent']} / month',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Owner card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.fieldFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.tenantFillBlue,
                                child: Text(
                                  property['ownerInitials'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.tenantTextDeep,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    property['ownerName'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Row(
                                    children: const [
                                      Icon(Icons.check_circle,
                                          color: AppColors.primaryTeal,
                                          size: 13),
                                      SizedBox(width: 3),
                                      Text(
                                        'Verified Owner',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Member since ${property['memberSince']} · ${property['propertyCount']} properties',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // House rules (non-outside)
                        if (!isOutside) ...[
                          const Text(
                            'House Rules',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _RuleRow(
                            label: 'Gender policy',
                            value: property['allowedGender'] as String,
                          ),
                          _RuleRow(
                            label: 'Smoking',
                            value: property['smokingAllowed'] == true
                                ? 'Allowed'
                                : 'Not allowed',
                          ),
                          _RuleRow(
                            label: 'Curfew',
                            value: property['curfew'] as String,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CiScorePill(
                                score: (property['ciScore'] as num)
                                    .toDouble(),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.fieldBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  '#${property['rank']} Rank',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Compatibility check (outside prefs)
                        if (isOutside) ...[
                          const Text(
                            'Compatibility check',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ConstraintCheckRow(
                            label: 'Monthly rent',
                            value:
                                '₱${property['rent']} — within budget',
                            isPassing:
                                (property['budgetExcess'] ?? 0) == 0,
                          ),
                          ConstraintCheckRow(
                            label: 'Distance',
                            value:
                                '${property['distance']} km — +${property['distanceExcess']} km over limit',
                            isPassing:
                                (property['distanceExcess'] ?? 0) == 0,
                          ),
                          ConstraintCheckRow(
                            label: 'Gender policy',
                            value:
                                '${property['allowedGender']} — matches',
                            isPassing: true,
                          ),
                        ],

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (bScore == 1 && !isOutside)
                AppButton(
                  label: 'Send Inquiry',
                  color: AppColors.primaryMid,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          Phase1TenantScreen(property: property),
                    ),
                  ),
                ),
              if (isOutside) ...[
                AppButton(
                  label: 'Send Inquiry Anyway',
                  color: AppColors.primaryMid,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          Phase1TenantScreen(property: property),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Update My Saved Budget',
                  color: AppColors.primaryMid,
                  isOutlined: true,
                  onPressed: () {},
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
