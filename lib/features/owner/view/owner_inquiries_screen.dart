import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
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
                  // ── Title & Subtitle Header ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
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
                        const SizedBox(height: 4),
                        const Text(
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
                    child: const TabBar(
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 2.5,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Color(0xFF64748B),
                      labelStyle: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: [
                        Tab(height: 42, text: 'Incoming'),
                        Tab(height: 42, text: 'Sent'),
                        Tab(height: 42, text: 'History'),
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
                        controller: _searchController,
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
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: _searchController.clear,
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
                    child: uid == null
                        ? const _InboxMessage('Sign in to see your inquiries.')
                        : BlocProvider(
                            create: (_) => InquiryListCubit(
                              uid: uid,
                              isOwner: true,
                              repository: InquiryRepositoryImpl(),
                            ),
                            child: _OwnerInquiryTabs(
                              searchQuery: _searchController.text,
                            ),
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

class _OwnerInquiryTabs extends StatelessWidget {
  const _OwnerInquiryTabs({required this.searchQuery});

  final String searchQuery;

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
          emptyText: searchQuery.trim().isNotEmpty
              ? 'No matching incoming inquiries.'
              : 'No incoming inquiries yet.',
        ),
        _InquiryList(
          items: _filter(state.sentInvitations),
          emptyText: searchQuery.trim().isNotEmpty
              ? 'No matching sent notifications.'
              : 'No sent notifications yet.',
        ),
        _InquiryList(
          items: _filter(state.history),
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
  const _InquiryList({required this.items, required this.emptyText});

  final List<InquirySummary> items;
  final String emptyText;

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
      itemBuilder: (_, i) => _OwnerInquiryCard(summary: items[i]),
    );
  }
}

class _OwnerInquiryCard extends StatelessWidget {
  const _OwnerInquiryCard({required this.summary});

  final InquirySummary summary;

  @override
  Widget build(BuildContext context) {
    final inquiry = summary.inquiry;

    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            InquiryThreadScreen(inquiryId: inquiry.inquiryId, isOwner: true),
      ),
    );

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
              color: const Color(0xFFE2E8F0),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.035),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFEDF2F7),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  summary.counterpartInitials,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
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
                    Text(
                      summary.counterpartName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      summary.propertyTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Date + Chevron >
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    inquiryDateLabel(inquiry.updatedAt?.toDate()),
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 4),
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
