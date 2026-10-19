import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../registration/model/user_role.dart';
import '../cubit/activity_cubit.dart';
import '../model/activity_item.dart';
import '../widgets/activity_tile.dart';

/// Notifications / Activity screen matching the reference design:
/// - Header with title, informative subtitle, and "Mark all read" CTA (fixed in place).
/// - Segmented category filter chips with dynamic count badges (fixed in place).
/// - Grouped time sections: "Today", "Earlier", "This Month" with collapsible accordions.
/// - Expandable notification cards with embedded property preview cards.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({this.isOwner, super.key});

  final bool? isOwner;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  ActivityCategory _selectedCategory = ActivityCategory.all;
  final Set<String> _collapsedSections = <String>{};

  void _toggleSection(String sectionKey) {
    setState(() {
      if (_collapsedSections.contains(sectionKey)) {
        _collapsedSections.remove(sectionKey);
      } else {
        _collapsedSections.add(sectionKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.isOwner ??
        (context.watch<ProfileCubit?>()?.state.userRole == UserRole.landlord);
    final state = context.watch<ActivityCubit>().state;
    final cubit = context.read<ActivityCubit>();
    final allItems = state.items;

    // Filter items based on selected category chip
    final filteredItems = allItems.where((item) {
      if (_selectedCategory == ActivityCategory.all) return true;
      return item.category == _selectedCategory;
    }).toList();

    // Compute category counts
    final propertiesCount = allItems
        .where((i) => i.category == ActivityCategory.properties)
        .length;
    final inquiriesCount = allItems
        .where((i) => i.category == ActivityCategory.inquiries)
        .length;
    final systemCount =
        allItems.where((i) => i.category == ActivityCategory.system).length;

    // Group items into time buckets: "Today", "Earlier", "This Month"
    final now = DateTime.now();
    final Map<String, List<ActivityItem>> grouped = {};
    for (final item in filteredItems) {
      final group = item.dateGroup(now);
      grouped.putIfAbsent(group, () => []).add(item);
    }

    // Preserve standard section order
    const sectionOrder = ['Today', 'Earlier', 'This Month'];
    final presentSections = sectionOrder.where(grouped.containsKey).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── 1. Top Header Bar (Fixed in place) ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (Navigator.of(context).canPop()) ...[
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 38,
                            height: 38,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 19,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isOwner
                                  ? 'Stay updated with your inquiries, tenants, and properties.'
                                  : 'Stay updated with the latest properties and activities.',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: cubit.markAllRead,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Mark all read',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── 2. Segmented Category Filter Chips (Fixed in place) ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          category: ActivityCategory.all,
                          label: 'All',
                          count: allItems.length,
                          icon: null,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          category: ActivityCategory.properties,
                          label: 'Properties',
                          count: propertiesCount,
                          icon: Icons.home_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          category: ActivityCategory.inquiries,
                          label: 'Inquiries',
                          count: inquiriesCount,
                          icon: Icons.chat_bubble_outline_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          category: ActivityCategory.system,
                          label: 'System',
                          count: systemCount,
                          icon: Icons.tune_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 16,
              thickness: 0.8,
              color: Color(0xFFF1F5F9),
            ),

            // ── 3. Scrollable Feed Body ────────────────────────────────────
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  if (state.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary,
                  ),
                ),
              )
            else if (state.errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 44,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: cubit.retry,
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (filteredItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 28,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "You're all caught up",
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'New alerts and updates will show here.',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // ── 4. Grouped Sections (Today, Earlier, This Month) ─────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sectionKey = presentSections[index];
                      final sectionItems = grouped[sectionKey] ?? [];
                      final isCollapsed = _collapsedSections.contains(sectionKey);
                      final unreadInSection =
                          sectionItems.where((i) => !i.isRead).length;

                      final trailingSummary = unreadInSection > 0
                          ? '$unreadInSection new'
                          : '${sectionItems.length} notification${sectionItems.length == 1 ? '' : 's'}';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Section Header with Accordion Toggle
                          InkWell(
                            onTap: () => _toggleSection(sectionKey),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 2),
                              child: Row(
                                children: [
                                  Text(
                                    sectionKey,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    trailingSummary,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    isCollapsed
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.keyboard_arrow_up_rounded,
                                    size: 18,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Section Items (Collapsible)
                          if (!isCollapsed)
                            ...sectionItems.map(
                              (item) => ActivityTile(
                                item: item,
                                isOwner: isOwner,
                              ),
                            ),
                          const SizedBox(height: 6),
                        ],
                      );
                    },
                    childCount: presentSections.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    ],
  ),
),
);
  }

  Widget _buildFilterChip({
    required ActivityCategory category,
    required String label,
    required int count,
    required IconData? icon,
  }) {
    final isSelected = _selectedCategory == category;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE0F7FA).withValues(alpha: 0.8)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.1 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

