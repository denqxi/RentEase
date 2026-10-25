import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../home/view/property_detail_screen.dart';
import '../../landlord_home/view/tenant_detail_screen.dart';
import '../../landlord_home/view/owner_detail_screen.dart';
import '../../owner/model/compatible_tenant.dart';
import '../../resolution/view/rating_screen.dart';
import '../cubit/inquiry_thread_cubit.dart';
import '../domain/services/inquiry_service.dart';
import '../model/inquiry_summary.dart';
import 'contact_row.dart';
import 'rejected_owner_notice.dart';

/// Phase 2 — open chat between tenant and owner, shared by both sides
/// ([isOwner] picks the perspective). Owners can mark the booking; once
/// booked, the input is replaced by a prompt to rate the other party.
class InquiryChatView extends StatefulWidget {
  const InquiryChatView({
    required this.isOwner,
    required this.counterpartName,
    required this.propertyTitle,
    super.key,
  });

  final bool isOwner;
  final String counterpartName;
  final String propertyTitle;

  @override
  State<InquiryChatView> createState() => _InquiryChatViewState();
}

class _InquiryChatViewState extends State<InquiryChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  static const _tenantQuickReplies = [
    'When can I visit?',
    'Is the room still available?',
    'How much is the deposit?',
  ];

  static const _ownerQuickReplies = [
    'When can you move in?',
    'Do you have your documents ready?',
    'Would you like to schedule a viewing?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // The list is reversed: offset 0 is the newest message.
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    final sent = await context.read<InquiryThreadCubit>().sendMessage(text);
    if (sent && mounted && text == _messageController.text) {
      _messageController.clear();
    }
  }

  Future<void> _confirmMarkBooked() async {
    final cubit = context.read<InquiryThreadCubit>();
    // Unchecked by default: most boarding houses have several vacancies,
    // and hiding a listing by accident is worse than an extra inquiry.
    var fillsLastVacancy = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Mark as occupied?',
          style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700),
        ),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirms that ${widget.counterpartName} is now staying at ${widget.propertyTitle}.',
                style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                value: fillsLastVacancy,
                onChanged: (v) =>
                    setDialogState(() => fillsLastVacancy = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
                title: const Text(
                  'This fills my last vacancy',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Marks ${widget.propertyTitle} as occupied and hides it from new searches.',
                  style: AppTextStyles.caption(ctx),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ctx.appColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (await cubit.markBooked(fillsLastVacancy: fillsLastVacancy) && mounted) {
      _openRating();
    }
  }

  void _openRating() {
    final cubit = context.read<InquiryThreadCubit>();
    Future<bool> handleRatingSubmit(int stars, String review) async {
      final ok = await cubit.submitRating(stars: stars, review: review);
      if (!ok && cubit.state.errorMessage != null) {
        throw Exception(cubit.state.errorMessage);
      }
      return ok;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.isOwner
            ? RatingScreen.forOwner(
                subjectName: widget.counterpartName,
                subjectInitials: InquirySummary.initialsOf(
                  widget.counterpartName,
                ),
                moveInLabel: widget.propertyTitle,
                onSubmit: (stars, review) =>
                    handleRatingSubmit(stars, review),
              )
            : RatingScreen(
                subjectName: widget.propertyTitle,
                moveInLabel: 'Hosted by ${widget.counterpartName}',
                onSubmit: (stars, review) =>
                    handleRatingSubmit(stars, review),
              ),
      ),
    );
  }

  void _showAttachmentOptions(PropertyDoc? property, String? phone) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.indicatorInactive,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Share',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.isOwner) ...[
                if (property != null) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Share property address',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      property.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _send(
                        'Location for ${property.title}: ${property.address}',
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Share payment terms',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '₱${property.monthlyRent}/mo · Deposit ₱${property.depositAmount}',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _send(
                        'Rent is ₱${property.monthlyRent}/mo with ₱${property.depositAmount} deposit and ${property.advanceMonths} month(s) advance.',
                      );
                    },
                  ),
                ],
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Request viewing schedule',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Ask for preferred date and time to visit',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _send(
                      'Would you like to schedule a viewing? Let me know what day and time works best for you.',
                    );
                  },
                ),
              ] else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Request viewing schedule',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Ask the owner for a property visit',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _send(
                      'Hello! I would like to schedule a viewing for ${property?.title ?? "the property"}. When would be a convenient time to visit?',
                    );
                  },
                ),
                if (property != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Ask for directions & landmarks',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Inquire about nearest landmarks or commute',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _send(
                        'Could you share the nearest landmarks or directions to ${property.title}?',
                      );
                    },
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Ask about move-in requirements',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Inquire about required IDs or deposit guidelines',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _send(
                      'What are the requirements and initial payment needed before move-in?',
                    );
                  },
                ),
              ],
              if (phone != null && phone.trim().isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Share contact number',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    phone,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _send('You can also reach me at $phone.');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPropertyDetail(PropertyDoc property) {
    final state = context.read<InquiryThreadCubit>().state;
    final inq = state.inquiry;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PropertyDetailScreen(
          propertyId: property.propertyId,
          initialPropertyDoc: property,
          inquiryId: inq?.inquiryId,
          initialTenantCi: (inq?.tenantCiSnapshot ?? 0) > 0
              ? inq!.tenantCiSnapshot.toDouble()
              : null,
        ),
      ),
    );
  }

  void _openCounterpartProfile(InquiryThreadState state) {
    if (widget.isOwner) {
      final tenant = state.tenant;
      final profile = state.tenantProfile;
      final tenantId = tenant?.userId ?? state.inquiry?.tenantId ?? '';
      final name = fullNameOf(
        tenant,
        fallback: widget.counterpartName,
        loaded: !state.isLoading,
      );
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TenantDetailScreen(
            tenant: CompatibleTenant(
              matchId: state.inquiry?.inquiryId ?? '',
              tenantId: tenantId,
              name: name,
              gender: tenant?.gender ?? '',
              maxBudget: profile?.maxBudget ?? 0,
              bScore: 1,
              occupation: profile?.occupation,
              school: profile?.school,
            ),
            user: tenant,
            profile: profile,
            phone: state.counterpartPhone,
            showInviteButton: false,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OwnerDetailScreen(
            owner: state.owner,
            property: state.property,
            fallbackName: widget.counterpartName,
            phone: state.counterpartPhone,
            isVerified: state.ownerVerified,
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Message-only emissions are handled by the list's own BlocSelector, so
    // the rest of the screen (header, banner, input bar) is not rebuilt.
    return BlocBuilder<InquiryThreadCubit, InquiryThreadState>(
      buildWhen: (p, c) => p.copyWith(messages: c.messages) != c,
      builder: _buildBody,
    );
  }

  Widget _buildBody(BuildContext context, InquiryThreadState state) {
    final inquiry = state.inquiry!;
    final property = state.property;
    final booked = inquiry.status == 'booked';
    // Another tenant took the last vacancy (InquiryService.markBooked).
    final closed = inquiry.status == 'closed';
    final canChat = InquiryService.canChat(inquiry);
    final myId = context.read<InquiryThreadCubit>().uid;

    final fallbackDate =
        inquiry.updatedAt?.toDate() ?? inquiry.createdAt?.toDate();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Soft Top Sky-Blue Gradient Background matching the reference UI
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 210,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppColors.accentSoft.withValues(alpha: 0.7),
                      AppColors.accentSoft.withValues(alpha: 0.45),
                      AppColors.surface.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Custom Thread Top Header Bar ─────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 10, 8),
                  child: Row(
                    children: [
                      // Circular/Rounded Back Button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
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
                            Icons.chevron_left_rounded,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Counterpart Initials Avatar & Name (Tappable for Owner)
                      Expanded(
                        child: InkWell(
                          onTap: () => _openCounterpartProfile(state),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: AppColors.fieldFill,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    InquirySummary.initialsOf(widget.counterpartName),
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              widget.counterpartName,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (!widget.isOwner && state.ownerVerified) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.verified_rounded,
                                              size: 15,
                                              color: AppColors.matchHigh,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        widget.propertyTitle,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // 3-Dot More Menu
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.textPrimary,
                          size: 21,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        onSelected: (value) {
                          if (value == 'mark_booked') {
                            _confirmMarkBooked();
                          } else if (value == 'rate') {
                            _openRating();
                          } else if (value == 'property_info' &&
                              property != null) {
                            _openPropertyDetail(property);
                          }
                        },
                        itemBuilder: (ctx) => [
                          if (property != null)
                            const PopupMenuItem<String>(
                              value: 'property_info',
                              height: 38,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.home_work_outlined,
                                    size: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'View property details',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (widget.isOwner && canChat && !state.isBusy)
                            const PopupMenuItem<String>(
                              value: 'mark_booked',
                              height: 38,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mark as occupied',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (booked && !state.hasRated)
                            PopupMenuItem<String>(
                              value: 'rate',
                              height: 38,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_outline_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.isOwner
                                        ? 'Rate ${widget.counterpartName}'
                                        : 'Rate your stay',
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Pinned Property Summary Card ─────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: ThreadPropertyBannerCard(
                    property: property,
                    fallbackTitle: widget.propertyTitle,
                    inquiry: inquiry,
                    onTap: property != null
                        ? () => _openPropertyDetail(property)
                        : null,
                  ),
                ),

                // Shown once the other party shared their phone (accepted
                // threads, including booked); absent otherwise.
                ContactRow(phone: state.counterpartPhone),

                // ── Chat Messages List ───────────────────────────────────
                Expanded(
                  child: BlocSelector<InquiryThreadCubit, InquiryThreadState,
                      List<MessageDoc>>(
                    selector: (s) => s.messages,
                    builder: (context, messages) {
                      if (messages.length != _lastMessageCount) {
                        _lastMessageCount = messages.length;
                        _scrollToBottom();
                      }
                      final threadDate = messages.isNotEmpty
                          ? messages.first.timeStamp?.toDate()
                          : fallbackDate;
                      // Reversed: index 0 is the newest message and the
                      // thread header sits at the last index (visual top).
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        itemCount: messages.length + 1,
                        findChildIndexCallback: (key) {
                          if (key is! ValueKey<String>) return null;
                          final idx = messages.indexWhere(
                            (m) => m.messageId == key.value,
                          );
                          return idx < 0 ? null : messages.length - 1 - idx;
                        },
                        itemBuilder: (_, i) {
                          if (i == messages.length) {
                            return Column(
                              key: const ValueKey('thread-header'),
                              children: [
                                _DateDivider(date: threadDate),
                                const SizedBox(height: 12),
                                _AcceptedStatusBanner(
                                  title: widget.isOwner
                                      ? 'You accepted this inquiry — chat is open.'
                                      : '${widget.counterpartName} accepted your inquiry — chat is open.',
                                  subtitle:
                                      'You can now message and exchange details.',
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                          final message = messages[messages.length - 1 - i];
                          return _MessageBubble(
                            key: ValueKey(message.messageId),
                            message: message,
                            isMine: message.senderId == myId,
                          );
                        },
                      );
                    },
                  ),
                ),

                // ── Bottom Controls (Booked / Closed / Quick Replies + Input)
                if (booked)
                  _BookedPanel(
                    isOwner: widget.isOwner,
                    counterpartName: widget.counterpartName,
                    hasRated: state.hasRated,
                    onRate: _openRating,
                  ),
                if (closed)
                  _ClosedPanel(isOwner: widget.isOwner)
                else if (state.ownerRejected)
                  RejectedOwnerNotice(isOwner: widget.isOwner)
                else ...[
                  // Quick-Reply Suggestion Chips (Wrap layout matching mockup)
                  if (!booked)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final reply
                              in widget.isOwner
                                  ? _ownerQuickReplies
                                  : _tenantQuickReplies)
                            _QuickReplyChip(
                              label: reply,
                              onTap: canChat && !state.isBusy
                                  ? () => _send(reply)
                                  : null,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Pill Input Bar + Circular Send Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
                              decoration: BoxDecoration(
                                color: AppColors.fieldFill,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: canChat && !state.isBusy
                                        ? () => _showAttachmentOptions(
                                            property,
                                            state.counterpartPhone,
                                          )
                                        : null,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: AppColors.surface,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Transform.rotate(
                                        angle: 0.5,
                                        child: const Icon(
                                          Icons.attach_file_rounded,
                                          size: 18,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      enabled: canChat,
                                      maxLength:
                                          InquiryService.maxMessageLength,
                                      buildCounter:
                                          (
                                            _, {
                                            required currentLength,
                                            required isFocused,
                                            maxLength,
                                          }) => null,
                                      onSubmitted: _send,
                                      textInputAction: TextInputAction.send,
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Type a message...',
                                        hintStyle: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textSecondary,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: canChat && !state.isBusy
                                ? () => _send(_messageController.text)
                                : null,
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: canChat
                                    ? AppColors.primary
                                    : AppColors.indicatorInactive,
                                shape: BoxShape.circle,
                                boxShadow: canChat
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.28,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: AppColors.surface,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinned property summary card displayed at the top of an inquiry thread.
class ThreadPropertyBannerCard extends StatelessWidget {
  const ThreadPropertyBannerCard({
    required this.property,
    required this.fallbackTitle,
    this.onTap,
    this.inquiry,
    super.key,
  });

  final PropertyDoc? property;
  final String fallbackTitle;
  final VoidCallback? onTap;
  final InquiryDoc? inquiry;

  @override
  Widget build(BuildContext context) {
    final photoUrl =
        property?.effectiveBuildingCoverPhoto ??
        ((property?.photos.isNotEmpty ?? false)
            ? property!.photos.first
            : null);
    final title = (property?.title.trim().isNotEmpty ?? false)
        ? property!.title.trim()
        : fallbackTitle;
    final address = (property?.address.trim().isNotEmpty ?? false)
        ? property!.address.trim()
        : 'View property details';

    final effectiveOnTap = onTap ??
        (property != null
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PropertyDetailScreen(
                      propertyId: property!.propertyId,
                      initialPropertyDoc: property,
                      inquiryId: inquiry?.inquiryId,
                      initialTenantCi: (inquiry?.tenantCiSnapshot ?? 0) > 0
                          ? inquiry!.tenantCiSnapshot.toDouble()
                          : null,
                    ),
                  ),
                );
              }
            : null);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: effectiveOnTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.fieldBorder.withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: ListingImagePlaceholder(
                    seed: (property?.propertyId.hashCode.abs() ?? 1) + 1,
                    photoUrl: photoUrl,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({this.date});

  final DateTime? date;

  String _formatDate(DateTime? dt) {
    final d = dt ?? DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.fieldBorder, thickness: 1, height: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _formatDate(date),
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.fieldBorder, thickness: 1, height: 1),
        ),
      ],
    );
  }
}

class _AcceptedStatusBanner extends StatelessWidget {
  const _AcceptedStatusBanner({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.75),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final MessageDoc message;
  final bool isMine;

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Just now';
    final hour24 = dt.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = _formatTime(message.timeStamp?.toDate());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.76,
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              color: isMine
                  ? AppColors.accentSoft
                  : AppColors.fieldFill,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMine ? 16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _ClosedPanel extends StatelessWidget {
  const _ClosedPanel({required this.isOwner});

  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SafeArea(
        top: false,
        child: Text(
          isOwner
              ? 'Closed — you marked this listing fully booked.'
              : 'This listing is now fully booked, so the chat is closed.',
          style: AppTextStyles.body(
            context,
          ).copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BookedPanel extends StatelessWidget {
  const _BookedPanel({
    required this.isOwner,
    required this.counterpartName,
    required this.hasRated,
    required this.onRate,
  });

  final bool isOwner;
  final String counterpartName;
  final bool hasRated;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.matchHigh,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Stay confirmed',
                style: AppTextStyles.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasRated)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warningFill.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amberBorder200),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, color: AppColors.matchMedium, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'You rated this stay · Thank you!',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber800,
                    ),
                  ),
                ],
              ),
            )
          else
            AppButton(
              label: isOwner ? 'Rate $counterpartName' : 'Rate your stay',
              variant: AppButtonVariant.outline,
              onPressed: onRate,
            ),
        ],
      ),
    );
  }
}
