import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../../shared/widgets/vacancy_status_pill.dart';
import '../../../shared/widgets/verified_badge.dart';
import '../cubit/properties_cubit.dart';
import '../domain/entities/admin_entities.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_views.dart';

class PropertyManagementScreen extends StatefulWidget {
  const PropertyManagementScreen({super.key});

  static const routeName = '/admin/properties';

  @override
  State<PropertyManagementScreen> createState() =>
      _PropertyManagementScreenState();
}

class _PropertyManagementScreenState extends State<PropertyManagementScreen> {
  final _searchController = TextEditingController();

  static const _tabs = ['all', 'active', 'unlisted'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleListed(AdminPropertyItem item) async {
    final cubit = context.read<AdminPropertiesCubit>();
    final listed = item.property.isAvailable;
    final ok = await confirmAdminAction(
      context,
      title: listed ? 'Unlist property?' : 'Relist property?',
      body: listed
          ? '"${item.property.title}" will be hidden from matching and '
                'search. The owner cannot relist it.'
          : '"${item.property.title}" will be visible to tenants again.',
      confirmLabel: listed ? 'Unlist' : 'Relist',
      destructive: listed,
    );
    if (ok) {
      cubit.setListed(item.property.propertyId, listed: !listed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminPropertiesCubit, AdminPropertiesState>(
      listenWhen: (a, b) => a.noticeSeq != b.noticeSeq,
      listener: (context, state) => showAdminNotice(context, state.notice),
      builder: (context, state) {
        return DefaultTabController(
          length: _tabs.length,
          child: Scaffold(
            backgroundColor: context.appColors.surface,
            body: Column(
              children: [
                AdminPageHeader(
                  title: 'Properties',
                  subtitle: '${state.items.length} listings on the platform',
                  bottom: AdminSearchField(
                    controller: _searchController,
                    hintText: 'Search by name, address or owner...',
                    onChanged: context.read<AdminPropertiesCubit>().setQuery,
                  ),
                ),
                TabBar(
                  indicatorColor: AppColors.accent,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: context.appColors.textSecondary,
                  labelStyle: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Active'),
                    Tab(text: 'Unlisted'),
                  ],
                ),
                Expanded(
                  child: state.isLoading
                      ? const AdminLoadingView()
                      : state.errorMessage != null && state.items.isEmpty
                      ? AdminMessageView(
                          icon: Icons.error_outline_rounded,
                          message: state.errorMessage!,
                          onRetry: context.read<AdminPropertiesCubit>().start,
                        )
                      : TabBarView(
                          children: [
                            for (final tab in _tabs)
                              _PropertyList(
                                items: state.filtered(tab),
                                busyIds: state.busyIds,
                                onToggle: _toggleListed,
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PropertyList extends StatelessWidget {
  const _PropertyList({
    required this.items,
    required this.busyIds,
    required this.onToggle,
  });

  final List<AdminPropertyItem> items;
  final Set<String> busyIds;
  final ValueChanged<AdminPropertyItem> onToggle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AdminMessageView(
        icon: Icons.home_work_outlined,
        message: 'No properties found.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        120,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _PropertyCard(
        item: items[i],
        isBusy: busyIds.contains(items[i].property.propertyId),
        onToggle: () => onToggle(items[i]),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.item,
    required this.isBusy,
    required this.onToggle,
  });

  final AdminPropertyItem item;
  final bool isBusy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = item.property;
    final seed = p.propertyId.hashCode.abs() % 5 + 1;
    final placeholder = ListingImagePlaceholder(seed: seed);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.adminUnlisted
              ? AppColors.destructive
              : context.appColors.fieldBorder,
          width: item.adminUnlisted ? 1.0 : 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.field),
            child: SizedBox(
              width: 60,
              height: 60,
              child: p.photos.isEmpty
                  ? placeholder
                  : Image.network(
                      p.photos.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => placeholder,
                    ),
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
                        p.title.isEmpty ? 'Untitled listing' : p.title,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.adminUnlisted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.destructive.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadii.chip),
                        ),
                        child: Text(
                          'Unlisted',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.destructive,
                          ),
                        ),
                      )
                    else
                      VacancyStatusPill.fromString(p.vacancyStatus),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  p.address,
                  style: AppTextStyles.caption(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '₱${p.monthlyRent}/mo',
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '· ${item.ownerName}',
                        style: AppTextStyles.caption(context),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (p.isVerified) ...[
                      SizedBox(width: 4),
                      const VerifiedBadge(isVerified: true, isSmall: true),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isBusy)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: context.appColors.textSecondary,
                size: 18,
              ),
              color: context.appColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (_) => onToggle(),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  enabled: p.isAvailable || item.adminUnlisted,
                  child: Text(
                    p.isAvailable
                        ? 'Unlist property'
                        : item.adminUnlisted
                        ? 'Relist property'
                        : 'Closed by owner',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.isAvailable
                          ? AppColors.destructive
                          : AppColors.matchHigh,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
