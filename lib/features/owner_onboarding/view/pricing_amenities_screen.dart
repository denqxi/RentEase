import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/card_over_hero_layout.dart';
import 'owner_topsis_screen.dart';

class PricingAmenitiesScreen extends StatefulWidget {
  const PricingAmenitiesScreen({super.key});

  @override
  State<PricingAmenitiesScreen> createState() => _PricingAmenitiesScreenState();
}

class _PricingAmenitiesScreenState extends State<PricingAmenitiesScreen> {
  final _rentController = TextEditingController();
  final Set<String> _selected = {};

  @override
  void dispose() {
    _rentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      ),
    );
  }
}
