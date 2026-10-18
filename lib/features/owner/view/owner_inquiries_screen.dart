import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/phase_badge.dart';
import '../../auth/presentation/current_uid.dart';
import '../../inquiry/cubit/inquiry_list_cubit.dart';
import '../../inquiry/data/repositories/inquiry_repository_impl.dart';
import '../../inquiry/domain/services/inquiry_service.dart';
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
    final canPop = Navigator.of(context).canPop();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            // Soft Top-Right Wave + Gradient Background matching the reference UI
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 230,
              child: IgnorePointer(child: _InquiriesHeaderWaveBackground()),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title & Subtitle Header ──────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      canPop ? AppSpacing.sm : AppSpacing.lg,
                      AppSpacing.lg,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (canPop) ...[
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0F172A,
                                    ).withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
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

class _InquiriesHeaderWaveBackground extends StatelessWidget {
  const _InquiriesHeaderWaveBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _InquiriesWavePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _InquiriesWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base subtle top gradient
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFFD8F3FE).withValues(alpha: 0.72),
          const Color(0xFFEFF9FF).withValues(alpha: 0.45),
          const Color(0xFFF8FAFC).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // Decorative soft wave sweeping from top-right to middle-right
    final wavePath = Path()
      ..moveTo(size.width * 0.52, 0)
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.35,
        size.width * 0.58,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.82,
        size.width * 0.78,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.75,
        size.width,
        size.height * 0.60,
      )
      ..lineTo(size.width, 0)
      ..close();

    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFFBAE8FD).withValues(alpha: 0.55),
          const Color(0xFFE0F4FE).withValues(alpha: 0.15),
        ],
      ).createShader(bgRect);

    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
              ? 'No matching sent invitations.'
              : 'No sent invitations yet.',
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

  String _messagePreview() {
    final latest = summary.lastMessagePreview?.trim();
    if (latest != null && latest.isNotEmpty) return latest;

    final inquiry = summary.inquiry;
    if (InquiryService.isInvite(inquiry)) {
      return switch (inquiry.status) {
        'declined' => 'Tenant declined your invitation.',
        'booked' => 'Booking confirmed for ${summary.propertyTitle}.',
        'closed' => 'This invitation is now closed.',
        _ =>
          inquiry.stage == 2
              ? 'Invitation accepted — tap to start chatting.'
              : 'Invitation sent — waiting for tenant response.',
      };
    }

    return switch (inquiry.status) {
      'booked' => 'Booking confirmed for ${summary.propertyTitle}.',
      'declined' => 'You declined this inquiry.',
      'closed' => 'Closed — listing marked as fully booked.',
      _ =>
        inquiry.stage == 2
            ? "Hi! Is this still available? I'm interested in this listing."
            : 'Hi! Sent an inquiry — tap to review tenant summary.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final inquiry = summary.inquiry;
    final phase = inquiry.stage.toInt();
    final isInvite = InquiryService.isInvite(inquiry);
    final resolvedLabel = switch (inquiry.status) {
      'booked' => 'Booked',
      'declined' => 'Declined',
      'closed' => 'Closed',
      _ => null,
    };
    final statusColor = switch (inquiry.status) {
      'booked' => AppColors.primary,
      'declined' => AppColors.destructive,
      _ => const Color(0xFF64748B),
    };

    final actionLabel = resolvedLabel != null
        ? (inquiry.status == 'booked' ? 'View & rate' : 'Open chat')
        : (isInvite && phase == 1 ? 'View invitation' : 'Open chat');

    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            InquiryThreadScreen(inquiryId: inquiry.inquiryId, isOwner: true),
      ),
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.75),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.045),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Initials Avatar
                  Container(
                    width: 46,
                    height: 46,
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

                  // Tenant Name, Property Name, Message Preview
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.counterpartName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          summary.propertyTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _messagePreview(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Date + Phase / Status Pill
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        inquiryDateLabel(inquiry.updatedAt?.toDate()),
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (resolvedLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            resolvedLabel,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              height: 1.15,
                            ),
                          ),
                        )
                      else
                        PhaseBadge(phase: phase),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom Row: Chat Icon + "Open chat" + Right Chevron
              Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: Color(0xFF475569),
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
