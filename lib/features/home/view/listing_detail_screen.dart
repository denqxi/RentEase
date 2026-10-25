import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../../shared/widgets/match_score_card.dart';
import '../cubit/listing_detail_cubit.dart';
import '../model/listing_detail.dart';

/// Full-screen detail view for a rental listing (tenant perspective).
class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({required this.detail, super.key});

  final ListingDetail detail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ListingDetailCubit>(
      create: (_) => ListingDetailCubit(detail: detail),
      child: const _ListingDetailView(),
    );
  }
}

class _ListingDetailView extends StatelessWidget {
  const _ListingDetailView();

  @override
  Widget build(BuildContext context) {
    final detail = context.select<ListingDetailCubit, ListingDetail>(
      (c) => c.state.detail,
    );
    final cubit = context.read<ListingDetailCubit>();

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: Stack(
        children: <Widget>[
          CustomScrollView(
            slivers: <Widget>[
              _PhotoHeader(detail: detail, onSaveToggle: cubit.toggleSaved),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  100,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    _TitleRow(detail: detail),
                    const SizedBox(height: AppSpacing.xs),
                    _LocationRow(location: detail.location),
                    const SizedBox(height: AppSpacing.md),
                    _SpecsRow(detail: detail),
                    const SizedBox(height: AppSpacing.md),
                    MatchScoreCard(
                      matchPercent: detail.matchPercent,
                      label: detail.matchLabel,
                      summary: detail.matchSummary,
                      reasons: detail.matchReasons
                          .map((r) => (r.label, r.met))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionTitle(title: 'About this home'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      detail.description,
                      style: AppTextStyles.body(context),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionTitle(title: 'Amenities'),
                    const SizedBox(height: AppSpacing.sm),
                    _AmenitiesWrap(amenities: detail.amenities),
                    const SizedBox(height: AppSpacing.lg),
                    _LandlordRow(detail: detail),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomBar(
              isSaved: detail.isSaved,
              onSaveToggle: cubit.toggleSaved,
              landlordName: detail.landlordName,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.detail, required this.onSaveToggle});

  final ListingDetail detail;
  final VoidCallback onSaveToggle;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Stack(
        children: <Widget>[
          SizedBox(
            height: 280,
            width: double.infinity,
            child: ListingImagePlaceholder(seed: detail.imageSeed),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _CircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _CircleButton(
                    icon: detail.isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border,
                    iconColor: detail.isSaved
                        ? AppColors.destructive
                        : context.appColors.textPrimary,
                    onTap: onSaveToggle,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: AppSpacing.md,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                3,
                (i) => _DotIndicator(active: i == 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.appColors.surface,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.scrim.withValues(alpha: 0.12),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor ?? context.appColors.textPrimary,
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 20 : 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: active
            ? context.appColors.surface
            : context.appColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.detail});

  final ListingDetail detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(detail.title, style: AppTextStyles.title(context)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              CurrencyUtils.formatDollars(detail.pricePerMonth),
              style: AppTextStyles.title(
                context,
              ).copyWith(color: AppColors.accent, fontSize: 20),
            ),
            Text(
              'per month',
              style: AppTextStyles.caption(context).copyWith(fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          Icons.location_on_outlined,
          size: 14,
          color: context.appColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          location,
          style: AppTextStyles.caption(context).copyWith(fontSize: 13),
        ),
      ],
    );
  }
}

class _SpecsRow extends StatelessWidget {
  const _SpecsRow({required this.detail});

  final ListingDetail detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _SpecChip(value: '${detail.beds}', label: 'Bedrooms'),
        const SizedBox(width: AppSpacing.sm),
        _SpecChip(value: '${detail.baths}', label: 'Bathrooms'),
        const SizedBox(width: AppSpacing.sm),
        _SpecChip(value: '${detail.sqft} ft²', label: 'Area'),
        const SizedBox(width: AppSpacing.sm),
        _SpecChip(value: detail.propertyType, label: 'Type'),
      ],
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.appColors.fieldFill,
          borderRadius: BorderRadius.circular(AppRadii.field),
          border: Border.all(color: context.appColors.fieldBorder),
        ),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: AppTextStyles.label(
                context,
              ).copyWith(fontSize: 13, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption(context).copyWith(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.title(context).copyWith(fontSize: 18),
    );
  }
}

class _AmenitiesWrap extends StatelessWidget {
  const _AmenitiesWrap({required this.amenities});

  final List<String> amenities;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: amenities.map((a) => _AmenityChip(label: a)).toList(),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.label});

  final String label;

  static const Map<String, IconData> _icons = <String, IconData>{
    'Wi-Fi': Icons.wifi,
    'Parking': Icons.local_parking_rounded,
    'Furnished': Icons.chair_outlined,
    'Pet friendly': Icons.pets_outlined,
    'Balcony': Icons.deck_outlined,
    'Laundry': Icons.local_laundry_service_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: context.appColors.fieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            _icons[label] ?? Icons.check_circle_outline,
            size: 14,
            color: context.appColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.appColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LandlordRow extends StatelessWidget {
  const _LandlordRow({required this.detail});

  final ListingDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: context.appColors.fieldBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[AppColors.placeholderNavyA, AppColors.placeholderNavyB],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.person, color: AppColors.onInk, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  detail.landlordName,
                  style: AppTextStyles.label(
                    context,
                  ).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${detail.landlordRole} · ${detail.landlordResponseTime}',
                  style: AppTextStyles.caption(context).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.appColors.fieldFill,
              shape: BoxShape.circle,
              border: Border.all(color: context.appColors.fieldBorder),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isSaved,
    required this.onSaveToggle,
    required this.landlordName,
  });

  final bool isSaved;
  final VoidCallback onSaveToggle;
  final String landlordName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border(top: BorderSide(color: context.appColors.fieldBorder)),
      ),
      child: Row(
        children: <Widget>[
          _HeartButton(isSaved: isSaved, onTap: onSaveToggle),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: AppSizes.buttonHeight,
              child: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Inquiry sent to $landlordName!'),
                    backgroundColor: context.appColors.ink,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appColors.ink,
                  foregroundColor: AppColors.onInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.button),
                  ),
                ),
                child: const Text(
                  'Contact landlord',
                  style: AppTextStyles.buttonLabel,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.isSaved, required this.onTap});

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSizes.buttonHeight,
        height: AppSizes.buttonHeight,
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.button),
          border: Border.all(color: context.appColors.fieldBorder),
        ),
        child: Icon(
          isSaved ? Icons.favorite_rounded : Icons.favorite_border,
          color: isSaved
              ? AppColors.destructive
              : context.appColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
