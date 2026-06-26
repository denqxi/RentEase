import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/qualified_badge.dart';

class FindTenantsScreen extends StatelessWidget {
  const FindTenantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tenants = MockData.tenants as List;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find tenants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AppChip(label: 'Female only', variant: AppChipVariant.owner, isLocked: true),
                AppChip(label: 'No smoking', variant: AppChipVariant.owner, isLocked: true),
                AppChip(label: 'No pets', variant: AppChipVariant.owner, isLocked: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                children: [
                  TextSpan(
                    text: '9 ',
                    style: TextStyle(
                      color: AppColors.ownerPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'qualified',
                    style: TextStyle(
                      color: AppColors.ownerPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' tenants found'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: tenants.length,
              itemBuilder: (context, index) {
                final t = tenants[index] as Map;
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.ownerFill,
                              child: Text(
                                t['initials'] ?? '',
                                style: TextStyle(
                                  color: AppColors.ownerText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.ownerPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '#${t['rank']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['name'] ?? '',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${t['gender']} · ${t['occupation']}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Budget ₱${t['budget']} · ${t['intendedStay']} months',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.ownerFill,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Ci ${(t['ciScore'] as double).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: AppColors.ownerText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const QualifiedBadge(),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (t['bScore'] == 1)
                          AppButton(
                            label: 'Invite',
                            color: AppColors.ownerPrimary,
                            isSmall: true,
                            isOutlined: true,
                            isFullWidth: false,
                            onPressed: () {},
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
