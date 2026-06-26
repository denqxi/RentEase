import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'owner_topsis_screen.dart';

class PricingAmenitiesScreen extends StatefulWidget {
  const PricingAmenitiesScreen({super.key});

  @override
  State<PricingAmenitiesScreen> createState() => _PricingAmenitiesScreenState();
}

class _PricingAmenitiesScreenState extends State<PricingAmenitiesScreen> {
  final TextEditingController rentController = TextEditingController();

  final List<String> amenityList = [
    'WiFi',
    'AC',
    'Parking',
    'Laundry',
    'Water included',
    'Electricity included',
    'Study desk',
    'Ref',
    'Kitchen access',
    'CCTV',
    'Security guard',
    'Visitor hours',
  ];

  Set<String> selected = {};

  @override
  void dispose() {
    rentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pricing and amenities.'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rent per month',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: rentController,
              prefixText: 'PHP ',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Text(
              'Amenities',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenityList.map((a) {
                final isSelected = selected.contains(a);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      selected.remove(a);
                    } else {
                      selected.add(a);
                    }
                  }),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.tenantFillBlue : AppColors.fieldBg,
                      border: Border.all(
                        color: isSelected ? AppColors.primaryMid : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check, size: 12, color: AppColors.primaryMid),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          a,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.tenantTextDeep
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              '${selected.length} amenities selected',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Save and continue',
              color: AppColors.ownerPrimary,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OwnerTopsisScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
