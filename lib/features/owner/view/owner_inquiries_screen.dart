import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../activity/cubit/activity_cubit.dart';
import '../../auth/presentation/current_uid.dart';
import '../../inquiry/cubit/inquiry_list_cubit.dart';
import '../../inquiry/data/repositories/inquiry_repository_impl.dart';
import '../../inquiry/model/inquiry_summary.dart';
import '../../inquiry/view/inquiry_thread_screen.dart';

/// Owner inbox — inquiries tenants sent to this owner's properties, live.
/// Sorted by latest activity; owner-side discovery is filtering-only
/// (CLAUDE.md), so tenants carry no ranking score here.
class OwnerInquiriesScreen extends StatefulWidget {
  const OwnerInquiriesScreen({super.key});

  @override
  State<OwnerInquiriesScreen> createState() => _OwnerInquiriesScreenState();
}

class _OwnerInquiriesScreenState extends State<OwnerInquiriesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = currentUidOrNull(context);
    if (uid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: _InboxMessage('Sign in to see your inquiries.'),
      );
    }

    return BlocProvider(
      create: (_) => InquiryListCubit(
        uid: uid,
        isOwner: true,
        repository: InquiryRepositoryImpl(),
      ),
      child: _OwnerInquiriesView(
        searchController: _searchController,
      ),
    );
  }
}

class _OwnerInquiriesView extends StatelessWidget {
  const _OwnerInquiriesView({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final activityState = context.watch<ActivityCubit?>()?.state;
    final unreadInquiryIds =
        activityState?.unreadInquiryIds ?? const <String>{};
    final int unreadCount = unreadInquiryIds.length;
    final state = context.watch<InquiryListCubit>().state;

    final hasIncomingDot = state.incoming.any(
      (s) => unreadInquiryIds.contains(s.inquiry.inquiryId),
    );
    final hasSentDot = state.sentInvitations.any(
      (s) => unreadInquiryIds.contains(s.inquiry.inquiryId),
    );
    final hasHistoryDot = state.history.any(
      (s) => unreadInquiryIds.contains(s.inquiry.inquiryId),
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            // Subtle top-right gradient — matching the homescreen bg
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 195,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.05,
                      colors: <Color>[
                        const Color(0xFFCCF2FE).withValues(alpha: 0.70),
                        const Color(0xFFE0F7FE).withValues(alpha: 0.35),
                        const Color(0xFFE0F7FE).withValues(alpha: 0.0),
                      ],
                      stops: const <double>[0.0, 0.45, 0.88],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title & Subtitle Header with Top-Right Badge ──────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Inquiries',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.6,
                                  height: 1.15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Messages from potential tenants',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 12),
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A8F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── 3-Tab Bar (Incoming / Sent / History) ────────────────
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                    ),
                    child: TabBar(
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 2.5,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: [
                        Tab(
                          height: 42,
                          child: _TabWithDot(
                            label: 'Incoming',
                            hasDot: hasIncomingDot,
                          ),
                        ),
                        Tab(
                          height: 42,
                          child: _TabWithDot(
                            label: 'Sent',
                            hasDot: hasSentDot,
                          ),
                        ),
                        Tab(
                          height: 42,
                          child: _TabWithDot(
                            label: 'History',
                            hasDot: hasHistoryDot,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Search Bar ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      14,
                      AppSpacing.md,
                      6,
                    ),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search name or property...',
                          hintStyle: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF475569),
                            size: 21,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: searchController.clear,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Tab Content ──────────────────────────────────────────
                  Expanded(
                    child: _OwnerInquiryTabs(
                      searchQuery: searchController.text,
                      unreadInquiryIds: unreadInquiryIds,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabWithDot extends StatelessWidget {
  const _TabWithDot({
    required this.label,
    required this.hasDot,
  });

  final String label;
  final bool hasDot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        if (hasDot) ...[
          const SizedBox(width: 5),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF00A8F0),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

class _OwnerInquiryTabs extends StatelessWidget {
  const _OwnerInquiryTabs({
    required this.searchQuery,
    this.unreadInquiryIds = const <String>{},
  });

  final String searchQuery;
  final Set<String> unreadInquiryIds;

  List<InquirySummary> _filter(List<InquirySummary> list) {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((s) {
      final nameMatch = s.counterpartName.toLowerCase().contains(q);
      final propMatch = s.propertyTitle.toLowerCase().contains(q);
      final msgMatch =
          (s.lastMessagePreview?.toLowerCase().contains(q) ?? false);
      return nameMatch || propMatch || msgMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InquiryListCubit>().state;
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return _InboxMessage(state.errorMessage!);
    }
    return TabBarView(
      children: [
        _InquiryList(
          items: _filter(state.incoming),
          unreadInquiryIds: unreadInquiryIds,
          emptyText: searchQuery.trim().isNotEmpty
              ? 'No matching incoming inquiries.'
              : 'No incoming inquiries yet.',
        ),
        _InquiryList(
          items: _filter(state.sentInvitations),
          unreadInquiryIds: unreadInquiryIds,
          emptyText: searchQuery.trim().isNotEmpty
              ? 'No matching sent notifications.'
              : 'No sent notifications yet.',
        ),
        _InquiryList(
          items: _filter(state.history),
          unreadInquiryIds: unreadInquiryIds,
          emptyText: searchQuery.trim().isNotEmpty
              ? 'No matching past inquiries.'
              : 'No past inquiries yet.',
        ),
      ],
    );
  }
}

class _InboxMessage extends StatelessWidget {
  const _InboxMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          style: AppTextStyles.body(
            context,
          ).copyWith(color: const Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _InquiryList extends StatelessWidget {
  const _InquiryList({
    required this.items,
    required this.emptyText,
    this.unreadInquiryIds = const <String>{},
  });

  final List<InquirySummary> items;
  final String emptyText;
  final Set<String> unreadInquiryIds;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _InboxMessage(emptyText);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        10,
        AppSpacing.md,
        115,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final summary = items[i];
        final isUnread = unreadInquiryIds.contains(summary.inquiry.inquiryId);
        return _OwnerInquiryCard(
          summary: summary,
          isUnread: isUnread,
        );
      },
    );
  }
}

class _OwnerInquiryCard extends StatelessWidget {
  const _OwnerInquiryCard({
    required this.summary,
    this.isUnread = false,
  });

  final InquirySummary summary;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final inquiry = summary.inquiry;

    void open() {
      try {
        context.read<ActivityCubit>().markInquiryRead(inquiry.inquiryId);
      } catch (_) {}
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              InquiryThreadScreen(inquiryId: inquiry.inquiryId, isOwner: true),
        ),
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
              width: isUnread ? 1.2 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnread
                    ? const Color(0xFF00A8F0).withValues(alpha: 0.07)
                    : const Color(0xFF0F172A).withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Initials Avatar
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isUnread ? const Color(0xFFE0F7FE) : const Color(0xFFEDF2F7),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  summary.counterpartInitials,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Profile Name & Property Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            summary.counterpartName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 15,
                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (inquiry.tenantCiSnapshot > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                            ),
                            child: Text(
                              '${(inquiry.tenantCiSnapshot * 100).round()}%',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                            ),
                            child: Text(
                              'ci=${inquiry.tenantCiSnapshot.toDouble().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      summary.propertyTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12.5,
                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                        color: isUnread ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Date + Chevron + Unread Dot
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    inquiryDateLabel(inquiry.updatedAt?.toDate()),
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                      color: isUnread ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isUnread) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A8F0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
