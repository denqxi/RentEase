<<<<<<< Updated upstream
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
=======
﻿import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/card_over_hero_layout.dart';
>>>>>>> Stashed changes
import 'owner_topsis_screen.dart';

class PricingAmenitiesScreen extends StatefulWidget {
  const PricingAmenitiesScreen({super.key});

  @override
  State<PricingAmenitiesScreen> createState() => _PricingAmenitiesScreenState();
}

class _PricingAmenitiesScreenState extends State<PricingAmenitiesScreen> {
<<<<<<< Updated upstream
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
=======
  final _rentController = TextEditingController();
  final Set<String> _selected = {};

  @override
  void dispose() {
    _rentController.dispose();
>>>>>>> Stashed changes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
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
=======
    return CardOverHeroLayout(
      hero: const HeroPlaceholder(),
      cardHeightFraction: 0.85,
      cardContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing & amenities.',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text('Set your rent and list what your property offers.', style: AppTextStyles.body(context)),
          SizedBox(height: AppSpacing.lg),
          LabelledField(
            label: 'Monthly rent (PHP)',
            child: AppTextField(
              controller: _rentController,
              hintText: '3500',
              prefixText: '₱ ',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Amenities',
                style: AppTextStyles.label(context).copyWith(
                  color: context.appColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${_selected.length} of ${MockData.amenities.length} selected',
                style: AppTextStyles.caption(context),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: MockData.amenities.map((amenity) {
              final isSelected = _selected.contains(amenity);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _selected.remove(amenity);
                  } else {
                    _selected.add(amenity);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentSoft : context.appColors.fieldFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : context.appColors.fieldBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      amenity,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? AppColors.accent : context.appColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Save and Continue',
            onPressed: _rentController.text.isNotEmpty
                ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const OwnerTopsisScreen()),
                    )
                : null,
          ),
          SizedBox(height: AppSpacing.lg),
        ],
>>>>>>> Stashed changes
      ),
    );
  }
}
